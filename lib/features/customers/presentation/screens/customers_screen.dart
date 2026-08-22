import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({
    super.key,
    this.onAddCustomer,
    this.onOpenCustomer,
    this.onEditCustomer,
  });

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
    'New',
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
          _buildHeader(),
          Expanded(
            child: customersAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, StackTrace st) {
                return AppErrorWidget(
                  message: 'Could not load customers.\n$e',
                );
              },
              data: (List<Customer> allCustomers) {
                final List<Customer> filteredCustomers =
                    _filterCustomers(allCustomers);

                return _buildCustomerList(filteredCustomers);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  'Customers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h2(Colors.white),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: widget.onAddCustomer,
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusPill,
                ),
                child: Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          _buildSearchField(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH FIELD
  // ---------------------------------------------------------------------------

  Widget _buildSearchField() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusMd,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (String value) {
          setState(() {
            _search = value;
          });
        },
        style: AppTypography.input(Colors.white),
        decoration: InputDecoration(
          hintText: 'Search name or phone...',
          hintStyle: AppTypography.input(
            Colors.white.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: AppDimensions.iconSm,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          filled: false,
          contentPadding: EdgeInsets.symmetric(
            vertical: 10.h,
            horizontal: 4.w,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER CUSTOMERS
  // ---------------------------------------------------------------------------

  List<Customer> _filterCustomers(
    List<Customer> allCustomers,
  ) {
    final String search = _search.trim().toLowerCase();

    return allCustomers.where((Customer customer) {
      final List<String> tags = customer.tags
          .split(',')
          .map((String tag) => tag.trim())
          .where((String tag) => tag.isNotEmpty)
          .toList();

      final bool matchesSearch = customer.name.toLowerCase().contains(search) ||
          customer.phone.toLowerCase().contains(search);

      final bool matchesFilter = _filter == 'All' ||
          tags.any(
            (String tag) => tag.toLowerCase() == _filter.toLowerCase(),
          ) ||
          (_filter == 'Members' && customer.membership != null);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // CUSTOMER LIST
  // ---------------------------------------------------------------------------

  Widget _buildCustomerList(
    List<Customer> list,
  ) {
    return ListView(
      padding: EdgeInsets.only(
        bottom: AppSpacing.xxxl,
      ),
      children: <Widget>[
        _buildFilterBar(),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
          ),
          child: Text(
            '${list.length} customers',
            style: AppTypography.caption(
              AppColors.mutedForeground,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        if (list.isEmpty) _buildEmptyState() else _buildCustomerRows(list),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER BAR
  // ---------------------------------------------------------------------------

  Widget _buildFilterBar() {
    return Padding(
      padding: EdgeInsets.only(
        top: 6.h,
        bottom: 10.h,
      ),
      child: SizedBox(
        height: 44.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 3.h,
          ),
          itemCount: _filters.length,
          separatorBuilder: (
            BuildContext context,
            int index,
          ) {
            return SizedBox(
              width: 8.w,
            );
          },
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final String filter = _filters[index];

            final bool active = filter == _filter;

            return _CustomerFilterChip(
              label: filter,
              selected: active,
              onTap: () {
                setState(() {
                  _filter = filter;
                });
              },
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.xxxl,
      ),
      child: const EmptyWidget(
        icon: Icons.people_outline,
        title: 'No customers found',
        message: 'Try a different search or filter.',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CUSTOMER ROWS
  // ---------------------------------------------------------------------------

  Widget _buildCustomerRows(
    List<Customer> list,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      child: Column(
        children: <Widget>[
          for (final Customer customer in list) ...<Widget>[
            _CustomerRow(
              customer: customer,
              onTap: () {
                widget.onOpenCustomer?.call(customer);
              },
              onEdit: () {
                widget.onEditCustomer?.call(customer);
              },
            ),
            SizedBox(
              height: AppSpacing.sm,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOMER FILTER CHIP
// =============================================================================

class _CustomerFilterChip extends StatelessWidget {
  const _CustomerFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusPill,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 7.h,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusPill,
            ),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: AppTypography.caption(
                selected ? Colors.white : const Color(0xFF6B4848),
              ).copyWith(
                fontWeight: AppTypography.semiBold,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOMER ROW
// =============================================================================

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.customer,
    required this.onTap,
    required this.onEdit,
  });

  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final List<String> tags = customer.tags
        .split(',')
        .map((String tag) => tag.trim())
        .where((String tag) => tag.isNotEmpty)
        .toList();

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // -----------------------------------------------------------------
          // AVATAR
          // -----------------------------------------------------------------

          AppAvatar(
            initials: customer.avatarInitials,
          ),

          SizedBox(
            width: AppSpacing.sm,
          ),

          // -----------------------------------------------------------------
          // CUSTOMER INFORMATION
          // -----------------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Name + Membership
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xxs,
                  runSpacing: 2.h,
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 180.w,
                      ),
                      child: Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(
                          AppColors.foreground,
                        ).copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ),
                    if (customer.membership != null)
                      _MemberBadge(
                        type: customer.membership!,
                      ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Phone
                Text(
                  customer.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    AppColors.mutedForeground,
                  ),
                ),

                SizedBox(height: 4.h),

                // Visit information
                Wrap(
                  spacing: AppSpacing.xxs,
                  runSpacing: 2.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      '${customer.visits} visits',
                      style: AppTypography.caption(
                        const Color(0xFF6B4848),
                      ),
                    ),
                    const _Dot(),
                    Text(
                      '${(customer.totalSpent / 1000).toStringAsFixed(1)}K spent',
                      style: AppTypography.caption(
                        const Color(0xFF6B4848),
                      ),
                    ),
                    if (customer.lastVisit != null) ...<Widget>[
                      const _Dot(),
                      Text(
                        customer.lastVisit!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          const Color(0xFF6B4848),
                        ),
                      ),
                    ],
                  ],
                ),

                // Tags
                if (tags.isNotEmpty) ...<Widget>[
                  SizedBox(
                    height: AppSpacing.xxs,
                  ),
                  Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: <Widget>[
                      for (final String tag in tags)
                        AppTag(
                          label: tag,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SizedBox(
            width: 4.w,
          ),

          // -----------------------------------------------------------------
          // EDIT + ARROW
          // -----------------------------------------------------------------

          SizedBox(
            width: 28.w,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusPill,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 4.h,
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFC9B0B8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DOT
// =============================================================================

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Color(0xFFDEC8CC),
        shape: BoxShape.circle,
      ),
    );
  }
}

// =============================================================================
// MEMBERSHIP BADGE
// =============================================================================

class _MemberBadge extends StatelessWidget {
  const _MemberBadge({
    required this.type,
  });

  final String type;

  static const Map<String, List<Color>> _colors = <String, List<Color>>{
    'Silver': <Color>[
      Color(0xFFBDBDBD),
      Color(0xFF9E9E9E),
    ],
    'Gold': <Color>[
      Color(0xFFC9956C),
      Color(0xFFE0B080),
    ],
    'Platinum': <Color>[
      AppColors.primary,
      AppColors.accent,
    ],
  };

  static const Map<String, String> _icons = <String, String>{
    'Silver': '⭐',
    'Gold': '🥇',
    'Platinum': '💎',
  };

  @override
  Widget build(BuildContext context) {
    final List<Color> gradient = _colors[type] ??
        <Color>[
          AppColors.primary,
          AppColors.accent,
        ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 7.w,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusPill,
        ),
      ),
      child: Text(
        '${_icons[type] ?? ''} $type',
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption(
          Colors.white,
        ).copyWith(
          fontSize: 10.sp,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}
