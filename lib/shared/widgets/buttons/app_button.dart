import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  destructive,
}

enum AppButtonSize {
  large,
  medium,
  small,
}

/// Common button used throughout the application.
///
/// Features:
/// - Responsive width
/// - Responsive horizontal padding
/// - Prevents Row/RenderFlex overflow
/// - Supports icon + label
/// - Supports loading state
/// - Supports disabled state
/// - Works correctly inside Expanded/Flexible
/// - Text automatically ellipsizes when space is limited
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

  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 12.w);

      case AppButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 10.w);

      case AppButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 8.w);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;

    final Widget buttonContent = _buildContent(context);

    final ButtonStyle commonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(
        Size.zero,
      ),
      maximumSize: WidgetStatePropertyAll<Size>(
        Size.infinite,
      ),
      padding: WidgetStatePropertyAll<EdgeInsets>(
        _padding,
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMd,
          ),
        ),
      ),
    );

    final Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          style: commonStyle,
          onPressed: disabled ? null : onPressed,
          child: buttonContent,
        );
        break;

      case AppButtonVariant.secondary:
        button = ElevatedButton(
          style: commonStyle.copyWith(
            backgroundColor: WidgetStatePropertyAll<Color>(
              AppColors.secondary,
            ),
            foregroundColor: WidgetStatePropertyAll<Color>(
              AppColors.secondaryForeground,
            ),
            elevation: const WidgetStatePropertyAll<double>(0),
          ),
          onPressed: disabled ? null : onPressed,
          child: buttonContent,
        );
        break;

      case AppButtonVariant.destructive:
        button = ElevatedButton(
          style: commonStyle.copyWith(
            backgroundColor: WidgetStatePropertyAll<Color>(
              AppColors.destructive,
            ),
            foregroundColor: WidgetStatePropertyAll<Color>(
              AppColors.destructiveForeground,
            ),
          ),
          onPressed: disabled ? null : onPressed,
          child: buttonContent,
        );
        break;

      case AppButtonVariant.outlined:
        button = OutlinedButton(
          style: commonStyle,
          onPressed: disabled ? null : onPressed,
          child: buttonContent,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          style: commonStyle,
          onPressed: disabled ? null : onPressed,
          child: buttonContent,
        );
        break;
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _height,
      child: button,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: AppDimensions.iconMd,
        height: AppDimensions.iconMd,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _loadingColor(context),
        ),
      );
    }

    // No icon: simple text that can shrink safely.
    if (icon == null) {
      return Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        textAlign: TextAlign.center,
      );
    }

    // Icon + text.
    //
    // Flexible is important here. Without it, a long label can force
    // the Row beyond the available width when this button is inside
    // an Expanded widget.
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          icon,
          size: AppDimensions.iconMd,
        ),
        SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.center,
          ),
        ),
      ],
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
