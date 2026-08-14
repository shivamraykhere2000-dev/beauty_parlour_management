import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'color_constants.dart';
import 'dimensions.dart';
import 'typography.dart';

/// Dark theme counterpart. The Figma export only fully specifies the light
/// theme (the app is designed to run light-first for a salon reception
/// tablet), so the dark palette here follows Material 3 dark-surface
/// conventions while keeping the brand primary colour recognisable.
class AppDarkTheme {
  const AppDarkTheme._();

  static ThemeData get theme {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkForeground,
      tertiary: AppColors.accent,
      onTertiary: AppColors.accentForeground,
      error: AppColors.darkDestructive,
      onError: AppColors.darkDestructiveForeground,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkCardForeground,
      surfaceContainerHighest: AppColors.darkMuted,
      onSurfaceVariant: AppColors.darkMutedForeground,
      outline: AppColors.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      fontFamily: AppTypography.bodyFontFamily,
      textTheme: AppTypography.textTheme(
        AppColors.darkForeground,
        AppColors.darkMutedForeground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.darkForeground,
        elevation: AppDimensions.elevationNone,
        centerTitle: false,
        titleTextStyle: AppTypography.h3(AppColors.darkForeground),
        iconTheme: const IconThemeData(color: AppColors.darkForeground),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: AppDimensions.elevationCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          disabledBackgroundColor: AppColors.darkMuted,
          disabledForegroundColor: AppColors.darkMutedForeground,
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
        fillColor: AppColors.darkMuted,
        hintStyle: AppTypography.input(AppColors.darkMutedForeground),
        labelStyle: AppTypography.label(AppColors.darkForeground),
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
          borderSide: const BorderSide(color: AppColors.darkDestructive),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        titleTextStyle: AppTypography.h3(AppColors.darkForeground),
        contentTextStyle: AppTypography.bodyMedium(AppColors.darkForeground),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        indicatorColor: AppColors.primary.withValues(alpha: 0.20),
        elevation: AppDimensions.elevationRaised,
        height: AppDimensions.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return AppTypography.caption(
            selected ? AppColors.primary : AppColors.darkMutedForeground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.darkMutedForeground,
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
        backgroundColor: AppColors.darkMuted,
        contentTextStyle: AppTypography.bodyMedium(AppColors.darkForeground),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: AppDimensions.borderThin,
        space: 1,
      ),
      dividerColor: AppColors.darkBorder,
      splashFactory: InkRipple.splashFactory,
    );
  }
}
