import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class _Template {
  const _Template(this.type, this.emoji, this.body);
  final String type;
  final String emoji;
  final String body;
}

const List<_Template> _templates = <_Template>[
  _Template('Appointment Confirmation', '📅',
      'Hi {{name}}! Your appointment at Blossom Beauty Studio is confirmed. We look forward to seeing you! 💅'),
  _Template('Birthday Wishes', '🎂',
      'Happy Birthday {{name}}! 🎉🌸 Enjoy 20% OFF your next visit this week. Book now: 📞 9876543210'),
  _Template('Festival Offer', '🪔',
      '🌟 Festival Special at Blossom Beauty Studio 🌟 15% off all services this week. Book now! 📞 9876543210'),
  _Template('Thank You Message', '💝',
      'Thank you for visiting Blossom Beauty Studio, {{name}}! 🌸 Hope you loved your visit. See you again soon!'),
  _Template('Package Expiry Reminder', '⏰',
      'Hi {{name}}, your package is expiring soon. Book now to use your remaining sessions! 📞 9876543210'),
];

/// WhatsApp message templates, wired to real customers — picking a
/// customer opens WhatsApp (via `url_launcher`) with their name filled
/// into the template and their real phone number as the recipient.
class WhatsAppScreen extends ConsumerWidget {
  const WhatsAppScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'WhatsApp Templates', onBack: onBack),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
        children: <Widget>[
          for (final _Template t in _templates) ...<Widget>[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(t.emoji, style: TextStyle(fontSize: 20.sp)),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                          child: Text(t.type,
                              style: AppTypography.label(AppColors.foreground)
                                  .copyWith(fontWeight: AppTypography.bold))),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(t.body,
                      style: AppTypography.caption(AppColors.mutedForeground),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickCustomerAndSend(context, ref, t),
                      icon: const Icon(Icons.send_outlined, size: 16),
                      label: const Text('Send to Customer'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  void _pickCustomerAndSend(
      BuildContext context, WidgetRef ref, _Template template) {
    AppDialog.show(
      context,
      title: 'Send "${template.type}" to...',
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final AsyncValue<List<Customer>> customersAsync =
                ref.watch(customersProvider);
            return customersAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, _) => AppErrorWidget(message: '$e'),
              data: (List<Customer> customers) => ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (final Customer c in customers)
                    ListTile(
                      leading: AppAvatar(
                          initials: c.avatarInitials, size: AppAvatarSize.sm),
                      title: Text(c.name,
                          style:
                              AppTypography.bodyMedium(AppColors.foreground)),
                      subtitle: Text(c.phone,
                          style:
                              AppTypography.caption(AppColors.mutedForeground)),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _launchWhatsApp(c.phone,
                            template.body.replaceAll('{{name}}', c.name));
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
      secondaryActionLabel: 'Cancel',
    );
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    final String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final String withCountryCode = digits.length == 10 ? '91$digits' : digits;
    final Uri uri = Uri.parse(
        'https://wa.me/$withCountryCode?text=${Uri.encodeComponent(message)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
