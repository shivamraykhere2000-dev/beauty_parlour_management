import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/config/route_constants.dart';
import '../../../../core/database/daos/settings_dao.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';

/// First screen shown on cold start. Recreated pixel-for-pixel from the
/// Figma `SplashScreen`: gradient background with faint concentric rings,
/// a frosted logo badge, the "Blossom" wordmark in Playfair Display, and
/// three pulsing dots at the bottom.
///
/// After ~2.8s it checks whether the owner has completed first-run setup
/// (`Settings.app_initialized`, see `OwnerSetupScreen`): if not, it routes
/// to Owner Setup; if already initialized, it goes straight to the
/// Dashboard — the old PIN-lock step is no longer shown on normal launch.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
        AppConstants.splashDuration + const Duration(milliseconds: 800),
        _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;
    final SettingsDao db = ref.read(settingsDaoProvider);
    final bool initialized = await db.isAppInitialized();
    if (!mounted) return;
    if (initialized) {
      context.goNamed(RouteConstants.rootName);
    } else {
      context.goNamed(RouteConstants.ownerSetupName);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Faint concentric rings, matching the Figma decoration.
            for (int i = 1; i <= 6; i++)
              Opacity(
                opacity: 0.10,
                child: Container(
                  width: (i * 80).w,
                  height: (i * 80).w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white),
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 96.r,
                  height: 96.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXl + 8),
                  ),
                  child: Icon(Icons.content_cut,
                      size: AppDimensions.iconXl + 16, color: Colors.white),
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  AppConstants.appName,
                  style: AppTypography.heroNumber(Colors.white)
                      .copyWith(letterSpacing: 1),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'BEAUTY STUDIO',
                  style: AppTypography.caption(
                          Colors.white.withValues(alpha: 0.75))
                      .copyWith(letterSpacing: 4),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'PREMIUM SALON MANAGEMENT',
                  style:
                      AppTypography.caption(Colors.white.withValues(alpha: 0.5))
                          .copyWith(letterSpacing: 3),
                ),
              ],
            ),
            Positioned(
              bottom: 64.h,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(3, (int index) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppSpacing.xxs / 2),
                    child:
                        _PulsingDot(delay: Duration(milliseconds: index * 150)),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.delay});

  final Duration delay;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.9).animate(_controller),
      child: Container(
        width: 8.r,
        height: 8.r,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}
