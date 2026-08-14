import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/config/route_constants.dart';
import '../../../../core/theme/theme.dart';
import '../widgets/pin_dot_indicator.dart';
import '../widgets/pin_keypad.dart';

/// Recreated pixel-for-pixel from the Figma `PINScreen`: gradient header
/// with the salon name, a lock icon + "Enter your PIN" prompt, a 4-dot
/// progress indicator, and a 3x4 numeric keypad. UI-only — any 4-digit PIN
/// unlocks the app.
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final List<int> _digits = <int>[];

  void _pressDigit(int digit) {
    if (_digits.length >= AppConstants.pinLength) return;
    setState(() => _digits.add(digit));
    if (_digits.length == AppConstants.pinLength) {
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) context.goNamed(RouteConstants.rootName);
      });
    }
  }

  void _pressDelete() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _Header(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.lock_outline, color: AppColors.primary),
                    SizedBox(height: AppSpacing.md),
                    Text('Enter your PIN', style: AppTypography.label(const Color(0xFF6B4848))),
                    SizedBox(height: AppSpacing.xxl),
                    PinDotIndicator(filledCount: _digits.length),
                    SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                    PinKeypad(
                      onDigitPressed: _pressDigit,
                      onDeletePressed: _pressDelete,
                      showBiometric: true,
                      onBiometricPressed: () => context.goNamed(RouteConstants.rootName),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    Text(
                      'Forgot PIN? Use biometrics or reinstall to reset.',
                      style: AppTypography.caption(AppColors.mutedForeground),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        children: <Widget>[
          Container(
            width: 64.r,
            height: 64.r,
            margin: EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            ),
            child: Icon(Icons.content_cut, size: AppDimensions.iconXl, color: Colors.white),
          ),
          Text('Blossom Beauty Studio', style: AppTypography.h3(Colors.white)),
          SizedBox(height: AppSpacing.xxs),
          Text('Welcome back 👋', style: AppTypography.bodySmall(Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}
