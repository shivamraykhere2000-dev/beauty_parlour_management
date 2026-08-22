import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

AppStatus statusFromString(String s) {
  switch (s) {
    case 'completed':
      return AppStatus.completed;
    case 'pending':
      return AppStatus.pending;
    case 'cancelled':
      return AppStatus.cancelled;
    default:
      return AppStatus.confirmed;
  }
}

/// Home tab — recreated pixel-for-pixel from the Figma `DashboardScreen`,
/// now fully live: every number, list and alert is streamed straight from
/// the Drift database and updates in real time as bills are collected,
/// customers added or stock adjusted.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.onQuickAction});

  final ValueChanged<String>? onQuickAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final String todayMonthDay = today.substring(5); // MM-DD

    final AsyncValue<List<Appointment>> apptsAsync =
        ref.watch(appointmentsForDateProvider(today));
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);
    final AsyncValue<List<InventoryItem>> inventoryAsync =
        ref.watch(inventoryProvider);

    // Idempotent housekeeping: purge notifications older than 15 days,
    // and ensure today's birthday/low-stock notifications exist.
    ref.watch(notificationsPurgeProvider);
    ref.watch(autoNotificationsSyncProvider);

    final String ownerName = ref.watch(settingsProvider).maybeWhen(
              data: (Map<String, String> m) => m['first_name'],
              orElse: () => null,
            ) ??
        'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: apptsAsync.when(
        loading: () => const LoadingWidget(),
        error: (Object e, _) => AppErrorWidget(message: '$e'),
        data: (List<Appointment> appts) {
          return customersAsync.when(
            loading: () => const LoadingWidget(),
            error: (Object e, _) => AppErrorWidget(message: '$e'),
            data: (List<Customer> customers) {
              return inventoryAsync.when(
                loading: () => const LoadingWidget(),
                error: (Object e, _) => AppErrorWidget(message: '$e'),
                data: (List<InventoryItem> inventory) {
                  final int completed = appts
                      .where((Appointment a) => a.status == 'completed')
                      .length;
                  final int earned = appts
                      .where((Appointment a) => a.status == 'completed')
                      .fold<int>(0, (int s, Appointment a) => s + a.amount);
                  final List<Customer> birthdays = customers
                      .where((Customer c) =>
                          (c.birthday ?? '').endsWith(todayMonthDay))
                      .toList();
                  final List<InventoryItem> lowStock = inventory
                      .where((InventoryItem i) => i.stock <= i.minStock)
                      .toList();

                  return Column(
                    children: <Widget>[
                      _Header(
                          earned: earned,
                          completed: completed,
                          total: appts.length,
                          ownerName: ownerName),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(AppSpacing.md,
                              AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                    child: _StatTile(
                                        label: 'Today',
                                        value: '${appts.length}',
                                        icon: Icons.calendar_today,
                                        color: AppColors.primary)),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                    child: _StatTile(
                                        label: 'Done',
                                        value: '$completed',
                                        icon: Icons.check,
                                        color: AppColors.success)),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                    child: _StatTile(
                                        label: 'Birthdays',
                                        value: '${birthdays.length}',
                                        icon: Icons.card_giftcard,
                                        color: AppColors.accent)),
                              ],
                            ),
                            SizedBox(height: AppSpacing.md),
                            _MonthlyRevenueCard(earned: earned),
                            if (birthdays.isNotEmpty) ...<Widget>[
                              SizedBox(height: AppSpacing.md),
                              _BirthdaysCard(
                                  birthdays: birthdays,
                                  onWish: (Customer c) =>
                                      sendBirthdayWish(context, ref, c)),
                            ],
                            SizedBox(height: AppSpacing.md),
                            _SectionHeader(
                                title: "Today's Schedule",
                                actionLabel: 'View All',
                                onAction: () =>
                                    onQuickAction?.call('Appointments')),
                            SizedBox(height: AppSpacing.sm),
                            if (appts.isEmpty)
                              const EmptyWidget(
                                  icon: Icons.event_available_outlined,
                                  title: 'No appointments today',
                                  message: 'Tap "New Appt" below to book one.')
                            else
                              for (final Appointment apt in appts) ...<Widget>[
                                _ScheduleCard(appointment: apt),
                                SizedBox(height: AppSpacing.sm),
                              ],
                            if (lowStock.isNotEmpty) ...<Widget>[
                              SizedBox(height: AppSpacing.xs),
                              _LowStockCard(
                                  items: lowStock,
                                  onViewAll: () =>
                                      onQuickAction?.call('Inventory')),
                            ],
                            SizedBox(height: AppSpacing.md),
                            Text('Quick Actions',
                                style: AppTypography.h3(AppColors.foreground)
                                    .copyWith(fontSize: 14.sp)),
                            SizedBox(height: AppSpacing.sm),
                            _QuickActionsGrid(onTap: onQuickAction),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.earned,
      required this.completed,
      required this.total,
      required this.ownerName});

  final int earned;
  final int completed;
  final int total;
  final String ownerName;

  String get _greeting {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final String dateLabel = _formatToday();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.lg),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(dateLabel.toUpperCase(),
                        style: AppTypography.caption(
                                Colors.white.withValues(alpha: 0.65))
                            .copyWith(letterSpacing: 1.5, fontSize: 10.sp)),
                    SizedBox(height: 2.h),
                    Text('$_greeting, $ownerName ✨',
                        style: AppTypography.h2(Colors.white)),
                  ],
                ),
              ),
              Builder(
                builder: (BuildContext context) => _CircleIconButton(
                  icon: Icons.notifications_outlined,
                  showDot: true,
                  onTap: () => showNotificationsSheet(context),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("TODAY'S REVENUE",
                    style: AppTypography.caption(
                            Colors.white.withValues(alpha: 0.65))
                        .copyWith(letterSpacing: 1.5, fontSize: 10.sp)),
                Text('₹$earned', style: AppTypography.heroNumber(Colors.white)),
                SizedBox(height: 2.h),
                Text('$completed of $total appointments completed',
                    style: AppTypography.caption(
                        Colors.white.withValues(alpha: 0.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatToday() {
    const List<String> weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final DateTime now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton(
      {required this.icon, required this.onTap, this.showDot = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      child: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Icon(icon, size: AppDimensions.iconMd, color: Colors.white),
            if (showDot)
              Positioned(
                top: 9.r,
                right: 9.r,
                child: Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF87171),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            child: Icon(icon, size: AppDimensions.iconSm, color: Colors.white),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(value,
              style: AppTypography.h2(AppColors.foreground)
                  .copyWith(fontSize: 20.sp)),
          Text(label, style: AppTypography.caption(AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _MonthlyRevenueCard extends StatelessWidget {
  const _MonthlyRevenueCard({required this.earned});

  final int earned;

  @override
  Widget build(BuildContext context) {
    const int target = 68000;
    final double progress = (earned / target).clamp(0, 1).toDouble();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Monthly Target Progress',
                  style: AppTypography.label(AppColors.foreground)
                      .copyWith(fontWeight: AppTypography.bold)),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              backgroundColor: const Color(0xFFF0E8EC),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 6.h),
          Text('₹$earned of ₹$target target (${(progress * 100).round()}%)',
              style: AppTypography.caption(AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _BirthdaysCard extends StatelessWidget {
  const _BirthdaysCard({required this.birthdays, required this.onWish});

  final List<Customer> birthdays;
  final ValueChanged<Customer> onWish;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFFF5F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.card_giftcard,
                  size: 16, color: AppColors.primary),
              SizedBox(width: AppSpacing.xxs),
              Text("Today's Birthdays 🎂",
                  style: AppTypography.label(AppColors.primary)
                      .copyWith(fontWeight: AppTypography.bold)),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          for (final Customer c in birthdays)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Row(
                children: <Widget>[
                  AppAvatar(initials: c.avatarInitials, size: AppAvatarSize.sm),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(c.name,
                            style: AppTypography.label(AppColors.foreground)
                                .copyWith(fontSize: 13.sp)),
                        Text(c.phone,
                            style: AppTypography.caption(
                                AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => onWish(c),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      minimumSize: Size.zero,
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 6.h),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusPill)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 14),
                    label: Text('Wish',
                        style: AppTypography.caption(Colors.white)
                            .copyWith(fontWeight: AppTypography.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
              width: 4.w,
              height: 48.h,
              decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(4))),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                        child: Text(appointment.customerName,
                            style: AppTypography.label(AppColors.foreground)
                                .copyWith(
                                    fontWeight: AppTypography.bold,
                                    fontSize: 13.sp),
                            overflow: TextOverflow.ellipsis)),
                    StatusPill(status: statusFromString(appointment.status)),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(appointment.services.replaceAll(',', ', '),
                    style: AppTypography.caption(const Color(0xFF6B4848))),
                SizedBox(height: 2.h),
                Text(
                    '${appointment.time} · ${appointment.durationMinutes} min · ₹${appointment.amount}',
                    style: AppTypography.caption(AppColors.mutedForeground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.items, required this.onViewAll});

  final List<InventoryItem> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFFFBEB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: AppSpacing.xxs),
                  Text('Low Stock Alert',
                      style: AppTypography.label(const Color(0xFFB45309))
                          .copyWith(fontWeight: AppTypography.bold)),
                ],
              ),
              GestureDetector(
                  onTap: onViewAll,
                  child: Text('View All',
                      style: AppTypography.caption(const Color(0xFFD97706))
                          .copyWith(fontWeight: AppTypography.bold))),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          for (final InventoryItem item in items.take(3))
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: Text(item.name,
                          style: AppTypography.caption(const Color(0xFF92400E)),
                          overflow: TextOverflow.ellipsis)),
                  Text('${item.stock}/${item.minStock}',
                      style: AppTypography.caption(const Color(0xFFD97706))
                          .copyWith(fontWeight: AppTypography.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(title,
            style: AppTypography.h3(AppColors.foreground)
                .copyWith(fontSize: 14.sp)),
        if (actionLabel != null)
          GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!,
                  style: AppTypography.caption(AppColors.primary)
                      .copyWith(fontWeight: AppTypography.bold))),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({this.onTap});

  final ValueChanged<String>? onTap;

  static const List<({String label, IconData icon})> _actions =
      <({String label, IconData icon})>[
    (label: 'New Appt', icon: Icons.calendar_today_outlined),
    (label: 'Add Client', icon: Icons.person_add_alt_outlined),
    (label: 'Billing', icon: Icons.credit_card_outlined),
    (label: 'Inventory', icon: Icons.shopping_bag_outlined),
    (label: 'Expenses', icon: Icons.account_balance_wallet_outlined),
    (label: 'Reports', icon: Icons.bar_chart_outlined),
    (label: 'WhatsApp', icon: Icons.chat_bubble_outline),
    (label: 'Services', icon: Icons.content_cut_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.85),
      itemBuilder: (BuildContext context, int index) {
        final action = _actions[index];
        return InkWell(
          onTap: () => onTap?.call(action.label),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.border)),
            padding: EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F4),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd)),
                  child: Icon(action.icon,
                      size: AppDimensions.iconSm, color: AppColors.primary),
                ),
                SizedBox(height: 6.h),
                Text(action.label,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption(const Color(0xFF6B4848))
                        .copyWith(
                            fontSize: 9.5.sp, fontWeight: AppTypography.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Birthday WhatsApp wish (dashboard birthday card "Wish" button)
// ============================================================================

/// Looks up the "Birthday Wishes" template (falls back to a sensible
/// default if the owner has deleted it), substitutes the customer's name,
/// and opens WhatsApp directly on that customer's chat with the message
/// prefilled — the owner still presses Send themselves.
Future<void> sendBirthdayWish(
    BuildContext context, WidgetRef ref, Customer customer) async {
  final List<WhatsappTemplate> templates =
      ref.read(whatsappTemplatesProvider).maybeWhen(
            data: (List<WhatsappTemplate> t) => t,
            orElse: () => const <WhatsappTemplate>[],
          );
  final WhatsappTemplate? template = templates
      .where((WhatsappTemplate t) => t.type == 'Birthday Wishes')
      .firstOrNull;
  final String body = (template?.body ??
          'Happy Birthday {{name}}! 🎉🌸 Enjoy 20% OFF your next visit this week.')
      .replaceAll('{{name}}', customer.name);

  final String digits = customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    if (context.mounted)
      AppSnackBar.show(context,
          message: '${customer.name} has no phone number saved.',
          type: AppSnackBarType.error);
    return;
  }
  final String withCountryCode = digits.length == 10 ? '91$digits' : digits;
  final Uri uri = Uri.parse(
      'https://wa.me/$withCountryCode?text=${Uri.encodeComponent(body)}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

// ============================================================================
// Notifications sheet (dashboard bell)
// ============================================================================

/// Opens the notification list as a modal bottom sheet — birthday alerts,
/// low-stock warnings, and any other notification the app has logged.
/// Notifications older than 15 days are purged automatically elsewhere
/// (see [notificationsPurgeProvider]); this sheet also offers "Clear All".
void showNotificationsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const _NotificationsSheet(),
  );
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> notificationsAsync =
        ref.watch(notificationsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXl)),
          ),
          child: Column(
            children: <Widget>[
              SizedBox(height: AppSpacing.sm),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusPill))),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Notifications',
                        style: AppTypography.h3(AppColors.foreground)
                            .copyWith(fontSize: 16.sp)),
                    notificationsAsync.maybeWhen(
                      data: (List<AppNotification> list) => list.isEmpty
                          ? const SizedBox.shrink()
                          : TextButton(
                              onPressed: () => _confirmClearAll(context, ref),
                              child: Text('Clear All',
                                  style: AppTypography.caption(
                                          AppColors.destructive)
                                      .copyWith(
                                          fontWeight: AppTypography.bold)),
                            ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: notificationsAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (Object e, _) => AppErrorWidget(message: '$e'),
                  data: (List<AppNotification> list) {
                    if (list.isEmpty) {
                      return const EmptyWidget(
                          icon: Icons.notifications_none,
                          title: 'No notifications',
                          message: "You're all caught up.");
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                          AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
                      itemCount: list.length,
                      itemBuilder: (BuildContext context, int i) {
                        final AppNotification n = list[i];
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            onTap: n.read
                                ? null
                                : () => ref
                                    .read(appNotificationsDaoProvider)
                                    .markNotificationRead(n.id),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width: 36.r,
                                  height: 36.r,
                                  decoration: BoxDecoration(
                                      color: _colorFor(n.type)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusMd)),
                                  child: Icon(_iconFor(n.type),
                                      size: AppDimensions.iconSm,
                                      color: _colorFor(n.type)),
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(n.title,
                                          style: AppTypography.label(
                                                  AppColors.foreground)
                                              .copyWith(
                                                  fontWeight: n.read
                                                      ? AppTypography.medium
                                                      : AppTypography.bold)),
                                      SizedBox(height: 2.h),
                                      Text(n.body,
                                          style: AppTypography.caption(
                                              AppColors.mutedForeground)),
                                    ],
                                  ),
                                ),
                                if (!n.read)
                                  Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: 'Clear All Notifications?',
      message:
          'This will permanently remove every notification. This cannot be undone.',
      confirmLabel: 'Clear All',
      isDestructive: true,
    );
    if (confirmed) {
      await ref.read(appNotificationsDaoProvider).clearAllNotifications();
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'birthday':
        return Icons.card_giftcard;
      case 'lowStock':
        return Icons.warning_amber_rounded;
      case 'appointment':
        return Icons.calendar_today_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'birthday':
        return AppColors.primary;
      case 'lowStock':
        return const Color(0xFFF59E0B);
      case 'appointment':
        return AppColors.accent;
      default:
        return AppColors.mutedForeground;
    }
  }
}
