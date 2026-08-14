import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme.dart';

enum AppAvatarSize { sm, md, lg, xl }

/// Initials avatar used for customers throughout the app (Dashboard
/// birthday list, Customers list, Customer Detail header, ...). Mirrors
/// the Figma `Av` component: a gradient circle picked deterministically
/// from the first letter of the initials, with the initials centered in
/// white bold text.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.initials,
    super.key,
    this.size = AppAvatarSize.md,
  });

  final String initials;
  final AppAvatarSize size;

  static const List<List<Color>> _gradients = <List<Color>>[
    <Color>[AppColors.primary, AppColors.accent],
    <Color>[Color(0xFF7B68EE), Color(0xFF9B88FF)],
    <Color>[Color(0xFF48B09B), Color(0xFF60C5B0)],
    <Color>[Color(0xFFE8956D), Color(0xFFF0A880)],
    <Color>[Color(0xFFC06090), Color(0xFFD080A8)],
  ];

  double get _diameter {
    switch (size) {
      case AppAvatarSize.sm:
        return AppDimensions.avatarSm;
      case AppAvatarSize.md:
        return AppDimensions.avatarMd;
      case AppAvatarSize.lg:
        return AppDimensions.avatarLg;
      case AppAvatarSize.xl:
        return AppDimensions.avatarXl;
    }
  }

  TextStyle get _textStyle {
    final double fontSize = switch (size) {
      AppAvatarSize.sm => 10.sp,
      AppAvatarSize.md => 13.sp,
      AppAvatarSize.lg => 18.sp,
      AppAvatarSize.xl => 28.sp,
    };
    return AppTypography.button(Colors.white).copyWith(fontSize: fontSize);
  }

  @override
  Widget build(BuildContext context) {
    final String safeInitials = initials.isEmpty ? '?' : initials;
    final List<Color> gradient =
        _gradients[safeInitials.codeUnitAt(0) % _gradients.length];

    return Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      alignment: Alignment.center,
      child: Text(safeInitials, style: _textStyle),
    );
  }
}
