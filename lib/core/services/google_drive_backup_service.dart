import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Typed failure reasons so the UI can show a specific, friendly message
/// instead of a raw exception string.
enum DriveBackupErrorType {
  notSignedIn,
  authenticationFailed,
  authorizationFailed,
  uploadFailed,
  downloadFailed,
  noBackupFound,
  invalidBackup,
  corruptedBackup,
  networkError,
  configurationError,
  unknown,
}

class DriveBackupException implements Exception {
  const DriveBackupException({
    required this.type,
    this.message,
    this.originalError,
  });

  final DriveBackupErrorType type;
  final String? message;
  final Object? originalError;

  /// User-facing message for snackbars/dialogs. Falls back to a sensible
  /// default per [type] if [message] wasn't supplied at the throw site.
  String get friendlyMessage {
    if (message != null && message!.isNotEmpty) return message!;
    switch (type) {
      case DriveBackupErrorType.notSignedIn:
        return 'Please sign in with Google first.';
      case DriveBackupErrorType.authenticationFailed:
        return 'Could not sign in with Google. Please try again.';
      case DriveBackupErrorType.authorizationFailed:
        return 'Google Drive permission was not granted.';
      case DriveBackupErrorType.uploadFailed:
        return 'Backup upload failed. Please try again.';
      case DriveBackupErrorType.downloadFailed:
        return 'Could not download the backup. Please try again.';
      case DriveBackupErrorType.noBackupFound:
        return 'No backup found for this Google account yet.';
      case DriveBackupErrorType.invalidBackup:
      case DriveBackupErrorType.corruptedBackup:
        return 'This backup could not be read — it may be corrupted.';
      case DriveBackupErrorType.networkError:
        return 'No internet connection. Please check your connection and try again.';
      case DriveBackupErrorType.configurationError:
        return 'Google Sign-In isn\'t set up for this app yet (missing SHA-1 fingerprint / OAuth client in Google Cloud Console). This needs a one-time developer setup step — see the app\'s setup docs.';
      case DriveBackupErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => 'DriveBackupException(type: $type, message: $message)';
}

/// Backs up the app's exported JSON (see `AppDatabase.exportToJson` /
/// `importFromJson`) to the signed-in owner's Google Drive, in the app's
/// private `appDataFolder` space (invisible in the user's regular Drive —
/// no folder for them to accidentally delete). One file is kept and
/// overwritten on every backup, so "restore" always means "restore the
/// latest backup", matching the phone-change flow: new phone → sign in
/// with the same Gmail → restore.
///
/// Deliberately built on `google_sign_in` v6.x rather than v7. v7's
/// silent-session restore (`attemptLightweightAuthentication`, backed by
/// Android's Credential Manager) has an open, unresolved upstream bug
/// where the session is not reliably restored after a full app restart on
/// Android — see flutter/flutter#171745, #174736, #174681. v6's
/// `GoogleSignInClient.silentSignIn()` uses the older, battle-tested
/// native Google Sign-In SDK and does not have this problem, which is
/// what this app's "stay signed in until you explicitly sign out"
/// requirement depends on.
///
/// **Setup required outside this code**: Google Sign-In needs an OAuth
/// client configured in Google Cloud Console for this app (Android SHA-1
/// fingerprint + `google-services.json`, iOS URL scheme in `Info.plist`).
/// Without that one-time platform setup, sign-in will fail with
/// [DriveBackupErrorType.configurationError] regardless of how correct
/// this code is — that configuration can't be done from source code alone.
class GoogleDriveBackupService {
  GoogleDriveBackupService()
      : _googleSignIn = GoogleSignIn(
          scopes: <String>[drive.DriveApi.driveAppdataScope, 'email'],
        );

  final GoogleSignIn _googleSignIn;
  static const String _backupFileName = 'blossom_backup.json';

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Restores a previous session without any UI. Safe to call on every
  /// app start / screen load — v6's `silentSignIn()` reliably restores a
  /// session that was granted in an earlier app run, unlike v7's
  /// lightweight authentication.
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  Future<GoogleSignInAccount> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled the picker — not a real error, but nothing to do.
        throw const DriveBackupException(
          type: DriveBackupErrorType.authenticationFailed,
          message: 'Sign-in was cancelled.',
        );
      }
      return account;
    } on DriveBackupException {
      rethrow;
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<drive.DriveApi> _driveApi() async {
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await signInSilently();
    account ??= await signIn();

    final http.Client? client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw const DriveBackupException(type: DriveBackupErrorType.notSignedIn);
    }
    return drive.DriveApi(client);
  }

