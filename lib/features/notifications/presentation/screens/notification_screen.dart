import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/notifications/notification_types.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({
    super.key,
    this.onQuickAction,
  });

  final ValueChanged<String>? onQuickAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> notificationsAsync =
        ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _NotificationHeader(
              notificationsAsync: notificationsAsync,
              onClearAll: () => _confirmClearAll(context, ref),
            ),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const LoadingWidget(),
                error: (Object error, StackTrace stackTrace) =>
                    AppErrorWidget(message: '$error'),
                data: (List<AppNotification> notifications) {
                  if (notifications.isEmpty) {
                    return const EmptyWidget(
                      icon: Icons.notifications_none,
                      title: 'No notifications',
                      message: "You're all caught up.",
                    );
                  }

                  return _NotificationList(
                    notifications: notifications,
                    onQuickAction: onQuickAction,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: 'Clear All Notifications?',
      message:
          'This will permanently remove every notification. This cannot be undone.',
      confirmLabel: 'Clear All',
      isDestructive: true,
    );

    if (!confirmed) {
      return;
    }

    await ref.read(appNotificationsDaoProvider).clearAllNotifications();
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader({
    required this.notificationsAsync,
    required this.onClearAll,
  });

  final AsyncValue<List<AppNotification>> notificationsAsync;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final bool hasNotifications = notificationsAsync.maybeWhen(
      data: (List<AppNotification> notifications) => notifications.isNotEmpty,
      orElse: () => false,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8.w,
        8.h,
        8.w,
        12.h,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24.r),
        ),
      ),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50.r),
            child: Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16.r,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Notifications',
              style: AppTypography.h2(Colors.white).copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (hasNotifications)
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 5.h,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Clear all',
                style: AppTypography.caption(
                  Colors.white,
                ).copyWith(
                  fontSize: 11.sp,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.notifications,
    this.onQuickAction,
  });

  final List<AppNotification> notifications;
  final ValueChanged<String>? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final List<AppNotification> birthdays = notifications
        .where(
          (AppNotification notification) =>
              notification.type == NotificationType.birthday,
        )
        .toList();

    final List<AppNotification> followUps = notifications
        .where(
          (AppNotification notification) =>
              notification.type == NotificationType.followUp,
        )
        .toList();

    final List<AppNotification> appointments = notifications
        .where(
          (AppNotification notification) =>
              notification.type == NotificationType.appointment,
        )
        .toList();

    final List<AppNotification> lowStock = notifications
        .where(
          (AppNotification notification) =>
              notification.type == NotificationType.lowStock,
        )
        .toList();

    final List<AppNotification> other = notifications
        .where(
          (AppNotification notification) =>
              notification.type != NotificationType.birthday &&
              notification.type != NotificationType.followUp &&
              notification.type != NotificationType.appointment &&
              notification.type != NotificationType.lowStock,
        )
        .toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        6.w,
        14.h,
        6.w,
        32.h,
      ),
      children: <Widget>[
        if (birthdays.isNotEmpty) ...<Widget>[
          const _SectionTitle(
            emoji: '🎂',
            title: 'Birthdays Today',
          ),
          SizedBox(height: 8.h),
          for (final AppNotification notification in birthdays)
            _BirthdayNotificationCard(
              notification: notification,
            ),
          SizedBox(height: 10.h),
        ],
        if (followUps.isNotEmpty) ...<Widget>[
          const _SectionTitle(
            emoji: '💬',
            title: 'Customer Follow-up',
          ),
          SizedBox(height: 8.h),
          for (final AppNotification notification in followUps)
            _FollowUpNotificationCard(
              notification: notification,
            ),
          SizedBox(height: 10.h),
        ],
        if (appointments.isNotEmpty) ...<Widget>[
          const _SectionTitle(
            emoji: '🗓️',
            title: 'Upcoming Appointments',
          ),
          SizedBox(height: 8.h),
          for (final AppNotification notification in appointments)
            _AppointmentNotificationCard(
              notification: notification,
              onView: () {
                onQuickAction?.call('Appointments');

                if (onQuickAction == null) {
                  Navigator.pop(context);
                }
              },
            ),
          SizedBox(height: 10.h),
        ],
        if (lowStock.isNotEmpty) ...<Widget>[
          const _SectionTitle(
            emoji: '⚠️',
            title: 'Low Stock',
          ),
          SizedBox(height: 8.h),
          for (final AppNotification notification in lowStock)
            _LowStockNotificationCard(
              notification: notification,
              onOrder: () {
                onQuickAction?.call('Inventory');

                if (onQuickAction == null) {
                  Navigator.pop(context);
                }
              },
            ),
          SizedBox(height: 10.h),
        ],
        if (other.isNotEmpty) ...<Widget>[
          const _SectionTitle(
            emoji: '🔔',
            title: 'Other',
          ),
          SizedBox(height: 8.h),
          for (final AppNotification notification in other)
            _GenericNotificationCard(
              notification: notification,
            ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.emoji,
    required this.title,
  });

  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 2.w,
        bottom: 2.h,
      ),
      child: Row(
        children: <Widget>[
          Text(
            emoji,
            style: TextStyle(fontSize: 13.sp),
          ),
          SizedBox(width: 6.w),
          Text(
            title,
            style: AppTypography.label(
              AppColors.foreground,
            ).copyWith(
              fontSize: 13.sp,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayNotificationCard extends ConsumerWidget {
  const _BirthdayNotificationCard({
    required this.notification,
  });

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _NotificationCard(
      notification: notification,
      child: Row(
        children: <Widget>[
          _NotificationIcon(
            icon: Icons.cake_outlined,
            color: AppColors.primary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _NotificationTitle(
                  notification: notification,
                ),
                SizedBox(height: 3.h),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    AppColors.mutedForeground,
                  ).copyWith(fontSize: 10.5.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (notification.isActionCompleted)
            const _CompletedLabel()
          else
            _NotificationActionButton(
              label: 'Wish',
              onPressed: () => _sendBirthdayWish(
                context,
                ref,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sendBirthdayWish(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final List<Customer> customers = ref.read(customersProvider).maybeWhen(
          data: (List<Customer> list) => list,
          orElse: () => const <Customer>[],
        );

    Customer? customer;

    if (notification.customerId != null) {
      customer = customers.firstWhereOrNull(
        (Customer item) => item.id == notification.customerId,
      );
    }

    customer ??= customers.firstWhereOrNull(
      (Customer item) =>
          item.name.trim().toLowerCase() ==
          notification.title.trim().toLowerCase(),
    );

    if (customer == null) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: 'Customer "${notification.title}" was not found.',
          type: AppSnackBarType.error,
        );
      }
      return;
    }

    final List<WhatsappTemplate> templates =
        ref.read(whatsappTemplatesProvider).maybeWhen(
              data: (List<WhatsappTemplate> list) => list,
              orElse: () => const <WhatsappTemplate>[],
            );

    final WhatsappTemplate? template = templates
        .where(
          (WhatsappTemplate item) => item.type == 'Birthday Wishes',
        )
        .firstOrNull;

    final String message = (template?.body ??
            'Happy Birthday {{name}}! 🎉🌸 Enjoy 20% OFF your next visit this week.')
        .replaceAll(
      '{{name}}',
      customer.name,
    );

    final String digits = customer.phone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.isEmpty) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: '${customer.name} has no phone number saved.',
          type: AppSnackBarType.error,
        );
      }
      return;
    }

    final String withCountryCode = digits.length == 10 ? '91$digits' : digits;

    final Uri uri = Uri.parse(
      'https://wa.me/$withCountryCode'
      '?text=${Uri.encodeComponent(message)}',
    );

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: 'Could not open WhatsApp.',
          type: AppSnackBarType.error,
        );
      }
      return;
    }

    await ref
        .read(appNotificationsDaoProvider)
        .markActionCompleted(notification.id);
  }
}

