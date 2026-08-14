import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/theme.dart';

/// Row of 4 dots showing how many PIN digits have been entered — filled
/// primary when entered, accent outline when empty, red when the last
/// attempt was wrong. Mirrors the dot row from the Figma PIN screen.
class PinDotIndicator extends StatelessWidget {
  const PinDotIndicator({
    required this.filledCount,
    super.key,
    this.hasError = false,
  });

  final int filledCount;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(AppConstants.pinLength, (int index) {
        final bool isFilled = index < filledCount;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
          child: AnimatedContainer(
            duration: AppConstants.animationFast,
            width: 16.r,
            height: 16.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled
                  ? (hasError ? AppColors.destructive : AppColors.primary)
                  : Colors.transparent,
              border: Border.all(
                color: isFilled
                    ? (hasError ? AppColors.destructive : AppColors.primary)
                    : AppColors.accent,
                width: 2,
              ),
            ),
          ),
        );
      }),
    );
  }
}