  /// Uploads [jsonData] as the single backup file, creating it on first
  /// run or overwriting the existing one on every subsequent backup.
  Future<void> uploadBackup(Map<String, dynamic> jsonData) async {
    try {
      final drive.DriveApi api = await _driveApi();
      final List<int> bytes = utf8.encode(jsonEncode(jsonData));
      final drive.Media media = drive.Media(
          Stream<List<int>>.value(bytes), bytes.length,
          contentType: 'application/json');

      final String? existingId = await _findBackupFileId(api);
      if (existingId != null) {
        await api.files.update(drive.File(), existingId, uploadMedia: media);
      } else {
        final drive.File metadata = drive.File()
          ..name = _backupFileName
          ..mimeType = 'application/json'
          ..parents = <String>['appDataFolder'];
        await api.files.create(metadata, uploadMedia: media);
      }
    } on DriveBackupException {
      rethrow;
    } catch (e) {
      throw _mapError(e, fallback: DriveBackupErrorType.uploadFailed);
    }
  }

  /// Downloads and decodes the latest backup, or throws
  /// [DriveBackupErrorType.noBackupFound] if this account has never backed
  /// up, or [DriveBackupErrorType.corruptedBackup] if the file can't be
  /// parsed as JSON.
  Future<Map<String, dynamic>> downloadLatestBackup() async {
    try {
      final drive.DriveApi api = await _driveApi();
      final String? fileId = await _findBackupFileId(api);
      if (fileId == null) {
        throw const DriveBackupException(
            type: DriveBackupErrorType.noBackupFound);
      }

      final drive.Media media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> bytes = <int>[];
      await for (final List<int> chunk in media.stream) {
        bytes.addAll(chunk);
      }

      try {
        return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      } catch (_) {
        throw const DriveBackupException(
            type: DriveBackupErrorType.corruptedBackup);
      }
    } on DriveBackupException {
      rethrow;
    } catch (e) {
      throw _mapError(e, fallback: DriveBackupErrorType.downloadFailed);
    }
  }

  Future<DateTime?> getLastBackupTime() async {
    try {
      final drive.DriveApi api = await _driveApi();
      final drive.FileList result = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id, modifiedTime)',
      );
      if (result.files == null || result.files!.isEmpty) return null;
      return result.files!.first.modifiedTime;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _findBackupFileId(drive.DriveApi api) async {
    try {
      final drive.FileList result = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id, name)',
      );
      if (result.files == null || result.files!.isEmpty) return null;
      return result.files!.first.id;
    } catch (e) {
      throw _mapError(e, fallback: DriveBackupErrorType.downloadFailed);
    }
  }

  DriveBackupException _mapError(Object e,
      {DriveBackupErrorType fallback = DriveBackupErrorType.unknown}) {
    final String message = e.toString().toLowerCase();
    if (message.contains('socketexception') ||
        message.contains('network') ||
        message.contains('failed host lookup')) {
      return const DriveBackupException(
          type: DriveBackupErrorType.networkError);
    }
    // ApiException: 10 = DEVELOPER_ERROR — the app's SHA-1 fingerprint /
    // package name isn't registered against an OAuth client in Google
    // Cloud Console. This is a one-time app-setup issue, not something a
    // retry or a code change fixes.
    if (message.contains('apiexception: 10') ||
        message.contains('developer_error') ||
        message.contains('sign_in_failed')) {
      return const DriveBackupException(
          type: DriveBackupErrorType.configurationError);
    }
    if (message.contains('apiexception: 12500')) {
      return const DriveBackupException(
          type: DriveBackupErrorType.configurationError);
    }
    return DriveBackupException(
        type: fallback, message: e.toString(), originalError: e);
  }
}