class _FollowUpNotificationCard extends ConsumerWidget {
  const _FollowUpNotificationCard({
    required this.notification,
  });

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _NotificationCard(
      notification: notification,
      child: Row(
        children: <Widget>[
          _NotificationIcon(
            icon: Icons.person_search_outlined,
            color: AppColors.accent,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _NotificationTitle(
                  notification: notification,
                ),
                SizedBox(height: 3.h),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    AppColors.mutedForeground,
                  ).copyWith(fontSize: 10.5.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (notification.isActionCompleted)
            const _CompletedLabel()
          else
            _NotificationActionButton(
              label: 'Message',
              onPressed: () => _sendFollowUpMessage(
                context,
                ref,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sendFollowUpMessage(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final List<Customer> customers = ref.read(customersProvider).maybeWhen(
          data: (List<Customer> list) => list,
          orElse: () => const <Customer>[],
        );

    Customer? customer;

    if (notification.customerId != null) {
      customer = customers.firstWhereOrNull(
        (Customer item) => item.id == notification.customerId,
      );
    }

    if (customer == null) {
      return;
    }

    final List<WhatsappTemplate> templates =
        ref.read(whatsappTemplatesProvider).maybeWhen(
              data: (List<WhatsappTemplate> list) => list,
              orElse: () => const <WhatsappTemplate>[],
            );

    final WhatsappTemplate? template = templates
        .where(
          (WhatsappTemplate item) => item.type == 'Follow Up',
        )
        .firstOrNull;

    final String message = (template?.body ??
            'Hi {{name}}! 🌸 We haven\'t seen you for a while. We would love to welcome you back. 😊')
        .replaceAll(
      '{{name}}',
      customer.name,
    );

    final String digits = customer.phone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.isEmpty) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: '${customer.name} has no phone number saved.',
          type: AppSnackBarType.error,
        );
      }
      return;
    }

    final String phone = digits.length == 10 ? '91$digits' : digits;

    final Uri uri = Uri.parse(
      'https://wa.me/$phone'
      '?text=${Uri.encodeComponent(message)}',
    );

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: 'Could not open WhatsApp.',
          type: AppSnackBarType.error,
        );
      }
      return;
    }

