import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme.dart';

class BottomNavTab {
  const BottomNavTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Five-tab bottom navigation bar — Home, Appointments, Clients (with a
/// notch reserved for the floating FAB), Reports, Settings. Matches the
/// Figma `BottomNav` exactly, including the active-tab pill background and
/// the small indicator line above the selected label.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<BottomNavTab> tabs = <BottomNavTab>[
    BottomNavTab(label: 'Home', icon: Icons.home_outlined),
    BottomNavTab(label: 'Appts', icon: Icons.calendar_today_outlined),
    BottomNavTab(label: 'Clients', icon: Icons.people_outline),
    BottomNavTab(label: 'Reports', icon: Icons.bar_chart_outlined),
    BottomNavTab(label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List<Widget>.generate(tabs.length, (int index) {
            final bool isCenterGap = index == 2;
            final bool isActive = currentIndex == index;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (isActive)
                      Container(
                        width: 16.w,
                        height: 2.h,
                        margin: EdgeInsets.only(bottom: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        ),
                      )
                    else
                      SizedBox(height: 2.h + 2.h),
                    if (isCenterGap)
                      SizedBox(height: 32.h)
                    else
                      Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.secondary : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                        child: Icon(
                          tabs[index].icon,
                          size: AppDimensions.iconMd,
                          color: isActive ? AppColors.primary : AppColors.mutedForeground,
                        ),
                      ),
                    SizedBox(height: 2.h),
                    Text(
                      tabs[index].label,
                      style: AppTypography.caption(
                        isActive ? AppColors.primary : AppColors.mutedForeground,
                      ).copyWith(fontSize: 9.sp, fontWeight: AppTypography.bold),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
