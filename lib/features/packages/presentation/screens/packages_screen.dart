import 'package:beauty_parlour_management/core/database/daos/appointments_dao.dart';
import 'package:beauty_parlour_management/core/database/daos/customers_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class _Package {
  const _Package(this.name, this.services, this.originalPrice, this.price,
      this.validityDays);
  final String name;
  final List<String> services;
  final int originalPrice;
  final int price;
  final int validityDays;
}

const List<_Package> _catalog = <_Package>[
  _Package(
      'Bridal Glow',
      <String>['Gold Facial', 'Threading', 'Manicure', 'Pedicure'],
      8400,
      6500,
      90),
  _Package(
      'Monthly Refresh',
      <String>[
        'Haircut & Style',
        'Hair Spa',
        'Cleanup',
        'Threading - Eyebrows'
      ],
      2550,
      1999,
      30),
  _Package('Nail Care Duo', <String>['Gel Manicure', 'Pedicure (Spa)'], 1600,
      1299, 60),
  _Package(
      'Hair Transformation',
      <String>[
        'Haircut & Style',
        'Hair Color (Global)',
        'Hair Spa',
        'Blowdry & Style'
      ],
      3900,
      2999,
      45),
];

/// Package catalog. "Sell Package" records a real completed appointment
/// for the chosen customer for the full package price and services, and
/// bumps their visit/spend/points stats — same as a normal bill.
class PackagesScreen extends ConsumerWidget {
  const PackagesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppointmentsDao db = ref.watch(appointmentsDaoProvider);
    final CustomersDao customersDao = ref.watch(customersDaoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Service Packages', onBack: onBack),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
        children: <Widget>[
          for (final _Package pkg in _catalog) ...<Widget>[
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppDimensions.radiusLg))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(pkg.name,
                                  style: AppTypography.h3(Colors.white)),
                              Text('${pkg.validityDays} days validity',
                                  style: AppTypography.caption(
                                      Colors.white.withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text('₹${pkg.originalPrice}',
                                style: AppTypography.caption(
                                        Colors.white.withValues(alpha: 0.6))
                                    .copyWith(
                                        decoration:
                                            TextDecoration.lineThrough)),
                            Text('₹${pkg.price}',
                                style: AppTypography.h2(Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(spacing: 6, runSpacing: 6, children: <Widget>[
                          for (final String s in pkg.services)
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F4),
                                    borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusPill)),
                                child: Text(s,
                                    style:
                                        AppTypography.caption(AppColors.primary)
                                            .copyWith(
                                                fontWeight:
                                                    AppTypography.semiBold)))
                        ]),
                        SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => _showSellDialog(
                                context, ref, db, customersDao, pkg),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMd)),
                              child: Text('Sell Package',
                                  style: AppTypography.caption(Colors.white)
                                      .copyWith(
                                          fontWeight: AppTypography.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  void _showSellDialog(BuildContext context, WidgetRef ref, AppointmentsDao db,
      CustomersDao customerDao, _Package pkg) {
    AppDialog.show(
      context,
      title: 'Sell "${pkg.name}" to...',
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
                        final DateTime now = DateTime.now();
                        await db.addAppointment(AppointmentsCompanion.insert(
                          customerId: c.id,
                          customerName: c.name,
                          services: pkg.services.join(','),
                          date: now.toIso8601String().substring(0, 10),
                          time:
                              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                          amount: Value<int>(pkg.price),
                          status: const Value<String>('completed'),
                          notes: Value<String>('Package: ${pkg.name}'),
                        ));
                        await customerDao.recordVisit(c.id,
                            amountSpent: pkg.price);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          AppSnackBar.show(context,
                              message: '${pkg.name} sold to ${c.name}.',
                              type: AppSnackBarType.success);
                        }
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
}
