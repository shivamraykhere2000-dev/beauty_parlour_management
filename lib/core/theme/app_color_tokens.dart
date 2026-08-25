import 'package:flutter/material.dart';

import 'color_constants.dart';

/// Colours that must actually change between light and dark mode —
/// surfaces and text, not brand colours. Registered on both
/// [ThemeData]s as a [ThemeExtension] and read via `context.colors.xxx`
/// (see `core/extensions/context_extensions.dart`), which — unlike the
/// static `AppColors.xxx` constants — correctly rebuilds every widget
/// that reads it whenever [themeModeProvider] changes.
///
/// Brand colours (`AppColors.primary`, `.accent`, `.destructive`,
/// `.success`, chart colours, `.primaryGradient`) are intentionally left
/// as plain static constants in [AppColors] — the design keeps the same
/// brand colours in both themes, only surfaces/text adapt.
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.inputBackground,
    required this.switchBackground,
    required this.ring,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color inputBackground;
  final Color switchBackground;
  final Color ring;

  static const AppColorTokens light = AppColorTokens(
    background: AppColors.background,
    foreground: AppColors.foreground,
    card: AppColors.card,
    cardForeground: AppColors.cardForeground,
    popover: AppColors.popover,
    popoverForeground: AppColors.popoverForeground,
    secondary: AppColors.secondary,
    secondaryForeground: AppColors.secondaryForeground,
    muted: AppColors.muted,
    mutedForeground: AppColors.mutedForeground,
    border: AppColors.border,
    inputBackground: AppColors.inputBackground,
    switchBackground: AppColors.switchBackground,
    ring: AppColors.ring,
  );

  static const AppColorTokens dark = AppColorTokens(
    background: AppColors.darkBackground,
    foreground: AppColors.darkForeground,
    card: AppColors.darkCard,
    cardForeground: AppColors.darkCardForeground,
    popover: AppColors.darkCard,
    popoverForeground: AppColors.darkCardForeground,
    secondary: AppColors.darkSecondary,
    secondaryForeground: AppColors.darkForeground,
    muted: AppColors.darkMuted,
    mutedForeground: AppColors.darkMutedForeground,
    border: AppColors.darkBorder,
    inputBackground: Color(0xFF2A2420),
    switchBackground: Color(0xFF5A5148),
    ring: AppColors.darkRing,
  );

  @override
  AppColorTokens copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? popoverForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? border,
    Color? inputBackground,
    Color? switchBackground,
    Color? ring,
  }) {
    return AppColorTokens(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      popover: popover ?? this.popover,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      inputBackground: inputBackground ?? this.inputBackground,
      switchBackground: switchBackground ?? this.switchBackground,
      ring: ring ?? this.ring,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      popoverForeground: Color.lerp(popoverForeground, other.popoverForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryForeground: Color.lerp(secondaryForeground, other.secondaryForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      switchBackground: Color.lerp(switchBackground, other.switchBackground, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
    );
  }
}

/// `context.colors.foreground`, `context.colors.background`, etc. — the
/// theme-reactive way to read surface/text colours. Unlike the static
/// `AppColors.xxx` constants, reading through `Theme.of(context)` here
/// means every widget that uses this correctly rebuilds with the right
/// colours when the app switches between light and dark mode.
extension AppColorTokensX on BuildContext {
  AppColorTokens get colors =>
      Theme.of(this).extension<AppColorTokens>() ?? AppColorTokens.light;
}
