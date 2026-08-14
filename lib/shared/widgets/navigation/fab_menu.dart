import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/theme/theme.dart';

class FabMenuItem {
  const FabMenuItem({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Full-screen scrim + floating quick-action card, opened from the
/// dashboard/shell FAB. Matches the Figma `FABMenu`: a blurred backdrop
/// and a rounded card of 4 quick actions (New Appointment, Add Customer,
/// New Expense, Generate Invoice).
class FabMenu extends StatelessWidget {
  const FabMenu({required this.items, required this.onClose, super.key});

  final List<FabMenuItem> items;
  final VoidCallback onClose;

  static Future<void> show(BuildContext context, {required List<FabMenuItem> items}) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Quick actions',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: AppConstants.animationFast,
      pageBuilder: (BuildContext context, _, __) {
        return FabMenu(items: items, onClose: () => Navigator.of(context).pop());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 110.h),
            child: GestureDetector(
              onTap: () {},
              child: SizedBox(
                width: 256.w,
                child: Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  clipBehavior: Clip.antiAlias,
                  elevation: AppDimensions.elevationModal,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = 0; i < items.length; i++)
                        InkWell(
                          onTap: () {
                            items[i].onTap();
                            onClose();
                          },
                          child: Container(
                            padding: EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              border: i < items.length - 1
                                  ? const Border(bottom: BorderSide(color: AppColors.border))
                                  : null,
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 36.r,
                                  height: 36.r,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                  ),
                                  child: Icon(items[i].icon, size: AppDimensions.iconMd, color: AppColors.primary),
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Text(items[i].label, style: AppTypography.label(AppColors.foreground)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
