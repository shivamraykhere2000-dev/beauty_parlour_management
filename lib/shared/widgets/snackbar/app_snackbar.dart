import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

enum AppSnackBarType { info, success, error }

/// Consistent snackbar presentation across the app — success (green),
/// error (destructive red) and neutral info variants.
abstract class AppSnackBar {
  const AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    final Color background = switch (type) {
      AppSnackBarType.success => AppColors.success,
      AppSnackBarType.error => AppColors.destructive,
      AppSnackBarType.info => AppColors.foreground,
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppTypography.bodyMedium(Colors.white)),
          backgroundColor: background,
        ),
      );
  }
}
