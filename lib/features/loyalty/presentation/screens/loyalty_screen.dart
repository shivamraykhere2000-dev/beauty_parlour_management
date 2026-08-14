import 'package:beauty_parlour_management/core/database/daos/customers_dao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// Loyalty points leaderboard, backed by the real `Customer.points` column
/// (earned automatically — 1 point per ₹10 spent — via `recordVisit` when
/// a bill is collected). Redeeming here writes straight back to the DB.
class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);
    final CustomersDao db = ref.watch(customersDaoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Loyalty Program', onBack: onBack),
      body: customersAsync.when(
        loading: () => const LoadingWidget(),
        error: (Object e, _) => AppErrorWidget(message: '$e'),
        data: (List<Customer> customers) {
          final List<Customer> ranked = <Customer>[...customers]
            ..sort((Customer a, Customer b) => b.points.compareTo(a.points));
          final int totalPoints =
              customers.fold<int>(0, (int s, Customer c) => s + c.points);

          return ListView(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
            children: <Widget>[
              AppCard(
                color: const Color(0xFFFFF5F7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('How it works',
                        style: AppTypography.label(AppColors.primary)
                            .copyWith(fontWeight: AppTypography.bold)),
                    SizedBox(height: 4.h),
                    Text(
                        'Customers earn 1 point for every ₹10 spent. Points can be redeemed for discounts on future visits.',
                        style: AppTypography.caption(const Color(0xFF6B4848))),
                    SizedBox(height: AppSpacing.sm),
                    Text('$totalPoints total points across all customers',
                        style: AppTypography.caption(AppColors.primary)
                            .copyWith(fontWeight: AppTypography.bold)),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text('Top Members',
                  style: AppTypography.h3(AppColors.foreground)
                      .copyWith(fontSize: 14.sp)),
              SizedBox(height: AppSpacing.sm),
              if (ranked.isEmpty)
                const EmptyWidget(
                    icon: Icons.star_border,
                    title: 'No customers yet',
                    message:
                        'Points appear here once customers start visiting.')
              else
                for (int i = 0; i < ranked.length; i++) ...<Widget>[
                  AppCard(
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 24.w,
                          child: Text('#${i + 1}',
                              style: AppTypography.label(i < 3
                                      ? AppColors.primary
                                      : AppColors.mutedForeground)
                                  .copyWith(fontWeight: AppTypography.bold)),
                        ),
                        AppAvatar(
                            initials: ranked[i].avatarInitials,
                            size: AppAvatarSize.sm),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(ranked[i].name,
                                  style:
                                      AppTypography.label(AppColors.foreground)
                                          .copyWith(
                                              fontWeight: AppTypography.bold)),
                              Text('${ranked[i].visits} visits',
                                  style: AppTypography.caption(
                                      AppColors.mutedForeground)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text('${ranked[i].points} pts',
                                style: AppTypography.label(AppColors.primary)
                                    .copyWith(fontWeight: AppTypography.bold)),
                            if (ranked[i].points >= 100)
                              InkWell(
                                onTap: () => _redeem(context, db, ranked[i]),
                                child: Text('Redeem 100',
                                    style:
                                        AppTypography.caption(AppColors.accent)
                                            .copyWith(
                                                fontWeight:
                                                    AppTypography.bold)),
                              ),
                          ],
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

  Future<void> _redeem(
      BuildContext context, CustomersDao db, Customer c) async {
    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: 'Redeem Points?',
      message:
          'Redeem 100 points for ${c.name} against a ₹100 discount on their next visit?',
      confirmLabel: 'Redeem',
    );
    if (confirmed) {
      await db.updateCustomer(c.copyWith(points: c.points - 100));
      if (context.mounted)
        AppSnackBar.show(context,
            message: '100 points redeemed for ${c.name}.',
            type: AppSnackBarType.success);
    }
  }
}
