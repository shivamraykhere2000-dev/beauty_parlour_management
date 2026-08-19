import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../buttons/app_button.dart';

/// Generic content dialog — title, body, and up to two actions. Every
/// custom dialog in the app (edit sheets, info popups, etc.) should build
/// on this rather than calling [showDialog] with a raw [AlertDialog].
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    super.key,
    this.content,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final Widget? content;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  static Future<void> show(
    BuildContext context, {
    required String title,
    Widget? content,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AppDialog(
        title: title,
        content: content,
        primaryActionLabel: primaryActionLabel,
        onPrimaryAction: onPrimaryAction,
        secondaryActionLabel: secondaryActionLabel,
        onSecondaryAction: onSecondaryAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content,
      actionsPadding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      actions: <Widget>[
        if (secondaryActionLabel != null)
          Expanded(
            child: AppButton(
              label: secondaryActionLabel!,
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.medium,
              onPressed: onSecondaryAction ?? () => Navigator.of(context).pop(),
            ),
          ),
        if (secondaryActionLabel != null && primaryActionLabel != null)
          SizedBox(width: AppSpacing.sm),
        if (primaryActionLabel != null)
          Expanded(
            child: AppButton(
              label: primaryActionLabel!,
              size: AppButtonSize.medium,
              onPressed: onPrimaryAction,
            ),
          ),
      ],
    );
  }
}

/// Destructive/confirm-style dialog — "Delete customer?", "Cancel
/// appointment?", etc. Returns `true` if the user confirmed, `false`/`null`
/// otherwise.
class ConfirmationDialog {
  const ConfirmationDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message, style: AppTypography.bodyMedium(AppColors.foreground)),
        actionsPadding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        actions: <Widget>[
          Expanded(
            child: AppButton(
              label: cancelLabel,
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.medium,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              label: confirmLabel,
              variant: isDestructive
                  ? AppButtonVariant.destructive
                  : AppButtonVariant.primary,
              size: AppButtonSize.medium,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