    await ref
        .read(appNotificationsDaoProvider)
        .markActionCompleted(notification.id);
  }
}

class _AppointmentNotificationCard extends StatelessWidget {
  const _AppointmentNotificationCard({
    required this.notification,
    required this.onView,
  });

  final AppNotification notification;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return _NotificationCard(
      notification: notification,
      child: Row(
        children: <Widget>[
          _NotificationIcon(
            icon: Icons.calendar_today_outlined,
            color: AppColors.accent,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _NotificationTitle(
                  notification: notification,
                ),
                SizedBox(height: 3.h),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    AppColors.mutedForeground,
                  ).copyWith(fontSize: 10.5.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _NotificationActionButton(
            label: 'View',
            onPressed: onView,
          ),
        ],
      ),
    );
  }
}

class _LowStockNotificationCard extends StatelessWidget {
  const _LowStockNotificationCard({
    required this.notification,
    required this.onOrder,
  });

  final AppNotification notification;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return _NotificationCard(
      notification: notification,
      child: Row(
        children: <Widget>[
          _NotificationIcon(
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFF59E0B),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _NotificationTitle(
                  notification: notification,
                ),
                SizedBox(height: 3.h),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    AppColors.mutedForeground,
                  ).copyWith(fontSize: 10.5.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _NotificationActionButton(
            label: 'Order',
            onPressed: onOrder,
          ),
        ],
      ),
    );
  }
}

class _GenericNotificationCard extends StatelessWidget {
  const _GenericNotificationCard({
    required this.notification,
  });

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return _NotificationCard(
      notification: notification,
      child: Row(
        children: <Widget>[
          _NotificationIcon(
            icon: Icons.notifications_none,
            color: AppColors.primary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _NotificationTitle(
                  notification: notification,
                ),
                SizedBox(height: 3.h),
                Text(
                  notification.body,
                  style: AppTypography.caption(
                    AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({
    required this.notification,
    required this.child,
  });

  final AppNotification notification;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: notification.isRead
          ? null
          : () async {
              await ref
                  .read(appNotificationsDaoProvider)
                  .markNotificationRead(notification.id);
            },
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(
          horizontal: 15.w,
          vertical: 13.h,
        ),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFFFF9FB),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: notification.isRead
                ? const Color(0xFFE8E0E3)
                : AppColors.primary.withValues(alpha: 0.30),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: child),
            if (!notification.isRead) ...<Widget>[
              SizedBox(width: 5.w),
              Container(
                width: 8.r,
                height: 8.r,
                margin: EdgeInsets.only(top: 3.h),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationTitle extends StatelessWidget {
  const _NotificationTitle({
    required this.notification,
  });

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Text(
      notification.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.label(
        AppColors.foreground,
      ).copyWith(
        fontSize: 13.sp,
        fontWeight:
            notification.isRead ? AppTypography.medium : AppTypography.bold,
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18.r,
        color: color,
      ),
    );
  }
}

class _CompletedLabel extends StatelessWidget {
  const _CompletedLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 9.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusPill,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.check_circle_outline,
            size: 13.r,
            color: AppColors.success,
          ),
          SizedBox(width: 3.w),
          Text(
            'Sent',
            style: AppTypography.caption(
              AppColors.success,
            ).copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(
        AppDimensions.radiusPill,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 7.h,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusPill,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption(
            Colors.white,
          ).copyWith(
            fontSize: 10.5.sp,
            fontWeight: AppTypography.bold,
          ),
        ),
      ),
    );
  }
}
