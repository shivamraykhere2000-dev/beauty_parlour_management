import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Base card container used for dashboard stat tiles, list items and
/// detail sections throughout the app. Wraps [Card] with the design's
/// standard padding, radius and optional tap ripple.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding,
    this.color,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: padding ?? EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    return Container(
      margin: margin,
      child: Card(
        color: color,
        clipBehavior: Clip.antiAlias,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: content,
              )
            : content,
      ),
    );
  }
}

/// A brand-coloured "hero" card variant — used for the dashboard earnings
/// tile and other headline stat callouts (gradient primary background,
/// white text).
class AppHeroCard extends StatelessWidget {
  const AppHeroCard({
    required this.child,
    super.key,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: child,
    );
  }
}
