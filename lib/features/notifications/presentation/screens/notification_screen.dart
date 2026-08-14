import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// Notification preference toggles. Each switch reads/writes straight to
/// `SharedPreferences` (registered once in `configureDependencies()`), so
/// the choice persists across app restarts — this is the actual settings
/// state `flutter_local_notifications` scheduling will read once wired up.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final SharedPreferences _prefs = getIt<SharedPreferences>();

  static const String _keyAppointmentReminders =
      'pref_notif_appointment_reminders';
  static const String _keyBirthdayReminders = 'pref_notif_birthday_reminders';
  static const String _keyLowStockAlerts = 'pref_notif_low_stock_alerts';
  static const String _keyDailySummary = 'pref_notif_daily_summary';

  bool _get(String key) => _prefs.getBool(key) ?? true;

  void _set(String key, bool value) =>
      setState(() => _prefs.setBool(key, value));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Notifications', onBack: widget.onBack),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _Toggle(
                  icon: Icons.calendar_today_outlined,
                  title: 'Appointment Reminders',
                  subtitle: 'Notify before upcoming appointments',
                  value: _get(_keyAppointmentReminders),
                  onChanged: (bool v) => _set(_keyAppointmentReminders, v),
                ),
                const Divider(height: 1),
                _Toggle(
                  icon: Icons.card_giftcard_outlined,
                  title: 'Birthday Reminders',
                  subtitle: "Alert when it's a customer's birthday",
                  value: _get(_keyBirthdayReminders),
                  onChanged: (bool v) => _set(_keyBirthdayReminders, v),
                ),
                const Divider(height: 1),
                _Toggle(
                  icon: Icons.warning_amber_outlined,
                  title: 'Low Stock Alerts',
                  subtitle: 'Notify when inventory falls below minimum',
                  value: _get(_keyLowStockAlerts),
                  onChanged: (bool v) => _set(_keyLowStockAlerts, v),
                ),
                const Divider(height: 1),
                _Toggle(
                  icon: Icons.summarize_outlined,
                  title: 'Daily Summary',
                  subtitle: "End-of-day revenue & appointments recap",
                  value: _get(_keyDailySummary),
                  onChanged: (bool v) => _set(_keyDailySummary, v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        child: Icon(icon, size: AppDimensions.iconSm, color: AppColors.primary),
      ),
      title: Text(title,
          style: AppTypography.label(AppColors.foreground)
              .copyWith(fontWeight: AppTypography.semiBold)),
      subtitle: Text(subtitle,
          style: AppTypography.caption(AppColors.mutedForeground)),
      trailing: Switch(
          value: value, onChanged: onChanged, activeThumbColor: Colors.white),
    );
  }
}
