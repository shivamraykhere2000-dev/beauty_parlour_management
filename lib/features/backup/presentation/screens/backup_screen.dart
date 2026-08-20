import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/services/google_drive_backup_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// Backup & Restore.
///
/// Primary path: sign in with Google, back up to Google Drive
/// (`appDataFolder` — private to this app), and restore the latest backup
/// on a new phone after signing in with the same account. Local
/// file export/import (from the previous version of this screen) is kept
/// as a manual fallback so a working path always exists even without
/// Google sign-in.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  bool _autoBackupEnabled = false;
  GoogleSignInAccount? _account;
  DateTime? _driveLastBackup;

  SharedPreferences get _prefs => getIt<SharedPreferences>();
  GoogleDriveBackupService get _drive =>
      ref.read(googleDriveBackupServiceProvider);

  @override
  void initState() {
    super.initState();
    _autoBackupEnabled =
        _prefs.getBool(AppConstants.prefKeyAutoBackupEnabled) ?? false;
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final GoogleSignInAccount? account = await _drive.signInSilently();
    if (!mounted) return;
    setState(() => _account = account);
    if (account != null) _refreshDriveLastBackup();
  }

  Future<void> _refreshDriveLastBackup() async {
    final DateTime? t = await _drive.getLastBackupTime();
    if (mounted) setState(() => _driveLastBackup = t);
  }

  String? get _localLastBackupLabel {
    final String? iso = _prefs.getString(AppConstants.prefKeyLastBackupDate);
    if (iso == null) return null;
    return _formatDate(DateTime.tryParse(iso));
  }

  String? get _driveLastBackupLabel => _formatDate(_driveLastBackup);

  String? _formatDate(DateTime? dt) {
    if (dt == null) return null;
    final DateTime local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year} at ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final GoogleSignInAccount account = await _drive.signIn();
      if (!mounted) return;
      setState(() => _account = account);
      await _refreshDriveLastBackup();
    } on DriveBackupException catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: e.friendlyMessage, type: AppSnackBarType.error);
    } catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: 'Could not sign in: $e', type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await _drive.signOut();
    if (mounted) setState(() => _account = null);
  }

  Future<void> _backupToDrive() async {
    if (_account == null) {
      AppSnackBar.show(context,
          message: 'Please sign in with Google first.',
          type: AppSnackBarType.error);
      return;
    }
    setState(() => _busy = true);
    try {
      final AppDatabase db = ref.read(databaseProvider);
      final Map<String, dynamic> data = await db.exportToJson();
      await _drive.uploadBackup(data);
      await _prefs.setString(
          AppConstants.prefKeyLastBackupDate, DateTime.now().toIso8601String());
      await _refreshDriveLastBackup();
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Backed up to Google Drive.', type: AppSnackBarType.success);
    } on DriveBackupException catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: e.friendlyMessage, type: AppSnackBarType.error);
    } catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: 'Backup failed: $e', type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Turns the "Auto Backup" preference on/off. Turning it on while
  /// already signed in triggers one immediate backup, so the owner gets
  /// instant confirmation it's working rather than waiting up to 24h (or
  /// the next app open) to see it take effect. The actual once-per-24h
  /// automatic checks happen via `autoBackupCheckProvider`, watched from
  /// `RootShell` on every app open/resume — this screen only owns the
  /// on/off switch and the "back up right now" convenience.
  Future<void> _setAutoBackup(bool value) async {
    setState(() => _autoBackupEnabled = value);
    await _prefs.setBool(AppConstants.prefKeyAutoBackupEnabled, value);
    if (value && _account != null) {
      await _backupToDrive();
    }
  }

  Future<void> _restoreFromDrive() async {
    if (_account == null) {
      AppSnackBar.show(context,
          message: 'Please sign in with Google first.',
          type: AppSnackBarType.error);
      return;
    }
    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: 'Restore Latest Backup?',
      message:
          'This will replace all current data on this device with your latest Google Drive backup for ${_account!.email}. This cannot be undone.',
      confirmLabel: 'Restore',
      isDestructive: true,
    );
    if (!confirmed) return;

    setState(() => _busy = true);
    try {
      final Map<String, dynamic> data = await _drive.downloadLatestBackup();
      final AppDatabase db = ref.read(databaseProvider);
      await db.importFromJson(data);
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Data restored from Google Drive.',
          type: AppSnackBarType.success);
    } on DriveBackupException catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: e.friendlyMessage, type: AppSnackBarType.error);
    } catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: 'Restore failed: $e', type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backupLocally() async {
    setState(() => _busy = true);
    try {
      final AppDatabase db = ref.read(databaseProvider);
      final Map<String, dynamic> data = await db.exportToJson();
      final Directory dir = await getApplicationDocumentsDirectory();
      final String filename =
          'blossom_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final File file = File('${dir.path}/$filename');
      await file
          .writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      await _prefs.setString(
          AppConstants.prefKeyLastBackupDate, DateTime.now().toIso8601String());
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Local backup saved to ${file.path}',
          type: AppSnackBarType.success);
    } catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: 'Backup failed: $e', type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromFile() async {
    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: 'Restore Backup?',
      message:
          'This will replace all current data with the contents of the selected backup file. This cannot be undone.',
      confirmLabel: 'Restore',
      isDestructive: true,
    );
    if (!confirmed) return;

    final FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: <String>['json']);
    if (result == null || result.files.single.path == null) return;

    setState(() => _busy = true);
    try {
      final File file = File(result.files.single.path!);
      final String content = await file.readAsString();
      late final Map<String, dynamic> data;
      try {
        data = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        throw const DriveBackupException(
            type: DriveBackupErrorType.corruptedBackup);
      }
      final AppDatabase db = ref.read(databaseProvider);
      await db.importFromJson(data);
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Data restored successfully.',
          type: AppSnackBarType.success);
    } on DriveBackupException catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: e.friendlyMessage, type: AppSnackBarType.error);
    } catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: 'Restore failed: $e', type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Backup & Restore', onBack: widget.onBack),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          // ---------------------------------------------------------------
          // Google account card
          // ---------------------------------------------------------------
          AppCard(
            child: _account == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(children: <Widget>[
                        const Icon(Icons.account_circle_outlined,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: AppSpacing.xs),
                        Text('Not signed in',
                            style: AppTypography.label(AppColors.foreground)
                                .copyWith(fontWeight: AppTypography.bold))
                      ]),
                      SizedBox(height: 4.h),
                      Text(
                          'Sign in with Google to back up all your data to Drive and restore it on a new phone.',
                          style:
                              AppTypography.caption(AppColors.mutedForeground)),
                      SizedBox(height: AppSpacing.sm),
                      AppButton(
                          label: 'Sign in with Google',
                          icon: Icons.login,
                          onPressed: _busy ? null : _signIn,
                          isLoading: _busy),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      CircleAvatar(
                          radius: 20,
                          backgroundImage: _account!.photoUrl != null
                              ? NetworkImage(_account!.photoUrl!)
                              : null,
                          child: _account!.photoUrl == null
                              ? const Icon(Icons.person)
                              : null),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(_account!.displayName ?? _account!.email,
                                style: AppTypography.label(AppColors.foreground)
                                    .copyWith(fontWeight: AppTypography.bold)),
                            Text(_account!.email,
                                style: AppTypography.caption(
                                    AppColors.mutedForeground)),
                          ],
                        ),
                      ),
                      TextButton(
                          onPressed: _busy ? null : _signOut,
                          child: const Text('Sign out')),
                    ],
                  ),
          ),
          SizedBox(height: AppSpacing.md),

          // ---------------------------------------------------------------
          // Google Drive backup/restore
          // ---------------------------------------------------------------
          AppCard(
            color: const Color(0xFFFFF5F7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[
                  const Icon(Icons.cloud_outlined,
                      color: AppColors.primary, size: 18),
                  SizedBox(width: AppSpacing.xs),
                  Text('Google Drive Backup',
                      style: AppTypography.label(AppColors.primary)
                          .copyWith(fontWeight: AppTypography.bold))
                ]),
                const SizedBox(height: 4),
                Text(
                  'Includes customers, appointments, services, inventory, expenses, notifications, WhatsApp templates and settings. New phone → install app → sign in with this Gmail → Restore.',
                  style: AppTypography.caption(const Color(0xFF6B4848)),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                    _driveLastBackupLabel != null
                        ? 'Last Drive backup: $_driveLastBackupLabel'
                        : 'No Drive backup yet',
                    style: AppTypography.caption(AppColors.mutedForeground)),
                SizedBox(height: AppSpacing.sm),
                Container(
                    height: 1, color: AppColors.primary.withValues(alpha: 0.1)),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Auto Backup',
                              style: AppTypography.label(AppColors.foreground)
                                  .copyWith(fontWeight: AppTypography.bold)),
                          Text(
                              'Automatically backs up once every 24 hours when you open the app',
                              style: AppTypography.caption(
                                  AppColors.mutedForeground)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _autoBackupEnabled,
                      onChanged: _busy ? null : (bool v) => _setAutoBackup(v),
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          AppButton(
              label: 'Back Up to Google Drive',
              icon: Icons.cloud_upload_outlined,
              onPressed: _busy ? null : _backupToDrive,
              isLoading: _busy),
          SizedBox(height: AppSpacing.sm),
          AppButton(
              label: 'Restore Latest Backup',
              icon: Icons.cloud_download_outlined,
              variant: AppButtonVariant.outlined,
              onPressed: _busy ? null : _restoreFromDrive),

          SizedBox(height: AppSpacing.xl),
          Divider(color: AppColors.border),
          SizedBox(height: AppSpacing.sm),

          // ---------------------------------------------------------------
          // Local file fallback (previous implementation, kept as-is)
          // ---------------------------------------------------------------
          Text('Local Backup (manual fallback)',
              style: AppTypography.label(AppColors.foreground)
                  .copyWith(fontWeight: AppTypography.bold)),
          SizedBox(height: 4.h),
          Text(
              'Saves/loads a backup file on this device — useful if Google sign-in is unavailable.',
              style: AppTypography.caption(AppColors.mutedForeground)),
          SizedBox(height: AppSpacing.xs),
          Text(
              _localLastBackupLabel != null
                  ? 'Last local backup: $_localLastBackupLabel'
                  : 'Never backed up locally',
              style: AppTypography.caption(AppColors.mutedForeground)),
          SizedBox(height: AppSpacing.sm),
          AppButton(
              label: 'Back Up to This Device',
              icon: Icons.save_alt_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: _busy ? null : _backupLocally),
          SizedBox(height: AppSpacing.sm),
          AppButton(
              label: 'Restore from File',
              icon: Icons.restore_outlined,
              variant: AppButtonVariant.outlined,
              onPressed: _busy ? null : _restoreFromFile),
        ],
      ),
    );
  }
}
