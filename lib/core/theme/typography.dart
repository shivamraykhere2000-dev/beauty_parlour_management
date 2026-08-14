import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Typography scale lifted from the Figma design.
///
/// Two font families are used throughout the app:
/// - `Playfair Display` — serif, used for headings / brand moments
///   (AppBar titles, hero numbers, screen headers).
/// - `DM Sans` — sans-serif, used for all body copy, labels, buttons
///   and inputs.
///
/// Root design font-size is 15px, so the scale below mirrors the Tailwind
/// scale used in the source design (h1 = text-2xl, h2 = text-xl,
/// h3 = text-lg, h4/body = text-base) computed against that 15px root.
abstract class AppTypography {
  const AppTypography._();

  static const String headingFontFamily = 'PlayfairDisplay';
  static const String bodyFontFamily = 'DMSans';

  static const FontWeight normal = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // ---------------------------------------------------------------------
  // Headings (Playfair Display)
  // ---------------------------------------------------------------------
  static TextStyle h1(Color color) => TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 24.sp,
        fontWeight: bold,
        color: color,
        height: 1.3,
      );

  static TextStyle h2(Color color) => TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 20.sp,
        fontWeight: bold,
        color: color,
        height: 1.3,
      );

  static TextStyle h3(Color color) => TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 18.sp,
        fontWeight: semiBold,
        color: color,
        height: 1.3,
      );

  static TextStyle heroNumber(Color color) => TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 34.sp,
        fontWeight: bold,
        color: color,
        height: 1.2,
      );

  // ---------------------------------------------------------------------
  // Body copy (DM Sans)
  // ---------------------------------------------------------------------
  static TextStyle bodyLarge(Color color) => TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 16.sp,
        fontWeight: normal,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 15.sp,
        fontWeight: normal,
        color: color,
        height: 1.5,
      );

  static TextStyle bodySmall(Color color) => TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 13.sp,
        fontWeight: normal,
        color: color,
        height: 1.5,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 12.sp,
        fontWeight: normal,
        color: color,
        height: 1.4,
      );

  static TextStyle label(Color color) => TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 15.sp,
        fontWeight: medium,
        color: color,
        height: 1.5,
      );

  static TextStyle button(Color color) => TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 15.sp,
        fontWeight: medium,
        color: color,
        height: 1.5,
      );

  static TextStyle input(Color color) => TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 15.sp,
        fontWeight: normal,
        color: color,
        height: 1.5,
      );

  /// Default text theme built from the scale above, parameterised by the
  /// on-surface colour so it can be reused for both light and dark themes.
  static TextTheme textTheme(Color onSurface, Color onSurfaceMuted) {
    return TextTheme(
      displayLarge: h1(onSurface),
      displayMedium: h2(onSurface),
      displaySmall: h3(onSurface),
      headlineLarge: h1(onSurface),
      headlineMedium: h2(onSurface),
      headlineSmall: h3(onSurface),
      titleLarge: h3(onSurface),
      titleMedium: label(onSurface),
      titleSmall: label(onSurface),
      bodyLarge: bodyLarge(onSurface),
      bodyMedium: bodyMedium(onSurface),
      bodySmall: bodySmall(onSurfaceMuted),
      labelLarge: button(onSurface),
      labelMedium: label(onSurface),
      labelSmall: caption(onSurfaceMuted),
    );
  }
}
