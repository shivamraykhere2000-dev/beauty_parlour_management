import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    this.onOpenBackup,
    this.onOpenNotifications,
    this.onOpenWhatsApp,
    this.onOpenMemberships,
    this.onOpenPackages,
    this.onOpenLoyalty,
    this.onLockNow,
  });

  final VoidCallback? onOpenBackup;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenWhatsApp;
  final VoidCallback? onOpenMemberships;
  final VoidCallback? onOpenPackages;
  final VoidCallback? onOpenLoyalty;
  final VoidCallback? onLockNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xxl, AppSpacing.md, AppSpacing.lg),
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Settings', style: AppTypography.h2(Colors.white)),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    const AppAvatar(initials: 'PR', size: AppAvatarSize.lg),
                    SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Priya Sharma',
                            style: AppTypography.label(Colors.white)
                                .copyWith(fontWeight: AppTypography.bold)),
                        Text('Blossom Beauty Studio',
                            style: AppTypography.caption(
                                Colors.white.withValues(alpha: 0.7))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                _SectionLabel('BUSINESS'),
                _SettingsGroup(
                  children: <Widget>[
                    _SettingsTile(
                        icon: Icons.storefront_outlined,
                        title: 'Business Profile',
                        subtitle: 'Name, address, contact'),
                    _SettingsTile(
                        icon: Icons.content_cut_outlined,
                        title: 'Services & Pricing',
                        subtitle: 'Manage service menu'),
                    _SettingsTile(
                        icon: Icons.card_membership_outlined,
                        title: 'Membership Plans',
                        subtitle: 'Silver, Gold, Platinum',
                        onTap: onOpenMemberships),
                    _SettingsTile(
                        icon: Icons.local_offer_outlined,
                        title: 'Service Packages',
                        subtitle: 'Bundled offers',
                        onTap: onOpenPackages),
                    _SettingsTile(
                        icon: Icons.star_border,
                        title: 'Loyalty Program',
                        subtitle: 'Points & rewards',
                        onTap: onOpenLoyalty),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                _SectionLabel('PREFERENCES'),
                _SettingsGroup(
                  children: <Widget>[
                    _SwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      subtitle: 'Switch app appearance',
                      value: mode == ThemeMode.dark,
                      onChanged: (bool v) => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                    ),
                    _SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Reminders & alerts',
                        onTap: onOpenNotifications),
                    _SettingsTile(
                        icon: Icons.chat_bubble_outline,
                        title: 'WhatsApp Templates',
                        subtitle: 'Message templates',
                        onTap: onOpenWhatsApp),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                _SectionLabel('DATA & SECURITY'),
                _SettingsGroup(
                  children: <Widget>[
                    _SettingsTile(
                        icon: Icons.cloud_upload_outlined,
                        title: 'Backup & Restore',
                        subtitle: 'Google Drive sync',
                        onTap: onOpenBackup),
                    _SettingsTile(
                        icon: Icons.lock_outline,
                        title: 'Change PIN',
                        subtitle: 'Update app-lock PIN'),
                    _SettingsTile(
                        icon: Icons.logout,
                        title: 'Lock App Now',
                        subtitle: 'Require PIN to reopen',
                        onTap: onLockNow,
                        destructive: true),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                _SectionLabel('ABOUT'),
                _SettingsGroup(
                  children: <Widget>[
                    _SettingsTile(
                        icon: Icons.info_outline,
                        title: 'App Version',
                        subtitle: AppConstants.appVersion),
                    _SettingsTile(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Contact us'),
                  ],
                ),
                SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: AppSpacing.xs),
      child: Text(text,
          style: AppTypography.caption(AppColors.mutedForeground)
              .copyWith(fontWeight: AppTypography.bold, letterSpacing: 1)),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            children[i],
            if (i < children.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.onTap,
      this.destructive = false});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color color = destructive ? AppColors.destructive : AppColors.primary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        child: Icon(icon, size: AppDimensions.iconSm, color: color),
      ),
      title: Text(title,
          style: AppTypography.label(
                  destructive ? AppColors.destructive : AppColors.foreground)
              .copyWith(fontWeight: AppTypography.semiBold)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: AppTypography.caption(AppColors.mutedForeground))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFC9B0B8)),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile(
      {required this.icon,
      required this.title,
      required this.value,
      required this.onChanged,
      this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        child: Icon(icon, size: AppDimensions.iconSm, color: AppColors.primary),
      ),
      title: Text(title,
          style: AppTypography.label(AppColors.foreground)
              .copyWith(fontWeight: AppTypography.semiBold)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: AppTypography.caption(AppColors.mutedForeground))
          : null,
      trailing: Switch(
          value: value, onChanged: onChanged, activeThumbColor: Colors.white),
    );
  }
}
