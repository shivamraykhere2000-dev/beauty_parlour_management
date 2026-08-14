import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Sizing tokens for radii, elevations, icon sizes and fixed component
/// heights, all lifted from the Figma design (`--radius: 0.875rem` etc).
abstract class AppDimensions {
  const AppDimensions._();

  // ---------------------------------------------------------------------
  // Corner radius — base radius is 14px (0.875rem @ 16px root).
  // ---------------------------------------------------------------------
  static double get radiusSm => 10.r; // radius - 4
  static double get radiusMd => 12.r; // radius - 2
  static double get radiusLg => 14.r; // base radius
  static double get radiusXl => 18.r; // radius + 4
  static double get radiusPill => 999.r;

  // ---------------------------------------------------------------------
  // Elevation
  // ---------------------------------------------------------------------
  static const double elevationNone = 0;
  static const double elevationCard = 1;
  static const double elevationRaised = 4;
  static const double elevationModal = 8;

  // ---------------------------------------------------------------------
  // Icon sizes
  // ---------------------------------------------------------------------
  static double get iconSm => 16.r;
  static double get iconMd => 20.r;
  static double get iconLg => 24.r;
  static double get iconXl => 32.r;

  // ---------------------------------------------------------------------
  // Component heights
  // ---------------------------------------------------------------------
  static double get buttonHeight => 52.h;
  static double get buttonHeightSm => 40.h;
  static double get inputHeight => 52.h;
  static double get appBarHeight => 56.h;
  static double get bottomNavHeight => 64.h;
  static double get avatarSm => 32.r;
  static double get avatarMd => 44.r;
  static double get avatarLg => 64.r;
  static double get avatarXl => 88.r;

  // ---------------------------------------------------------------------
  // Border width
  // ---------------------------------------------------------------------
  static const double borderThin = 1;
  static const double borderMedium = 1.5;
}
