import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Google Drive scope used by this application.
///
/// `drive.file` is intentionally narrower than full Drive access.
/// The backup is stored in the application's private appDataFolder.
const List<String> _googleDriveScopes = <String>[
  'https://www.googleapis.com/auth/drive.file',
];

/// The OAuth Web Client ID created in Google Cloud Console.
///
/// IMPORTANT:
/// This must be your WEB OAuth client ID, not the Android client ID.
///
/// Example:
/// 1234567890-xxxxxxxxxxxxxxxx.apps.googleusercontent.com
const String _serverClientId =
    '201522328304-846hcut8ibn68tenee5g5i62o4aidvhb.apps.googleusercontent.com';

/// The name of the backup file stored in Google Drive.
const String _backupFileName = 'beauty_parlour_backup.json';

/// Exception categories used by the BackupScreen.
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
  unknown,
}

/// Application-specific exception for Google Drive backup operations.
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
      case DriveBackupErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() {
    return 'DriveBackupException('
        'type: $type, '
        'message: $message'
        ')';
  }
}

/// Handles:
///
/// - Google Sign-In
/// - Google Drive authorization
/// - Uploading backup JSON
/// - Updating the existing backup
/// - Downloading the latest backup
/// - Reading last backup time
/// - Signing out
///
/// IMPORTANT:
/// The public methods in this class are intentionally kept compatible
/// with the existing BackupScreen.
///
/// BackupScreen should NOT need to be changed.
class GoogleDriveBackupService {
  GoogleDriveBackupService();

  // ---------------------------------------------------------------------------
  // GOOGLE SIGN-IN
  // ---------------------------------------------------------------------------

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  GoogleSignInAccount? _currentUser;

  bool _initialized = false;

  /// Initializes Google Sign-In.
  ///
  /// Must be called before signIn(), signInSilently(), etc.
  Future<void> _initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await _googleSignIn.initialize(
        serverClientId: _serverClientId,
      );

