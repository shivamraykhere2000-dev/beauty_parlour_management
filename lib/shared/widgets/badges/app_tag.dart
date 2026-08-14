import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme.dart';

/// Small customer-attribute chip (VIP, Regular, Member, New, Active, ...).
/// Colour is looked up by label to match the Figma `Tag` component;
/// unrecognised labels fall back to a neutral grey chip.
class AppTag extends StatelessWidget {
  const AppTag({required this.label, super.key});

  final String label;

  static const Map<String, ({Color bg, Color fg, Color border})> _styles =
      <String, ({Color bg, Color fg, Color border})>{
    'VIP': (bg: Color(0xFFFFF0F4), fg: AppColors.primary, border: Color(0xFFF0CEDE)),
    'Regular': (bg: Color(0xFFEFF6FF), fg: Color(0xFF2563EB), border: Color(0xFFDBEAFE)),
    'Member': (bg: Color(0xFFFFFBEB), fg: Color(0xFFD97706), border: Color(0xFFFDE68A)),
    'New': (bg: Color(0xFFF0FFF4), fg: Color(0xFF16A34A), border: Color(0xFFBBF7D0)),
    'Active': (bg: Color(0xFFF5F0FF), fg: Color(0xFF9333EA), border: Color(0xFFE9D5FF)),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[label] ??
        (bg: AppColors.muted, fg: AppColors.mutedForeground, border: AppColors.border);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2.h),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: style.border),
      ),
      child: Text(
        label,
        style: AppTypography.caption(style.fg).copyWith(fontSize: 10.sp, fontWeight: AppTypography.semiBold),
      ),
    );
  }
}
