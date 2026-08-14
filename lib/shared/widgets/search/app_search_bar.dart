import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme.dart';

/// Search input used at the top of list screens (Customers, Appointments,
/// Inventory, ...). Matches the pill-shaped search field from the Figma
/// design.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      style: AppTypography.input(AppColors.foreground),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search, size: AppDimensions.iconMd, color: AppColors.mutedForeground),
        suffixIcon: (controller != null && controller!.text.isNotEmpty)
            ? IconButton(
                icon: Icon(Icons.close, size: AppDimensions.iconSm),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                  onChanged?.call('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
      ),
    );
  }
}
