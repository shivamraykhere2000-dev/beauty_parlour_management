import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme.dart';
import '../buttons/app_button.dart';

/// Empty-state placeholder — "No customers yet", "No appointments today",
/// etc. Optionally shows a call-to-action button (e.g. "Add Customer").
class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    required this.message,
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72.r,
              height: 72.r,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppDimensions.iconXl, color: AppColors.primary),
            ),
            SizedBox(height: AppSpacing.md),
            if (title != null) ...<Widget>[
              Text(
                title!,
                style: AppTypography.h3(AppColors.foreground),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xxs),
            ],
            Text(
              message,
              style: AppTypography.bodySmall(AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
                size: AppButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error-state placeholder shown when a [Failure] bubbles up to the UI.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    required this.message,
    super.key,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyWidget(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      message: message,
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }
}
