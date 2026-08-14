import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/theme.dart';

/// 3x4 numeric keypad — digits 1-9, a biometric shortcut in the bottom-left
/// slot, 0 bottom-middle, and a delete key bottom-right. Matches the
/// Figma PIN screen layout exactly.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigitPressed,
    required this.onDeletePressed,
    super.key,
    this.onBiometricPressed,
    this.showBiometric = false,
  });

  final ValueChanged<int> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onBiometricPressed;
  final bool showBiometric;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 288.w,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.5,
        children: <Widget>[
          for (int digit = 1; digit <= 9; digit++)
            _KeypadButton(label: '$digit', onTap: () => onDigitPressed(digit)),
          if (showBiometric)
            _KeypadIconButton(icon: Icons.fingerprint, onTap: onBiometricPressed)
          else
            const SizedBox.shrink(),
          _KeypadButton(label: '0', onTap: () => onDigitPressed(0)),
          _KeypadIconButton(icon: Icons.backspace_outlined, onTap: onDeletePressed),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        onTap: onTap,
        splashColor: AppColors.secondary,
        child: Center(
          child: Text(
            label,
            style: AppTypography.h2(AppColors.foreground),
          ),
        ),
      ),
    );
  }
}

class _KeypadIconButton extends StatelessWidget {
  const _KeypadIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        onTap: onTap,
        child: Center(
          child: Icon(icon, size: AppDimensions.iconLg, color: AppColors.primary),
        ),
      ),
    );
  }
}
