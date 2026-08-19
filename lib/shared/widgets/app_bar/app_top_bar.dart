import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// The app's standard top bar: primary-coloured background, a Playfair
/// Display title, an optional back button and an optional trailing action
/// widget — mirrors the `AppBar` component used on every inner screen in
/// the Figma design (Customers, Appointments, Billing, Services, ...).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    required this.title,
    super.key,
    this.onBack,
    this.trailing,
    this.showBackButton = true,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: showBackButton ? 0 : AppSpacing.md,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(
        title,
        style: AppTypography.h3(AppColors.primaryForeground),
      ),
      actions: trailing != null ? <Widget>[trailing!, SizedBox(width: AppSpacing.xs)] : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppDimensions.appBarHeight);
}
