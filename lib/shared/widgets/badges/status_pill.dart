import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/enums/app_status.dart';
import '../../../core/theme/theme.dart';

export '../../../core/enums/app_status.dart';

/// Small rounded status chip used on appointment cards, bills and package
/// entries. Colours mirror the Figma `StatusPill` mapping exactly
/// (blue/amber/green/red tints).
class StatusPill extends StatelessWidget {
  const StatusPill({required this.status, super.key});

  final AppStatus status;

  ({Color bg, Color fg, Color border, String label}) get _style {
    switch (status) {
      case AppStatus.confirmed:
        return (
          bg: const Color(0xFFEFF6FF),
          fg: const Color(0xFF2563EB),
          border: const Color(0xFFDBEAFE),
          label: 'Confirmed',
        );
      case AppStatus.pending:
        return (
          bg: const Color(0xFFFFFBEB),
          fg: const Color(0xFFD97706),
          border: const Color(0xFFFDE68A),
          label: 'Pending',
        );
      case AppStatus.completed:
        return (
          bg: const Color(0xFFF0FFF4),
          fg: const Color(0xFF16A34A),
          border: const Color(0xFFBBF7D0),
          label: 'Completed',
        );
      case AppStatus.cancelled:
        return (
          bg: const Color(0xFFFEF2F2),
          fg: const Color(0xFFEF4444),
          border: const Color(0xFFFECACA),
          label: 'Cancelled',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2.h),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: style.border),
      ),
      child: Text(
        style.label,
        style: AppTypography.caption(style.fg).copyWith(fontSize: 10.sp, fontWeight: AppTypography.semiBold),
      ),
    );
  }
}
