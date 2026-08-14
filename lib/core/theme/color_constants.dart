import 'package:flutter/material.dart';

/// Centralised colour palette lifted 1:1 from the Figma design tokens
/// (`theme.css`). No colour literal should ever appear outside this file —
/// every widget must reference these constants instead of hardcoding hex
/// values.
abstract class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------------
  // Light theme — base surface colours
  // ---------------------------------------------------------------------
  static const Color background = Color(0xFFFDF8F5);
  static const Color foreground = Color(0xFF2C1810);

  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF2C1810);

  static const Color popover = Color(0xFFFFFFFF);
  static const Color popoverForeground = Color(0xFF2C1810);

  // ---------------------------------------------------------------------
  // Brand colours
  // ---------------------------------------------------------------------
  static const Color primary = Color(0xFFA0526A);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFFF5EDE8);
  static const Color secondaryForeground = Color(0xFF2C1810);

  static const Color accent = Color(0xFFC9956C);
  static const Color accentForeground = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------
  // Muted / neutral
  // ---------------------------------------------------------------------
  static const Color muted = Color(0xFFF0EAE7);
  static const Color mutedForeground = Color(0xFF9A7A7A);

  // ---------------------------------------------------------------------
  // State colours
  // ---------------------------------------------------------------------
  static const Color destructive = Color(0xFFD4183D);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF4CAF87);
  static const Color warning = Color(0xFFC9956C);

  // ---------------------------------------------------------------------
  // Borders / inputs / rings
  // ---------------------------------------------------------------------
  static const Color border = Color(0x1FA0526A); // rgba(160,82,106,0.12)
  static const Color input = Colors.transparent;
  static const Color inputBackground = Color(0xFFFFF5F0);
  static const Color switchBackground = Color(0xFFDEC8CC);
  static const Color ring = Color(0x66A0526A); // rgba(160,82,106,0.4)

  // ---------------------------------------------------------------------
  // Chart palette
  // ---------------------------------------------------------------------
  static const Color chart1 = Color(0xFFA0526A);
  static const Color chart2 = Color(0xFFC9956C);
  static const Color chart3 = Color(0xFFE8B4B8);
  static const Color chart4 = Color(0xFF4CAF87);
  static const Color chart5 = Color(0xFF7B68EE);
  static const List<Color> chartPalette = <Color>[
    chart1,
    chart2,
    chart3,
    chart4,
    chart5,
  ];

  // ---------------------------------------------------------------------
  // Dark theme
  // ---------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkForeground = Color(0xFFFAFAFA);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkCardForeground = Color(0xFFFAFAFA);
  static const Color darkSecondary = Color(0xFF444444);
  static const Color darkMuted = Color(0xFF444444);
  static const Color darkMutedForeground = Color(0xFFB5B5B5);
  static const Color darkBorder = Color(0xFF444444);
  static const Color darkDestructive = Color(0xFF7A2331);
  static const Color darkDestructiveForeground = Color(0xFFE0777F);
  static const Color darkRing = Color(0xFF707070);

  // ---------------------------------------------------------------------
  // Gradients — the Figma design's `bg-gradient-to-r from-primary to-accent`
  // used on header bars, splash background and hero cards.
  // ---------------------------------------------------------------------
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[primary, accent],
  );
}
