import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'color_constants.dart';
import 'dimensions.dart';
import 'typography.dart';

/// Light theme — the primary theme used throughout the salon-owner app.
/// Mirrors the `:root` design tokens from the Figma export exactly.
class AppLightTheme {
  const AppLightTheme._();

  static ThemeData get theme {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      tertiary: AppColors.accent,
      onTertiary: AppColors.accentForeground,
      error: AppColors.destructive,
      onError: AppColors.destructiveForeground,
      surface: AppColors.card,
      onSurface: AppColors.cardForeground,
      surfaceContainerHighest: AppColors.muted,
      onSurfaceVariant: AppColors.mutedForeground,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      fontFamily: AppTypography.bodyFontFamily,
      textTheme: AppTypography.textTheme(
        AppColors.foreground,
        AppColors.mutedForeground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        elevation: AppDimensions.elevationNone,
        centerTitle: false,
        titleTextStyle: AppTypography.h3(AppColors.primaryForeground),
        iconTheme: const IconThemeData(color: AppColors.primaryForeground),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: AppDimensions.elevationCard,
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          disabledBackgroundColor: AppColors.muted,
          disabledForegroundColor: AppColors.mutedForeground,
          minimumSize: Size(double.infinity, AppDimensions.buttonHeight),
          textStyle: AppTypography.button(AppColors.primaryForeground),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          elevation: AppDimensions.elevationNone,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: Size(double.infinity, AppDimensions.buttonHeight),
          textStyle: AppTypography.button(AppColors.primary),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.button(AppColors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        hintStyle: AppTypography.input(AppColors.mutedForeground),
        labelStyle: AppTypography.label(AppColors.foreground),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 14.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.popover,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        titleTextStyle: AppTypography.h3(AppColors.popoverForeground),
        contentTextStyle: AppTypography.bodyMedium(AppColors.popoverForeground),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.popover,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        elevation: AppDimensions.elevationRaised,
        height: AppDimensions.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return AppTypography.caption(
            selected ? AppColors.primary : AppColors.mutedForeground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.mutedForeground,
            size: AppDimensions.iconMd,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        elevation: AppDimensions.elevationRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.foreground,
        contentTextStyle: AppTypography.bodyMedium(AppColors.background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: AppDimensions.borderThin,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.switchBackground;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.mutedForeground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary,
        labelStyle: AppTypography.caption(AppColors.secondaryForeground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          side: BorderSide.none,
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.muted,
      ),
      dividerColor: AppColors.border,
      splashFactory: InkRipple.splashFactory,
    );
  }
}
