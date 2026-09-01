import 'package:beauty_parlour_management/core/database/daos/customers_dao.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/appointments_dao.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart'
    show statusFromString;

/// Customer profile — loads the live [Customer] row by id (so edits made
/// elsewhere are reflected immediately) and shows their real appointment
/// history pulled from the database.
class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen(
      {required this.customerId,
      super.key,
      this.onBack,
      this.onBookAppointment,
      this.onEdit});

  final int customerId;
  final VoidCallback? onBack;
  final VoidCallback? onBookAppointment;
  final ValueChanged<Customer>? onEdit;

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Customer>> customersAsync =
        ref.watch(customersProvider);
    final AsyncValue<List<Appointment>> apptsAsync =
        ref.watch(allAppointmentsProvider);

    return customersAsync.when(
      loading: () => const FullScreenLoading(),
      error: (Object e, _) => Scaffold(body: AppErrorWidget(message: '$e')),
      data: (List<Customer> customers) {
        final Customer? c = customers
            .where((Customer x) => x.id == widget.customerId)
            .firstOrNull;
        if (c == null) {
          return Scaffold(
            appBar: AppTopBar(title: 'Customer', onBack: widget.onBack),
            body: const EmptyWidget(
                icon: Icons.person_off_outlined,
                title: 'Customer not found',
                message: 'This customer may have been deleted.'),
          );
        }
        final List<Appointment> visits = apptsAsync.maybeWhen(
          data: (List<Appointment> all) =>
              all.where((Appointment a) => a.customerId == c.id).toList(),
          orElse: () => const <Appointment>[],
        );
        return _Body(
            customer: c,
            visits: visits,
            tab: _tab,
            onTabChanged: (int t) => setState(() => _tab = t),
            onBack: widget.onBack,
            onBookAppointment: widget.onBookAppointment,
            onEdit: widget.onEdit);
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body(
      {required this.customer,
      required this.visits,
      required this.tab,
      required this.onTabChanged,
      this.onBack,
      this.onBookAppointment,
      this.onEdit});

  final Customer customer;
  final List<Appointment> visits;
  final int tab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback? onBack;
  final VoidCallback? onBookAppointment;
  final ValueChanged<Customer>? onEdit;

  static const List<String> _tabs = <String>['Overview', 'Visits', 'Notes'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> tags = customer.tags
        .split(',')
        .where((String t) => t.trim().isNotEmpty)
        .toList();

    final AsyncValue<CustomerAppointmentSummary> summaryAsync = ref.watch(
      customerAppointmentSummaryProvider(
        customer.id,
      ),
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
                // -------------------------------------------------------------
                // TOP BAR
                // -------------------------------------------------------------

                Row(
                  children: <Widget>[
                    InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusPill,
                      ),
                      child: Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: AppSpacing.sm,
                    ),

                    Expanded(
                      child: Text(
                        'Customer Profile',
                        style: AppTypography.label(
                          Colors.white,
                        ).copyWith(
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                    ),

                    // Edit
                    InkWell(
                      onTap: () {
                        onEdit?.call(customer);
                      },
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),

                    SizedBox(
                      width: AppSpacing.md,
                    ),

                    // Delete
                    InkWell(
                      onTap: () {
                        _confirmDelete(
                          context,
                          ref,
                        );
                      },
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: AppSpacing.lg,
                ),

                // -------------------------------------------------------------
                // CUSTOMER INFO
                // -------------------------------------------------------------

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppAvatar(
                      initials: customer.avatarInitials,
                      size: AppAvatarSize.xl,
                    ),
                    SizedBox(
                      width: AppSpacing.md,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            customer.name,
                            style: AppTypography.h2(
                              Colors.white,
                            ),
                          ),
                          Text(
                            customer.phone,
                            style: AppTypography.bodySmall(
                              Colors.white.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: AppSpacing.xxs,
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: <Widget>[
                              for (final String tag in tags.take(2))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusPill,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: AppTypography.caption(
                                      Colors.white,
                                    ).copyWith(
                                      fontSize: 10.sp,
                                      fontWeight: AppTypography.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: AppSpacing.lg,
                ),

                // -------------------------------------------------------------
                // STATISTICS
                // -------------------------------------------------------------

                _buildHeaderStats(
                  summaryAsync,
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.card,
            child: Row(
              children: List<Widget>.generate(_tabs.length, (int i) {
                final bool active = tab == i;
                return Expanded(
                  child: InkWell(
                    onTap: () => onTabChanged(i),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: active
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 2))),
                      child: Text(_tabs[i],
                          textAlign: TextAlign.center,
                          style: AppTypography.caption(active
                                  ? AppColors.primary
                                  : AppColors.mutedForeground)
                              .copyWith(fontWeight: AppTypography.bold)),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
              children: <Widget>[_buildTab(context, ref)],
            ),
          ),
        ],
      ),
    );
  }
  // ===========================================================================
  // HEADER STATS
  // ===========================================================================

  Widget _buildHeaderStats(
    AsyncValue<CustomerAppointmentSummary> summaryAsync,
  ) {
    return summaryAsync.when(
      // -----------------------------------------------------------------------
      // LOADING
      // -----------------------------------------------------------------------

      loading: () {
        return Row(
          children: <Widget>[
            Expanded(
              child: _HeaderStat(
                label: 'Visits',
                value: '...',
              ),
            ),
            SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: _HeaderStat(
                label: 'Spent',
                value: '...',
              ),
            ),
            SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: _HeaderStat(
                label: 'Points',
                value: '${customer.points}',
              ),
            ),
          ],
        );
      },

      // -----------------------------------------------------------------------
      // ERROR
      // -----------------------------------------------------------------------

      error: (
        Object error,
        StackTrace stackTrace,
      ) {
        return Row(
          children: <Widget>[
            Expanded(
              child: _HeaderStat(
                label: 'Visits',
                value: '0',
              ),
            ),
            SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: _HeaderStat(
                label: 'Spent',
                value: '₹0',
              ),
            ),
            SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: _HeaderStat(
                label: 'Points',
                value: '${customer.points}',
              ),
            ),
          ],
        );
      },

      // -----------------------------------------------------------------------
      // DATA
      // -----------------------------------------------------------------------

      data: (
        CustomerAppointmentSummary summary,
      ) {
        return Row(
          children: <Widget>[
            Expanded(
              child: _HeaderStat(
                label: 'Visits',
                value: '${summary.totalAppointments}',
              ),
            ),
            SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: _HeaderStat(
                label: 'Spent',
                value: '₹${(summary.totalAmount / 1000).toStringAsFixed(1)}K',
              ),
            ),
            SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: _HeaderStat(
                label: 'Points',
                value: '${customer.points}',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab(BuildContext context, WidgetRef ref) {
    switch (tab) {
      case 0:
        return Column(
          children: <Widget>[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('CONTACT INFO',
                      style: AppTypography.caption(AppColors.mutedForeground)
                          .copyWith(letterSpacing: 1)),
                  SizedBox(height: AppSpacing.sm),
                  _InfoRow(icon: Icons.phone_outlined, text: customer.phone),
                  if (customer.email.isNotEmpty)
                    _InfoRow(icon: Icons.mail_outline, text: customer.email),
                  if ((customer.birthday ?? '').isNotEmpty)
                    _InfoRow(
                        icon: Icons.card_giftcard_outlined,
                        text: '${customer.birthday} · Birthday'),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(customer.membership ?? 'No Membership',
                            style: AppTypography.label(AppColors.foreground)
                                .copyWith(fontWeight: AppTypography.bold)),
                        Text('${customer.points} loyalty points',
                            style: AppTypography.caption(
                                AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            AppButton(
                label: 'Book Appointment',
                icon: Icons.calendar_today,
                onPressed: onBookAppointment),
          ],
        );
      case 1:
        if (visits.isEmpty) {
          return const EmptyWidget(
              icon: Icons.history,
              title: 'No visits yet',
              message: 'This customer has no appointment history.');
        }
        return Column(
          children: <Widget>[
            for (final Appointment v in visits)
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(v.services.replaceAll(',', ', '),
                                style: AppTypography.label(AppColors.foreground)
                                    .copyWith(fontWeight: AppTypography.bold)),
                            Text('${v.date} · ${v.time}',
                                style: AppTypography.caption(
                                    AppColors.mutedForeground)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text('₹${v.amount}',
                              style: AppTypography.label(AppColors.primary)
                                  .copyWith(fontWeight: AppTypography.bold)),
                          StatusPill(status: statusFromString(v.status)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      case 2:
      default:
        return _NotesEditor(customer: customer);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Customer?',
      message:
          'This will permanently remove ${customer.name} and cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed) {
      await ref.read(customersDaoProvider).deleteCustomer(customer.id);
      onBack?.call();
    }
  }
}

class _NotesEditor extends ConsumerStatefulWidget {
  const _NotesEditor({required this.customer});

  final Customer customer;

  @override
  ConsumerState<_NotesEditor> createState() => _NotesEditorState();
}

class _NotesEditorState extends ConsumerState<_NotesEditor> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.customer.notes);
  bool _dirty = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final CustomersDao db = ref.read(customersDaoProvider);
    await db.updateCustomer(
        widget.customer.copyWith(notes: _controller.text.trim()));
    setState(() => _dirty = false);
    if (mounted)
      AppSnackBar.show(context,
          message: 'Notes saved.', type: AppSnackBarType.success);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('NOTES',
              style: AppTypography.caption(AppColors.mutedForeground)
                  .copyWith(letterSpacing: 1)),
          SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            maxLines: 5,
            onChanged: (_) => setState(() => _dirty = true),
            style: AppTypography.bodyMedium(AppColors.foreground),
            decoration: const InputDecoration(
                hintText: 'Allergies, preferences, special notes...'),
          ),
          if (_dirty) ...<Widget>[
            SizedBox(height: AppSpacing.sm),
            AppButton(
                label: 'Save Notes',
                size: AppButtonSize.medium,
                onPressed: _save),
          ],
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
      child: Column(
        children: <Widget>[
          Text(value,
              style: AppTypography.label(Colors.white)
                  .copyWith(fontWeight: AppTypography.bold, fontSize: 16.sp)),
          Text(label,
              style:
                  AppTypography.caption(Colors.white.withValues(alpha: 0.65))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.primary),
          SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(text,
                  style: AppTypography.bodySmall(AppColors.foreground))),
        ],
      ),
    );
  }
}
