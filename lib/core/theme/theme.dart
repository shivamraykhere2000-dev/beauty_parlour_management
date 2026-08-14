import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

export 'color_constants.dart';
export 'dark_theme.dart';
export 'dimensions.dart';
export 'light_theme.dart';
export 'spacing.dart';
export 'typography.dart';

/// Single entrypoint for the app's theming layer.
///
/// Screens should import `core/theme/theme.dart` rather than the individual
/// files, and pull colours/typography/spacing from [AppColors],
/// [AppTypography], [AppSpacing] and [AppDimensions].
abstract class AppTheme {
  const AppTheme._();

  static ThemeData get light => AppLightTheme.theme;
  static ThemeData get dark => AppDarkTheme.theme;
}

/// Holds the user's preferred [ThemeMode]. The salon owner can toggle this
/// from Settings; defaults to light to match the Figma design, which was
/// designed light-first for a reception tablet.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setThemeMode(ThemeMode mode) => state = mode;

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
