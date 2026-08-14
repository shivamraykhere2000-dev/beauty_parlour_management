import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme.dart';

/// Standard loading indicator — used for full-screen loading states and
/// inline loading placeholders. Keeps a single visual language for "app is
/// busy" across every screen.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.message,
    this.size = 32,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: size.r,
            height: size.r,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          if (message != null) ...<Widget>[
            SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              style: AppTypography.bodySmall(AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen variant, for route-level loading (e.g. while the database
/// initialises on cold start).
class FullScreenLoading extends StatelessWidget {
  const FullScreenLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingWidget(message: message),
    );
  }
}
