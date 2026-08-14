import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing scale — every margin/padding value in the app must come from
/// here. Values follow a 4pt base grid, mirroring the Tailwind spacing
/// scale used in the Figma export (p-1, p-2, p-3, p-4, p-6, p-8...).
abstract class AppSpacing {
  const AppSpacing._();

  static double get xxs => 4.w;
  static double get xs => 8.w;
  static double get sm => 12.w;
  static double get md => 16.w;
  static double get lg => 20.w;
  static double get xl => 24.w;
  static double get xxl => 32.w;
  static double get xxxl => 40.w;

  /// Standard screen edge padding used on every screen in the design.
  static double get screenHorizontal => 16.w;
  static double get screenVertical => 16.h;

  /// Gap between stacked cards / list items.
  static double get cardGap => 12.h;
}
