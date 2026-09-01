import 'package:beauty_parlour_management/core/database/daos/settings_dao.dart';
import 'package:beauty_parlour_management/core/providers/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
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
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Future<Map<String, String>> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SettingsDao settingsDao = ref.read(settingsDaoProvider);

    _settingsFuture = Future.wait<String?>(<Future<String?>>[
      settingsDao.getSetting('first_name'),
      settingsDao.getSetting('last_name'),
      settingsDao.getSetting('business_name'),
    ]).then((List<String?> values) {
      return <String, String>{
        'first_name': values[0]?.trim() ?? '',
        'last_name': values[1]?.trim() ?? '',
        'business_name': values[2]?.trim() ?? '',
      };
    });
  }

  String _getInitials(
    String firstName,
    String lastName,
  ) {
    final String first = firstName.trim();
    final String last = lastName.trim();

    final String firstInitial =
        first.isNotEmpty ? first.substring(0, 1).toUpperCase() : '';

    final String lastInitial =
        last.isNotEmpty ? last.substring(0, 1).toUpperCase() : '';

    if (firstInitial.isEmpty && lastInitial.isEmpty) {
      return 'OW';
    }

    return '$firstInitial$lastInitial';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = ref.watch(themeModeProvider);

    return FutureBuilder<Map<String, String>>(
      future: _settingsFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<Map<String, String>> snapshot,
      ) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Unable to load settings',
                  style: AppTypography.label(
                    AppColors.foreground,
                  ),
                ),
              ),
            ),
          );
        }

        // Get database values
        final Map<String, String> settings =
            snapshot.data ?? <String, String>{};

        final String firstName = settings['first_name']?.trim() ?? '';

        final String lastName = settings['last_name']?.trim() ?? '';

        final String businessName = settings['business_name']?.trim() ?? '';

        // Full owner name
        final String ownerName = '$firstName $lastName'.trim().isNotEmpty
            ? '$firstName $lastName'.trim()
            : 'Owner';

        // Business name
        final String displayBusinessName =
            businessName.isNotEmpty ? businessName : 'Beauty Studio';

        // Initials
        final String initials = _getInitials(
          firstName,
          lastName,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xxl,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Settings',
                      style: AppTypography.h2(
                        Colors.white,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Row(
                      children: <Widget>[
                        AppAvatar(
                          initials: initials,
                          size: AppAvatarSize.lg,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                ownerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(
                                  Colors.white,
                                ).copyWith(
                                  fontWeight: AppTypography.bold,
                                ),
                              ),
                              Text(
                                displayBusinessName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption(
                                  Colors.white.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(
                    AppSpacing.md,
                  ),
                  children: <Widget>[
                    _SectionLabel('BUSINESS'),
                    _SettingsGroup(
                      children: <Widget>[
                        _SettingsTile(
                          icon: Icons.storefront_outlined,
                          title: 'Business Profile',
                          subtitle: 'Name, address, contact',
                        ),
                        _SettingsTile(
                          icon: Icons.content_cut_outlined,
                          title: 'Services & Pricing',
                          subtitle: 'Manage service menu',
                        ),
                        _SettingsTile(
                          icon: Icons.card_membership_outlined,
                          title: 'Membership Plans',
                          subtitle: 'Silver, Gold, Platinum',
                          onTap: widget.onOpenMemberships,
                        ),
                        _SettingsTile(
                          icon: Icons.local_offer_outlined,
                          title: 'Service Packages',
                          subtitle: 'Bundled offers',
                          onTap: widget.onOpenPackages,
                        ),
                        _SettingsTile(
                          icon: Icons.star_border,
                          title: 'Loyalty Program',
                          subtitle: 'Points & rewards',
                          onTap: widget.onOpenLoyalty,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    _SectionLabel('PREFERENCES'),
                    _SettingsGroup(
                      children: <Widget>[
                        // _SwitchTile(
                        //   icon: Icons.dark_mode_outlined,
                        //   title: 'Dark Mode',
                        //   subtitle: 'Switch app appearance',
                        //   value: mode == ThemeMode.dark,
                        //   onChanged: (bool value) {
                        //     ref
                        //         .read(
                        //           themeModeProvider.notifier,
                        //         )
                        //         .setThemeMode(
                        //           value ? ThemeMode.dark : ThemeMode.light,
                        //         );
                        //   },
                        // ),
                        _SettingsTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Reminders & alerts',
                          onTap: widget.onOpenNotifications,
                        ),
                        _SettingsTile(
                          icon: Icons.chat_bubble_outline,
                          title: 'WhatsApp Templates',
                          subtitle: 'Message templates',
                          onTap: widget.onOpenWhatsApp,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    _SectionLabel(
                      'DATA & SECURITY',
                    ),
                    _SettingsGroup(
                      children: <Widget>[
                        _SettingsTile(
                          icon: Icons.cloud_upload_outlined,
                          title: 'Backup & Restore',
                          subtitle: 'Google Drive sync',
                          onTap: widget.onOpenBackup,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    _SectionLabel('ABOUT'),
                    _SettingsGroup(
                      children: <Widget>[
                        _SettingsTile(
                          icon: Icons.info_outline,
                          title: 'App Version',
                          subtitle: AppConstants.appVersion,
                        ),
                        _SettingsTile(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'Contact us',
                        ),
                      ],
                    ),
                    SizedBox(
                      height: AppSpacing.xxxl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 4.w,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        text,
        style: AppTypography.caption(
          AppColors.mutedForeground,
        ).copyWith(
          fontWeight: AppTypography.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.children,
  });

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
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.destructive = false,
  });

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
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMd,
          ),
        ),
        child: Icon(
          icon,
          size: AppDimensions.iconSm,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.label(
          destructive ? AppColors.destructive : AppColors.foreground,
        ).copyWith(
          fontWeight: AppTypography.semiBold,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.caption(
                AppColors.mutedForeground,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFFC9B0B8),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

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
          color: AppColors.primary.withValues(
            alpha: 0.1,
          ),
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMd,
          ),
        ),
        child: Icon(
          icon,
          size: AppDimensions.iconSm,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.label(
          AppColors.foreground,
        ).copyWith(
          fontWeight: AppTypography.semiBold,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.caption(
                AppColors.mutedForeground,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
      ),
    );
  }
}
