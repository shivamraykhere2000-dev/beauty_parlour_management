import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme.dart';

enum AppButtonVariant { primary, secondary, outlined, text, destructive }

enum AppButtonSize { large, medium, small }

/// The single button widget used everywhere in the app. Wraps Material's
/// button family so every screen gets identical sizing, radius and
/// disabled/loading states instead of re-implementing them ad hoc.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  double get _height {
    switch (size) {
      case AppButtonSize.large:
        return AppDimensions.buttonHeight;
      case AppButtonSize.medium:
        return AppDimensions.buttonHeightSm;
      case AppButtonSize.small:
        return 36.h;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final Widget child = isLoading
        ? SizedBox(
            width: AppDimensions.iconMd,
            height: AppDimensions.iconMd,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _loadingColor(context),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: AppDimensions.iconMd),
                SizedBox(width: AppSpacing.xs),
              ],
              Text(label),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.destructive => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.destructive,
            foregroundColor: AppColors.destructiveForeground,
          ),
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.secondary => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.secondaryForeground,
            elevation: AppDimensions.elevationNone,
          ),
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
    };

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _height,
      child: button,
    );
  }

  Color _loadingColor(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        return AppColors.primaryForeground;
      case AppButtonVariant.secondary:
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return AppColors.primary;
    }
  }
}