      _initialized = true;
    } on GoogleSignInException catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.authenticationFailed,
        message: 'Google Sign-In could not be initialized.',
        originalError: e,
      );
    } catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.authenticationFailed,
        message: 'Google Sign-In initialization failed.',
        originalError: e,
      );
    }
  }

  /// Returns the currently signed-in account, if available.
  ///
  /// We keep this private because google_sign_in 7.x no longer exposes
  /// GoogleSignIn.currentUser in the old way.
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Initializes Google Sign-In and tries to restore the previous
  /// lightweight authentication state.
  ///
  /// This method is called by your BackupScreen from initState().
  Future<GoogleSignInAccount?> signInSilently() async {
    await _initialize();

    try {
      // In google_sign_in 7.x, lightweight authentication is initiated
      // after initialization.
      final Future<GoogleSignInAccount?>? result =
          _googleSignIn.attemptLightweightAuthentication();

      if (result != null) {
        _currentUser = await result;
      }
    } on GoogleSignInException catch (e) {
      // Silent authentication failure should generally not break
      // the BackupScreen. The user can still press "Sign in with Google".
      _currentUser = null;

      // Do not throw for lightweight authentication.
      //
      // The actual interactive sign-in will show the proper error.
      print(
        'Google silent sign-in failed: $e',
      );
    } catch (e) {
      _currentUser = null;

      print(
        'Google silent sign-in failed: $e',
      );
    }

    return _currentUser;
  }

  /// Interactive Google Sign-In.
  ///
  /// This method matches:
  ///
  /// final GoogleSignInAccount account =
  ///     await _drive.signIn();
  Future<GoogleSignInAccount> signIn() async {
    await _initialize();

    try {
      // If we already have an authenticated account, use it.
      if (_currentUser != null) {
        return _currentUser!;
      }

      if (!_googleSignIn.supportsAuthenticate()) {
        throw const DriveBackupException(
          type: DriveBackupErrorType.authenticationFailed,
          message: 'Google Sign-In authentication is not supported '
              'on this platform.',
        );
      }

      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      _currentUser = account;

      return account;
    } on DriveBackupException {
      rethrow;
    } on GoogleSignInException catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.authenticationFailed,
        message: _googleSignInErrorMessage(e),
        originalError: e,
      );
    } catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.authenticationFailed,
        message: 'Google Sign-In failed.',
        originalError: e,
      );
    }
  }

  /// Signs out from Google.
  ///
  /// This matches your BackupScreen:
  ///
  /// await _drive.signOut();
  Future<void> signOut() async {
    await _initialize();

    try {
      await _googleSignIn.signOut();

      _currentUser = null;
    } on GoogleSignInException catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.authenticationFailed,
        message: 'Unable to sign out from Google.',
        originalError: e,
      );
    } catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.authenticationFailed,
        message: 'Unable to sign out from Google.',
        originalError: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE DRIVE AUTHORIZATION
  // ---------------------------------------------------------------------------

  /// Makes sure the user is signed in and has permission to access
  /// Google Drive for this application.
  Future<void> _ensureDriveAuthorization({
    bool promptIfNecessary = true,
  }) async {
    await _initialize();

    GoogleSignInAccount? user = _currentUser;

    if (user == null) {
      try {
        user = await _googleSignIn.attemptLightweightAuthentication();
      } catch (_) {
        user = null;
      }
    }

    if (user == null) {
      throw const DriveBackupException(
        type: DriveBackupErrorType.notSignedIn,
        message: 'Please sign in with Google first.',
      );
    }

    _currentUser = user;

    try {
      final GoogleSignInClientAuthorization? existingAuthorization =
          await user.authorizationClient.authorizationForScopes(
        _googleDriveScopes,
      );

      if (existingAuthorization != null &&
          existingAuthorization.accessToken.isNotEmpty) {
        return;
      }

      if (!promptIfNecessary) {
        throw const DriveBackupException(
          type: DriveBackupErrorType.authorizationFailed,
          message: 'Google Drive permission has not been granted.',
        );
      }

      await user.authorizationClient.authorizeScopes(
        _googleDriveScopes,
      );
    } on DriveBackupException {
      rethrow;
    } on GoogleSignInException catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.authorizationFailed,
        message: 'Google Drive permission was not granted.',
        originalError: e,
      );
    } catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.authorizationFailed,
        message: 'Unable to authorize Google Drive.',
        originalError: e,
      );
    }
  }

  /// Returns authorization headers for Google Drive REST/API requests.
  Future<Map<String, String>> _getAuthorizationHeaders() async {
    await _ensureDriveAuthorization();

    final user = _currentUser;

    if (user == null) {
      throw const DriveBackupException(
        type: DriveBackupErrorType.notSignedIn,
        message: 'Please sign in with Google first.',
      );
    }

    try {
      final Map<String, String>? headers =
          await user.authorizationClient.authorizationHeaders(
        _googleDriveScopes,
        promptIfNecessary: true,
      );

      if (headers == null || headers.isEmpty) {
        throw const DriveBackupException(
          type: DriveBackupErrorType.authorizationFailed,
          message: 'Could not obtain Google Drive authorization.',
        );
      }

      return headers;
    } on DriveBackupException {
      rethrow;
    } on GoogleSignInException catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.authorizationFailed,
        message: 'Could not obtain Google Drive authorization.',
        originalError: e,
      );
    } catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.authorizationFailed,
        message: 'Could not obtain Google Drive authorization.',
        originalError: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DRIVE CLIENT
  // ---------------------------------------------------------------------------

  /// Creates a Google Drive API client using the current Google access token.
  ///
  /// We intentionally create the client from authorization headers instead
  /// of using the old google_sign_in authenticatedClient() API.
  ///
  /// Returns both the [drive.DriveApi] and the underlying [http.Client] —
  /// `DriveApi` does not expose the client it was built with, so callers
  /// must hold onto this reference themselves in order to close it.
  Future<({drive.DriveApi api, http.Client client})> _getDriveApi() async {
    final Map<String, String> headers = await _getAuthorizationHeaders();

    final http.Client httpClient = _AuthorizedHttpClient(headers);

    return (api: drive.DriveApi(httpClient), client: httpClient);
  }

  // ---------------------------------------------------------------------------
  // FIND BACKUP
  // ---------------------------------------------------------------------------

  /// Finds the existing backup file in Google's private appDataFolder.
  Future<drive.File?> _findBackupFile(
    drive.DriveApi driveApi,
  ) async {
    try {
      final drive.FileList result = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName' "
            "and trashed = false",
        $fields: 'files(id,name,size,createdTime,modifiedTime)',
        pageSize: 10,
      );

      final List<drive.File>? files = result.files;

      if (files == null || files.isEmpty) {
        return null;
      }

      return files.first;
    } on drive.DetailedApiRequestError catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.downloadFailed,
        message: 'Unable to find the backup in Google Drive.',
        originalError: e,
      );
    } catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.downloadFailed,
        message: 'Unable to find the backup in Google Drive.',
        originalError: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UPLOAD
  // ---------------------------------------------------------------------------

  /// Uploads a backup to Google Drive.
  ///
  /// If a backup already exists:
  ///
  ///     existing file → update
  ///
  /// Otherwise:
  ///
  ///     no file → create
  ///
  /// This matches the behavior expected by your BackupScreen.
  Future<void> uploadBackup(
    Map<String, dynamic> data,
  ) async {
    drive.DriveApi? driveApi;
    http.Client? httpClient;

    try {
      final ({drive.DriveApi api, http.Client client}) result =
          await _getDriveApi();
      driveApi = result.api;
      httpClient = result.client;

      final String jsonData = jsonEncode(data);

      final List<int> bytes = utf8.encode(jsonData);

      final drive.File? existingFile = await _findBackupFile(driveApi);

      final drive.Media media = drive.Media(
        Stream<List<int>>.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );

      if (existingFile != null && existingFile.id != null) {
        // ---------------------------------------------------------------
        // UPDATE EXISTING BACKUP
        // ---------------------------------------------------------------

        await driveApi.files.update(
          drive.File(
            name: _backupFileName,
            mimeType: 'application/json',
          ),
          existingFile.id!,
          uploadMedia: media,
        );
      } else {
        // ---------------------------------------------------------------
        // CREATE NEW BACKUP
        // ---------------------------------------------------------------

        final drive.File metadata = drive.File()
          ..name = _backupFileName
          ..mimeType = 'application/json'
          ..parents = <String>[
            'appDataFolder',
          ];

        await driveApi.files.create(
          metadata,
          uploadMedia: media,
        );
      }
    } on DriveBackupException {
      rethrow;
    } on drive.DetailedApiRequestError catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.uploadFailed,
        message: _driveApiErrorMessage(e),
        originalError: e,
      );
    } catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.uploadFailed,
        message: 'Backup upload failed.',
        originalError: e,
      );
    } finally {
      httpClient?.close();
    }
  }

  // ---------------------------------------------------------------------------
  // DOWNLOAD
  // ---------------------------------------------------------------------------

  /// Downloads the latest backup from Google Drive.
  ///
  /// Returns the JSON backup as:
  ///
  ///     Map<String, dynamic>
  ///
  /// This exactly matches your BackupScreen.
  Future<Map<String, dynamic>> downloadLatestBackup() async {
    drive.DriveApi? driveApi;
    http.Client? httpClient;

    try {
      final ({drive.DriveApi api, http.Client client}) result =
          await _getDriveApi();
      driveApi = result.api;
      httpClient = result.client;

      final drive.File? backupFile = await _findBackupFile(driveApi);

      if (backupFile == null || backupFile.id == null) {
        throw const DriveBackupException(
          type: DriveBackupErrorType.noBackupFound,
          message: 'No backup was found in Google Drive.',
        );
      }

      final drive.Media media = await driveApi.files.get(
        backupFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> bytes = await _readMedia(media);

      if (bytes.isEmpty) {
        throw const DriveBackupException(
          type: DriveBackupErrorType.invalidBackup,
          message: 'The Google Drive backup is empty.',
        );
      }

      final String jsonString = utf8.decode(bytes);

      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        throw const DriveBackupException(
          type: DriveBackupErrorType.invalidBackup,
          message: 'The Google Drive backup has an invalid format.',
        );
      }

      return decoded;
    } on DriveBackupException {
      rethrow;
    } on FormatException catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.invalidBackup,
        message: 'The Google Drive backup is not valid JSON.',
        originalError: e,
      );
    } on drive.DetailedApiRequestError catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.downloadFailed,
        message: _driveApiErrorMessage(e),
        originalError: e,
      );
    } catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.downloadFailed,
        message: 'Unable to download the latest backup.',
        originalError: e,
      );
    } finally {
      httpClient?.close();
    }
  }

  // ---------------------------------------------------------------------------
  // LAST BACKUP TIME
  // ---------------------------------------------------------------------------

  /// Returns the last modified time of the backup.
  ///
  /// Your BackupScreen uses this to display:
  ///
  ///     Last backup
  ///     X minutes ago
  ///
  Future<DateTime?> getLastBackupTime() async {
    drive.DriveApi? driveApi;
    http.Client? httpClient;

    try {
      final ({drive.DriveApi api, http.Client client}) result =
          await _getDriveApi();
      driveApi = result.api;
      httpClient = result.client;

      final drive.File? backupFile = await _findBackupFile(driveApi);

      if (backupFile == null) {
        return null;
      }

      return backupFile.modifiedTime;
    } on DriveBackupException {
      rethrow;
    } on drive.DetailedApiRequestError catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.downloadFailed,
        message: 'Unable to read the last backup time.',
        originalError: e,
      );
    } catch (e) {
      throw DriveBackupException(
        type: DriveBackupErrorType.downloadFailed,
        message: 'Unable to read the last backup time.',
        originalError: e,
      );
    } finally {
      httpClient?.close();
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Future<List<int>> _readMedia(
    drive.Media media,
  ) async {
    final List<int> result = <int>[];

    await for (final List<int> chunk in media.stream) {
      result.addAll(chunk);
    }

    return result;
  }

  String _googleSignInErrorMessage(
    GoogleSignInException error,
  ) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google Sign-In was cancelled.';

      case GoogleSignInExceptionCode.interrupted:
        return 'Google Sign-In was interrupted.';

      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google Sign-In is not configured correctly. '
            'Please check the Android package name, SHA-1, '
            'OAuth client IDs and Google Cloud configuration.';

      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Sign-In provider configuration is incorrect.';

      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google Sign-In UI is currently unavailable.';

      case GoogleSignInExceptionCode.userMismatch:
        return 'The selected Google account could not be used.';

      case GoogleSignInExceptionCode.unknownError:
        return 'Google Sign-In failed. '
            'Please check your Google Cloud Console configuration.';
    }
  }

  String _driveApiErrorMessage(
    drive.DetailedApiRequestError error,
  ) {
    final int? status = error.status;

    if (status == 401) {
      return 'Google Drive authorization expired. '
          'Please sign in again.';
    }

    if (status == 403) {
      return 'Google Drive permission was denied. '
          'Please allow Drive access for this app.';
    }

    if (status == 404) {
      return 'The Google Drive backup could not be found.';
    }

    return 'Google Drive request failed'
        '${status != null ? ' ($status)' : ''}.';
  }
}

/// HTTP client that adds the authorization headers returned by
/// google_sign_in 7.x.
///
/// This is used only for Google API requests.
///
/// It avoids using the old:
///
///     authenticatedClient()
///
/// API from older google_sign_in implementations.
class _AuthorizedHttpClient extends http.BaseClient {
  _AuthorizedHttpClient(
    Map<String, String> headers,
  ) : _headers = Map<String, String>.from(
          headers,
        );

  final Map<String, String> _headers;

  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(
    http.BaseRequest request,
  ) {
    request.headers.addAll(_headers);

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
