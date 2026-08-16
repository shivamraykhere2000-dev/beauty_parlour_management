import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen(
      {super.key,
      this.onAddCustomer,
      this.onOpenCustomer,
      this.onEditCustomer});

  final VoidCallback? onAddCustomer;
  final ValueChanged<Customer>? onOpenCustomer;
  final ValueChanged<Customer>? onEditCustomer;

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _filter = 'All';

  static const List<String> _filters = <String>[
    'All',
    'VIP',
    'Members',
    'Regular',
    'New'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xxl, AppSpacing.md, AppSpacing.md),
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Customers', style: AppTypography.h2(Colors.white)),
                    InkWell(
                      onTap: widget.onAddCustomer,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusPill),
                      child: Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (String v) => setState(() => _search = v),
                    style: AppTypography.input(Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search name or phone...',
                      hintStyle: AppTypography.input(
                          Colors.white.withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.search,
                          size: AppDimensions.iconSm,
                          color: Colors.white.withValues(alpha: 0.7)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, StackTrace st) =>
                  AppErrorWidget(message: 'Could not load customers.\n$e'),
              data: (List<Customer> all) {
                final List<Customer> list = all.where((Customer c) {
                  final List<String> tags = c.tags
                      .split(',')
                      .where((String t) => t.isNotEmpty)
                      .toList();
                  final bool matchesSearch =
                      c.name.toLowerCase().contains(_search.toLowerCase()) ||
                          c.phone.contains(_search);
                  final bool matchesFilter = _filter == 'All' ||
                      tags.contains(_filter) ||
                      (_filter == 'Members' && c.membership != null);
                  return matchesSearch && matchesFilter;
                }).toList();

                return ListView(
                  padding: EdgeInsets.only(bottom: AppSpacing.xxxl),
                  children: <Widget>[
                    SizedBox(
                      height: 40.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(width: AppSpacing.xs),
                        itemBuilder: (BuildContext context, int index) {
                          final String f = _filters[index];
                          final bool active = f == _filter;
                          return ChoiceChip(
                            label: Text(f),
                            selected: active,
                            onSelected: (_) => setState(() => _filter = f),
                            labelStyle: AppTypography.caption(active
                                    ? Colors.white
                                    : const Color(0xFF6B4848))
                                .copyWith(fontWeight: AppTypography.semiBold),
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusPill)),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('${list.length} customers',
                          style:
                              AppTypography.caption(AppColors.mutedForeground)),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    if (list.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: AppSpacing.xxxl),
                        child: const EmptyWidget(
                            icon: Icons.people_outline,
                            title: 'No customers found',
                            message: 'Try a different search or filter.'),
                      )
                    else
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Column(
                          children: <Widget>[
                            for (final Customer c in list) ...<Widget>[
                              _CustomerRow(
                                  customer: c,
                                  onTap: () => widget.onOpenCustomer?.call(c),
                                  onEdit: () => widget.onEditCustomer?.call(c)),
                              SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow(
      {required this.customer, required this.onTap, required this.onEdit});

  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final List<String> tags =
        customer.tags.split(',').where((String t) => t.isNotEmpty).toList();
    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          AppAvatar(initials: customer.avatarInitials),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xxs,
                  children: <Widget>[
                    Text(customer.name,
                        style: AppTypography.label(AppColors.foreground)
                            .copyWith(fontWeight: AppTypography.bold)),
                    if (customer.membership != null)
                      _MemberBadge(type: customer.membership!),
                  ],
                ),
                Text(customer.phone,
                    style: AppTypography.caption(AppColors.mutedForeground)),
                SizedBox(height: 2.h),
                Wrap(
                  spacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text('${customer.visits} visits',
                        style: AppTypography.caption(const Color(0xFF6B4848))),
                    _Dot(),
                    Text(
                        '${(customer.totalSpent / 1000).toStringAsFixed(1)}K spent',
                        style: AppTypography.caption(const Color(0xFF6B4848))),
                    if (customer.lastVisit != null) ...<Widget>[
                      _Dot(),
                      Text(customer.lastVisit!,
                          style:
                              AppTypography.caption(const Color(0xFF6B4848))),
                    ],
                  ],
                ),
                if (tags.isNotEmpty) ...<Widget>[
                  SizedBox(height: AppSpacing.xxs),
                  Wrap(spacing: 4, runSpacing: 4, children: <Widget>[
                    for (final String t in tags) AppTag(label: t)
                  ]),
                ],
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.primary),
                ),
              ),
              SizedBox(height: 4.h),
              const Icon(Icons.chevron_right, color: Color(0xFFC9B0B8)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 3,
        height: 3,
        decoration: const BoxDecoration(
            color: Color(0xFFDEC8CC), shape: BoxShape.circle));
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
    final List<Color> gradient =
        _colors[type] ?? <Color>[AppColors.primary, AppColors.accent];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Text('${_icons[type] ?? ''} $type',
          style: AppTypography.caption(Colors.white)
              .copyWith(fontSize: 10.sp, fontWeight: AppTypography.bold)),
    );
  }
}
