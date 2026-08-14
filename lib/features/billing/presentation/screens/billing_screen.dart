import 'package:beauty_parlour_management/core/database/daos/appointments_dao.dart';
import 'package:beauty_parlour_management/core/database/daos/customers_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// Generates and collects payment for a bill.
///
/// If [appointmentId] is provided (billing an existing appointment from
/// the schedule), its services/customer are preloaded and, on collection,
/// the appointment is marked `completed` and the customer's visit stats
/// are updated. If null (ad-hoc "Generate Invoice" from the dashboard/FAB),
/// the owner picks a customer and services manually and a new completed
/// appointment record is created directly.
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen(
      {super.key, this.appointmentId, this.onBack, this.onCollected});

  final int? appointmentId;
  final VoidCallback? onBack;
  final VoidCallback? onCollected;

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  int _discount = 0;
  String _method = 'UPI';
  bool _collecting = false;
  Customer? _adHocCustomer;
  final List<Service> _adHocServices = <Service>[];

  @override
  Widget build(BuildContext context) {
    if (widget.appointmentId != null) {
      final AsyncValue<List<Appointment>> apptsAsync =
          ref.watch(allAppointmentsProvider);
      return apptsAsync.when(
        loading: () => const Scaffold(body: LoadingWidget()),
        error: (Object e, _) => Scaffold(body: AppErrorWidget(message: '$e')),
        data: (List<Appointment> all) {
          final Appointment? appt = all
              .where((Appointment a) => a.id == widget.appointmentId)
              .firstOrNull;
          if (appt == null) {
            return Scaffold(
                appBar: AppTopBar(title: 'Invoice', onBack: widget.onBack),
                body: const EmptyWidget(
                    icon: Icons.receipt_long_outlined,
                    title: 'Appointment not found',
                    message: ''));
          }
          final List<String> serviceNames = appt.services
              .split(',')
              .where((String s) => s.trim().isNotEmpty)
              .toList();
          return _buildScaffold(
            customerName: appt.customerName,
            dateTimeLabel: '${appt.date} · ${appt.time}',
            lineItems: serviceNames
                .map((String n) => (
                      n,
                      (appt.amount /
                              (serviceNames.isEmpty ? 1 : serviceNames.length))
                          .round()
                    ))
                .toList(),
            onCollect: () => _collectForAppointment(appt),
          );
        },
      );
    }

    // Ad-hoc billing: pick customer + services.
    if (_adHocCustomer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(title: 'Generate Invoice', onBack: widget.onBack),
        body: Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final AsyncValue<List<Customer>> customersAsync =
                ref.watch(customersProvider);
            return customersAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, _) => AppErrorWidget(message: '$e'),
              data: (List<Customer> customers) => ListView(
                padding: EdgeInsets.all(AppSpacing.md),
                children: <Widget>[
                  Text('Select Customer',
                      style: AppTypography.h3(AppColors.foreground)
                          .copyWith(fontSize: 14.sp)),
                  SizedBox(height: AppSpacing.sm),
                  for (final Customer c in customers)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                      child: AppCard(
                        onTap: () => setState(() => _adHocCustomer = c),
                        child: Row(
                          children: <Widget>[
                            AppAvatar(
                                initials: c.avatarInitials,
                                size: AppAvatarSize.sm),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                                child: Text(c.name,
                                    style: AppTypography.label(
                                            AppColors.foreground)
                                        .copyWith(
                                            fontWeight: AppTypography.bold))),
                            const Icon(Icons.chevron_right,
                                color: Color(0xFFC9B0B8)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Consumer(
      builder: (BuildContext context, WidgetRef ref, _) {
        final AsyncValue<List<Service>> servicesAsync =
            ref.watch(servicesProvider);
        return servicesAsync.when(
          loading: () => const Scaffold(body: LoadingWidget()),
          error: (Object e, _) => Scaffold(body: AppErrorWidget(message: '$e')),
          data: (List<Service> allServices) {
            if (_adHocServices.isEmpty) {
              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppTopBar(
                    title: 'Add Services',
                    onBack: () => setState(() => _adHocCustomer = null)),
                body: ListView(
                  padding: EdgeInsets.all(AppSpacing.md),
                  children: <Widget>[
                    for (final Service sv in allServices)
                      Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xs),
                        child: AppCard(
                          onTap: () => setState(() => _adHocServices.add(sv)),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                  child: Text(sv.name,
                                      style: AppTypography.label(
                                              AppColors.foreground)
                                          .copyWith(
                                              fontWeight:
                                                  AppTypography.semiBold))),
                              Text('₹${sv.price}',
                                  style: AppTypography.label(AppColors.primary)
                                      .copyWith(
                                          fontWeight: AppTypography.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }
            return _buildScaffold(
              customerName: _adHocCustomer!.name,
              dateTimeLabel: DateTime.now()
                  .toIso8601String()
                  .substring(0, 16)
                  .replaceFirst('T', ' · '),
              lineItems:
                  _adHocServices.map((Service s) => (s.name, s.price)).toList(),
              onCollect: () => _collectAdHoc(allServices),
              onAddMore: () => setState(() => _adHocServices.clear()),
            );
          },
        );
      },
    );
  }

  Widget _buildScaffold({
    required String customerName,
    required String dateTimeLabel,
    required List<(String, int)> lineItems,
    required VoidCallback onCollect,
    VoidCallback? onAddMore,
  }) {
    final int subtotal =
        lineItems.fold<int>(0, (int s, (String, int) item) => s + item.$2);
    final int discountAmount = (subtotal * _discount / 100).round();
    final int total = subtotal - discountAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
          title: 'Generate Invoice',
          onBack: widget.onBack,
          trailing:
              const Icon(Icons.share_outlined, color: Colors.white, size: 20)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
        children: <Widget>[
          AppCard(
            child: Row(
              children: <Widget>[
                AppAvatar(
                    initials: customerName.isEmpty
                        ? '?'
                        : customerName.substring(0, 1)),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(customerName,
                          style: AppTypography.label(AppColors.foreground)
                              .copyWith(fontWeight: AppTypography.bold)),
                      Text(dateTimeLabel,
                          style:
                              AppTypography.caption(AppColors.mutedForeground)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Services',
                          style: AppTypography.label(AppColors.foreground)
                              .copyWith(fontWeight: AppTypography.bold)),
                      if (onAddMore != null)
                        InkWell(
                          onTap: onAddMore,
                          child: Container(
                              width: 28.r,
                              height: 28.r,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFFFF0F4),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.add,
                                  size: 16, color: AppColors.primary)),
                        ),
                    ],
                  ),
                ),
                for (final (String, int) item in lineItems)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(
                                color:
                                    AppColors.border.withValues(alpha: 0.6)))),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                            child: Text(item.$1,
                                style: AppTypography.bodySmall(
                                    AppColors.foreground))),
                        Text('₹${item.$2}',
                            style: AppTypography.label(AppColors.primary)
                                .copyWith(fontWeight: AppTypography.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Discount',
                        style: AppTypography.label(AppColors.foreground)
                            .copyWith(fontWeight: AppTypography.bold)),
                    Text('$_discount%',
                        style: AppTypography.label(AppColors.primary)
                            .copyWith(fontWeight: AppTypography.bold)),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    for (final int d in <int>[0, 5, 10, 15, 20]) ...<Widget>[
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _discount = d),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 6.h),
                            decoration: BoxDecoration(
                                color: _discount == d
                                    ? AppColors.primary
                                    : const Color(0xFFF0E8EC),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSm)),
                            alignment: Alignment.center,
                            child: Text('$d%',
                                style: AppTypography.caption(_discount == d
                                        ? Colors.white
                                        : const Color(0xFF6B4848))
                                    .copyWith(fontWeight: AppTypography.bold)),
                          ),
                        ),
                      ),
                      if (d != 20) SizedBox(width: 4.w),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: <Widget>[
                _SummaryRow(label: 'Subtotal', value: '₹$subtotal'),
                _SummaryRow(
                    label: 'Discount ($_discount%)',
                    value: '-₹$discountAmount',
                    valueColor: AppColors.success),
                Container(
                  margin: EdgeInsets.only(top: AppSpacing.xs),
                  padding: EdgeInsets.only(top: AppSpacing.xs),
                  decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Total',
                          style: AppTypography.label(AppColors.foreground)
                              .copyWith(fontWeight: AppTypography.bold)),
                      Text('₹$total',
                          style: AppTypography.h2(AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Payment Method',
                    style: AppTypography.label(AppColors.foreground)
                        .copyWith(fontWeight: AppTypography.bold)),
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    for (final String m in <String>[
                      'Cash',
                      'UPI',
                      'Card',
                      'Online'
                    ])
                      InkWell(
                        onTap: () => setState(() => _method = m),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient:
                                _method == m ? AppColors.primaryGradient : null,
                            color: _method == m ? null : Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                            border: _method == m
                                ? null
                                : Border.all(color: AppColors.border),
                          ),
                          child: Text(m,
                              style: AppTypography.label(_method == m
                                      ? Colors.white
                                      : const Color(0xFF6B4848))
                                  .copyWith(fontWeight: AppTypography.bold)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                  child: AppButton(
                      label: 'WhatsApp Bill',
                      icon: Icons.chat_bubble_outline,
                      variant: AppButtonVariant.outlined,
                      onPressed: () {})),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: AppButton(
                      label: 'Collect ₹$total',
                      icon: Icons.check,
                      onPressed: _collecting ? null : onCollect,
                      isLoading: _collecting)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _collectForAppointment(Appointment appt) async {
    setState(() => _collecting = true);
    final AppointmentsDao appointmentsdao = ref.read(appointmentsDaoProvider);
    final CustomersDao customersdao = ref.read(customersDaoProvider);
    final int discountedTotal = (appt.amount * (100 - _discount) / 100).round();
    try {
      await appointmentsdao.updateAppointment(
          appt.copyWith(status: 'completed', amount: discountedTotal));
      await customersdao.recordVisit(appt.customerId,
          amountSpent: discountedTotal);
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Payment collected. Bill marked complete.',
          type: AppSnackBarType.success);
      widget.onCollected?.call();
    } finally {
      if (mounted) setState(() => _collecting = false);
    }
  }

  Future<void> _collectAdHoc(List<Service> allServices) async {
    if (_adHocCustomer == null || _adHocServices.isEmpty) return;
    setState(() => _collecting = true);
    final AppointmentsDao db = ref.read(appointmentsDaoProvider);
    final CustomersDao customersdao = ref.read(customersDaoProvider);
    final int subtotal =
        _adHocServices.fold<int>(0, (int s, Service sv) => s + sv.price);
    final int total = (subtotal * (100 - _discount) / 100).round();
    final int duration =
        _adHocServices.fold<int>(0, (int s, Service sv) => s + sv.duration);
    try {
      final DateTime now = DateTime.now();
      await db.addAppointment(AppointmentsCompanion.insert(
        customerId: _adHocCustomer!.id,
        customerName: _adHocCustomer!.name,
        services: _adHocServices.map((Service s) => s.name).join(','),
        date: now.toIso8601String().substring(0, 10),
        time:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        durationMinutes: Value<int>(duration),
        amount: Value<int>(total),
        status: const Value<String>('completed'),
      ));
      await customersdao.recordVisit(_adHocCustomer!.id, amountSpent: total);
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Payment collected for ${_adHocCustomer!.name}.',
          type: AppSnackBarType.success);
      widget.onCollected?.call();
    } finally {
      if (mounted) setState(() => _collecting = false);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: AppTypography.bodySmall(AppColors.mutedForeground)),
          Text(value,
              style:
                  AppTypography.bodySmall(valueColor ?? AppColors.foreground)),
        ],
      ),
    );
  }
}
