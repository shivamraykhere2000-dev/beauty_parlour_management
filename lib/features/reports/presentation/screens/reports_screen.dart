import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// Business reports, computed live from the Drift database — no mock data.
/// Revenue/expenses/top-services all recompute automatically whenever a
/// bill is collected, an expense is logged, or a customer is added.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Appointment>> appointmentsAsync =
        ref.watch(allAppointmentsProvider);
    final AsyncValue<List<Expense>> expensesAsync = ref.watch(expensesProvider);
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);

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
            child: Text('Reports', style: AppTypography.h2(Colors.white)),
          ),
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, _) => AppErrorWidget(message: '$e'),
              data: (List<Appointment> appointments) {
                return expensesAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (Object e, _) => AppErrorWidget(message: '$e'),
                  data: (List<Expense> expenses) {
                    return customersAsync.when(
                      loading: () => const LoadingWidget(),
                      error: (Object e, _) => AppErrorWidget(message: '$e'),
                      data: (List<Customer> customers) => _ReportsBody(
                          appointments: appointments,
                          expenses: expenses,
                          customers: customers),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody(
      {required this.appointments,
      required this.expenses,
      required this.customers});

  final List<Appointment> appointments;
  final List<Expense> expenses;
  final List<Customer> customers;

  @override
  Widget build(BuildContext context) {
    final List<Appointment> completed =
        appointments.where((Appointment a) => a.status == 'completed').toList();
    final int revenue =
        completed.fold<int>(0, (int s, Appointment a) => s + a.amount);
    final int expenseTotal =
        expenses.fold<int>(0, (int s, Expense e) => s + e.amount);
    final int netProfit = revenue - expenseTotal;

    final Map<String, int> serviceRevenue = <String, int>{};
    for (final Appointment a in completed) {
      final List<String> names = a.services
          .split(',')
          .where((String s) => s.trim().isNotEmpty)
          .toList();
      if (names.isEmpty) continue;
      final int share = (a.amount / names.length).round();
      for (final String n in names) {
        serviceRevenue[n.trim()] = (serviceRevenue[n.trim()] ?? 0) + share;
      }
    }
    final List<MapEntry<String, int>> topServices = serviceRevenue.entries
        .toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));
    final int maxServiceRevenue =
        topServices.isEmpty ? 1 : topServices.first.value;

    return ListView(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
                child: _StatCard(
                    label: 'Revenue',
                    value: '₹$revenue',
                    color: AppColors.success)),
            SizedBox(width: AppSpacing.sm),
            Expanded(
                child: _StatCard(
                    label: 'Expenses',
                    value: '₹$expenseTotal',
                    color: AppColors.destructive)),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
                child: _StatCard(
                    label: 'Net Profit',
                    value: '₹$netProfit',
                    color: AppColors.primary)),
            SizedBox(width: AppSpacing.sm),
            Expanded(
                child: _StatCard(
                    label: 'Customers',
                    value: '${customers.length}',
                    color: AppColors.accent)),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Text('Top Services by Revenue',
            style: AppTypography.h3(AppColors.foreground)
                .copyWith(fontSize: 14.sp)),
        SizedBox(height: AppSpacing.sm),
        if (topServices.isEmpty)
          const EmptyWidget(
              icon: Icons.bar_chart_outlined,
              title: 'No completed bills yet',
              message: 'Collect a payment to see service performance here.')
        else
          AppCard(
            child: Column(
              children: <Widget>[
                for (final MapEntry<String, int> e
                    in topServices.take(6)) ...<Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                                child: Text(e.key,
                                    style: AppTypography.bodySmall(
                                        AppColors.foreground),
                                    overflow: TextOverflow.ellipsis)),
                            Text('₹${e.value}',
                                style: AppTypography.caption(AppColors.primary)
                                    .copyWith(fontWeight: AppTypography.bold)),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusPill),
                          child: LinearProgressIndicator(
                            value: e.value / maxServiceRevenue,
                            minHeight: 6.h,
                            backgroundColor: const Color(0xFFF0E8EC),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        SizedBox(height: AppSpacing.md),
        Text('Expense Breakdown',
            style: AppTypography.h3(AppColors.foreground)
                .copyWith(fontSize: 14.sp)),
        SizedBox(height: AppSpacing.sm),
        if (expenses.isEmpty)
          const EmptyWidget(
              icon: Icons.wallet_outlined,
              title: 'No expenses logged',
              message: 'Add an expense to see the breakdown here.')
        else
          AppCard(
            child: Column(
              children: <Widget>[
                for (final MapEntry<String, int> e
                    in _byCategory(expenses).entries)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(e.key,
                            style:
                                AppTypography.bodySmall(AppColors.foreground)),
                        Text('₹${e.value}',
                            style: AppTypography.bodySmall(
                                AppColors.mutedForeground)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Map<String, int> _byCategory(List<Expense> expenses) {
    final Map<String, int> map = <String, int>{};
    for (final Expense e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTypography.caption(AppColors.mutedForeground)),
          SizedBox(height: 2.h),
          Text(value, style: AppTypography.h2(color).copyWith(fontSize: 20.sp)),
        ],
      ),
    );
  }
}
