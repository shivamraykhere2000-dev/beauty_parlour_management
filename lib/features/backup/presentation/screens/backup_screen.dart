import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// Backup & Restore.
///
/// Fully working **local** JSON export/import today (writes to the app's
/// documents folder and restores from a previously exported file). Google
/// Drive upload is not wired up yet, but slots in as a thin wrapper around
/// [AppDatabase.exportToJson] / [AppDatabase.importFromJson] without
/// changing anything else here.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  String? _lastResultPath;

  SharedPreferences get _prefs => getIt<SharedPreferences>();

  String? get _lastBackupLabel {
    final String? iso = _prefs.getString(AppConstants.prefKeyLastBackupDate);
    if (iso == null) return null;
    final DateTime dt = DateTime.tryParse(iso) ?? DateTime.now();
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _backupNow() async {
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
      setState(() => _lastResultPath = file.path);
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Backup saved to ${file.path}',
          type: AppSnackBarType.success);
    } catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: 'Backup failed: $e', type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: 'Restore Backup?',
      message:
          'This will replace all current data (customers, appointments, services, inventory, expenses) with the contents of the selected backup file. This cannot be undone.',
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
      final Map<String, dynamic> data =
          jsonDecode(content) as Map<String, dynamic>;
      final AppDatabase db = ref.read(databaseProvider);
      await db.importFromJson(data);
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Data restored successfully.',
          type: AppSnackBarType.success);
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
          AppCard(
            color: const Color(0xFFFFF5F7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[
                  const Icon(Icons.cloud_outlined,
                      color: AppColors.primary, size: 18),
                  SizedBox(width: AppSpacing.xs),
                  Text('Local Backup',
                      style: AppTypography.label(AppColors.primary)
                          .copyWith(fontWeight: AppTypography.bold))
                ]),
                const SizedBox(height: 4),
                Text(
                  "All your data stays on this device. \"Back Up Now\" saves a full export to the app's documents folder; \"Restore\" loads it back in. Google Drive sync is planned but not connected yet.",
                  style: AppTypography.caption(const Color(0xFF6B4848)),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Last Backup',
                    style: AppTypography.label(AppColors.foreground)
                        .copyWith(fontWeight: AppTypography.bold)),
                const SizedBox(height: 2),
                Text(_lastBackupLabel ?? 'Never backed up',
                    style: AppTypography.caption(AppColors.mutedForeground)),
                if (_lastResultPath != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(_lastResultPath!,
                      style: AppTypography.caption(AppColors.mutedForeground),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          AppButton(
              label: 'Back Up Now',
              icon: Icons.cloud_upload_outlined,
              onPressed: _busy ? null : _backupNow,
              isLoading: _busy),
          SizedBox(height: AppSpacing.sm),
          AppButton(
              label: 'Restore from File',
              icon: Icons.restore_outlined,
              variant: AppButtonVariant.outlined,
              onPressed: _busy ? null : _restore),
        ],
      ),
    );
  }
}
