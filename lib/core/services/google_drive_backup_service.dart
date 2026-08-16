import 'dart:convert';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Typed failure reasons so the UI can show a specific, friendly message
/// instead of a raw exception string.
enum DriveBackupErrorType {
  noInternet,
  signInFailed,
  notSignedIn,
  noBackupFound,
  corruptedBackup,
  unknown
}

class DriveBackupException implements Exception {
  DriveBackupException(this.type, [this.message]);
  final DriveBackupErrorType type;
  final String? message;

  String get friendlyMessage {
    switch (type) {
      case DriveBackupErrorType.noInternet:
        return 'No internet connection. Please check your connection and try again.';
      case DriveBackupErrorType.signInFailed:
        return 'Could not sign in with Google. Please try again.';
      case DriveBackupErrorType.notSignedIn:
        return 'Please sign in with Google first.';
      case DriveBackupErrorType.noBackupFound:
        return 'No backup found for this Google account yet.';
      case DriveBackupErrorType.corruptedBackup:
        return 'This backup could not be read — it may be corrupted.';
      case DriveBackupErrorType.unknown:
        return message ?? 'Something went wrong. Please try again.';
    }
  }
}

/// Backs up the app's exported JSON (see `AppDatabase.exportToJson` /
/// `importFromJson`) to the signed-in owner's Google Drive, in the app's
/// private `appDataFolder` space (invisible in the user's regular Drive —
/// no folder for them to accidentally delete). One file is kept and
/// overwritten on every backup, so "restore" always means "restore the
/// latest backup", matching the phone-change flow: new phone → sign in
/// with the same Gmail → restore.
///
/// **Setup required outside this code**: Google Sign-In needs an OAuth
/// client configured in Google Cloud Console for this app (Android SHA-1
/// fingerprint + `google-services.json`, iOS URL scheme in `Info.plist`).
/// Without that one-time platform setup, sign-in will fail with
/// [DriveBackupErrorType.signInFailed] regardless of how correct this code
/// is — that configuration can't be done from source code alone.
class GoogleDriveBackupService {
  GoogleDriveBackupService()
      : _googleSignIn = GoogleSignIn(
          scopes: <String>[drive.DriveApi.driveAppdataScope, 'email'],
        );

  final GoogleSignIn _googleSignIn;
  static const String _backupFileName = 'blossom_backup.json';

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

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
        throw DriveBackupException(
            DriveBackupErrorType.signInFailed, 'Sign-in was cancelled.');
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
      throw DriveBackupException(DriveBackupErrorType.notSignedIn);
    }
    return drive.DriveApi(client);
  }

  /// Uploads [jsonData] as the single backup file, creating it on first
  /// run or overwriting the existing one on every subsequent backup.
  Future<void> uploadBackup(Map<String, dynamic> jsonData) async {
    try {
      final drive.DriveApi api = await _driveApi();
      final Uint8List bytes =
          Uint8List.fromList(utf8.encode(jsonEncode(jsonData)));
      final drive.Media media =
          drive.Media(Stream<List<int>>.value(bytes), bytes.length);

      final String? existingId = await _findBackupFileId(api);
      if (existingId != null) {
        await api.files.update(drive.File(), existingId, uploadMedia: media);
      } else {
        final drive.File metadata = drive.File()
          ..name = _backupFileName
          ..parents = <String>['appDataFolder'];
        await api.files.create(metadata, uploadMedia: media);
      }
    } on DriveBackupException {
      rethrow;
    } catch (e) {
      throw _mapError(e);
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
        throw DriveBackupException(DriveBackupErrorType.noBackupFound);
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
        throw DriveBackupException(DriveBackupErrorType.corruptedBackup);
      }
    } on DriveBackupException {
      rethrow;
    } catch (e) {
      throw _mapError(e);
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
    final drive.FileList result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
      $fields: 'files(id, name)',
    );
    if (result.files == null || result.files!.isEmpty) return null;
    return result.files!.first.id;
  }

  DriveBackupException _mapError(Object e) {
    final String message = e.toString().toLowerCase();
    if (message.contains('socketexception') ||
        message.contains('network') ||
        message.contains('failed host lookup')) {
      return DriveBackupException(DriveBackupErrorType.noInternet);
    }
    return DriveBackupException(DriveBackupErrorType.unknown, e.toString());
  }
}
