import 'package:beauty_parlour_management/core/database/daos/customers_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class _Plan {
  const _Plan(this.name, this.price, this.months, this.discount, this.perks,
      this.emoji);
  final String name;
  final int price;
  final int months;
  final int discount;
  final List<String> perks;
  final String emoji;
}

const List<_Plan> _plans = <_Plan>[
  _Plan('Silver', 2999, 6, 10,
      <String>['Free Threading x4', '10% off all services'], '⭐'),
  _Plan(
      'Gold',
      5999,
      12,
      15,
      <String>[
        'Free Threading x12',
        '15% off all services',
        'Priority booking'
      ],
      '🥇'),
  _Plan(
      'Platinum',
      9999,
      12,
      20,
      <String>[
        'Unlimited Threading',
        '20% off all services',
        'Priority booking',
        'Free monthly facial'
      ],
      '💎'),
];

/// Membership plans + active members — reads/writes the real
/// `Customer.membership` column, so upgrading a customer here is reflected
/// immediately on their profile and everywhere else in the app.
class MembershipsScreen extends ConsumerWidget {
  const MembershipsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);
    final CustomersDao db = ref.watch(customersDaoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Membership Plans', onBack: onBack),
      body: customersAsync.when(
        loading: () => const LoadingWidget(),
        error: (Object e, _) => AppErrorWidget(message: '$e'),
        data: (List<Customer> customers) {
          final List<Customer> members = customers
              .where((Customer c) => (c.membership ?? '').isNotEmpty)
              .toList();
          return ListView(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
            children: <Widget>[
              for (final _Plan plan in _plans) ...<Widget>[
                _PlanCard(
                    plan: plan,
                    activeCount: members
                        .where((Customer m) => m.membership == plan.name)
                        .length,
                    onAssign: () =>
                        _showAssignDialog(context, ref, db, plan, customers)),
                SizedBox(height: AppSpacing.md),
              ],
              SizedBox(height: AppSpacing.sm),
              Text('Active Members',
                  style: AppTypography.h3(AppColors.foreground)
                      .copyWith(fontSize: 14.sp)),
              SizedBox(height: AppSpacing.sm),
              if (members.isEmpty)
                const EmptyWidget(
                    icon: Icons.card_membership_outlined,
                    title: 'No members yet',
                    message: 'Assign a plan to a customer above.')
              else
                for (final Customer c in members) ...<Widget>[
                  AppCard(
                    child: Row(
                      children: <Widget>[
                        AppAvatar(
                            initials: c.avatarInitials, size: AppAvatarSize.sm),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(c.name,
                                  style:
                                      AppTypography.label(AppColors.foreground)
                                          .copyWith(
                                              fontWeight: AppTypography.bold)),
                              Text(c.phone,
                                  style: AppTypography.caption(
                                      AppColors.mutedForeground)),
                            ],
                          ),
                        ),
                        _MemberBadge(type: c.membership!),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 16, color: AppColors.mutedForeground),
                          onPressed: () => db.updateCustomer(c.copyWith(
                              membership: const Value<String?>(null))),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                ],
            ],
          );
        },
      ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref, CustomersDao db,
      _Plan plan, List<Customer> customers) {
    AppDialog.show(
      context,
      title: 'Assign ${plan.name} to...',
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (final Customer c in customers)
              ListTile(
                leading: AppAvatar(
                    initials: c.avatarInitials, size: AppAvatarSize.sm),
                title: Text(c.name,
                    style: AppTypography.bodyMedium(AppColors.foreground)),
                subtitle: Text(c.membership ?? 'No membership',
                    style: AppTypography.caption(AppColors.mutedForeground)),
                onTap: () {
                  db.updateCustomer(
                      c.copyWith(membership: Value<String?>(plan.name)));
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
      secondaryActionLabel: 'Cancel',
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard(
      {required this.plan, required this.activeCount, required this.onAssign});

  final _Plan plan;
  final int activeCount;
  final VoidCallback onAssign;

  Color get _color {
    switch (plan.name) {
      case 'Silver':
        return const Color(0xFF9E9E9E);
      case 'Gold':
        return const Color(0xFFC9956C);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(color: _color.withValues(alpha: 0.2))),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(plan.emoji, style: TextStyle(fontSize: 28.sp)),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${plan.name} Membership',
                        style: AppTypography.h3(AppColors.foreground)
                            .copyWith(fontSize: 15.sp)),
                    Text(
                        '${plan.months} months validity · ${plan.discount}% discount',
                        style:
                            AppTypography.caption(AppColors.mutedForeground)),
                  ],
                ),
              ),
              Text('₹${plan.price}',
                  style: AppTypography.h2(AppColors.foreground)
                      .copyWith(fontSize: 20.sp)),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          for (final String perk in plan.perks)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Row(children: <Widget>[
                const Icon(Icons.check, size: 14, color: AppColors.primary),
                SizedBox(width: AppSpacing.xxs),
                Text(perk,
                    style: AppTypography.caption(const Color(0xFF6B4848)))
              ]),
            ),
          SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('$activeCount active members',
                  style: AppTypography.caption(AppColors.mutedForeground)),
              InkWell(
                onTap: onAssign,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      color: _color,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusPill)),
                  child: Text('Assign',
                      style: AppTypography.caption(Colors.white)
                          .copyWith(fontWeight: AppTypography.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberBadge extends StatelessWidget {
  const _MemberBadge({required this.type});

  final String type;

  static const Map<String, List<Color>> _colors = <String, List<Color>>{
    'Silver': <Color>[Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
    'Gold': <Color>[Color(0xFFC9956C), Color(0xFFE0B080)],
    'Platinum': <Color>[AppColors.primary, AppColors.accent],
  };
  static const Map<String, String> _icons = <String, String>{
    'Silver': '⭐',
    'Gold': '🥇',
    'Platinum': '💎'
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: _colors[type] ??
                  <Color>[AppColors.primary, AppColors.accent]),
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill)),
      child: Text('${_icons[type] ?? ''} $type',
          style: AppTypography.caption(Colors.white)
              .copyWith(fontSize: 10.sp, fontWeight: AppTypography.bold)),
    );
  }
}
