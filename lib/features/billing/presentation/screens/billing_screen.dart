import 'dart:io';

import 'package:beauty_parlour_management/core/database/daos/appointments_dao.dart';
import 'package:beauty_parlour_management/core/database/daos/customers_dao.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/services/pdf_invoice_service.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// Generates and collects payment for a bill — supports multiple
/// services per bill.
///
/// If [appointmentId] is provided, the appointment is loaded and
/// completed after payment collection.
///
/// If [appointmentId] is null, the owner selects a customer and
/// services manually and a completed appointment is created.
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({
    super.key,
    this.appointmentId,
    this.onBack,
    this.onCollected,
  });

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
  bool _sendingWhatsApp = false;

  Customer? _adHocCustomer;

  final List<Service> _adHocServices = <Service>[];

  // Services attached to an existing appointment. These can be edited
  // from the final billing step before payment is collected.
  final List<Service> _appointmentServices = <Service>[];

  bool _pickingServices = false;
  bool _appointmentServicesInitialized = false;

  List<Service> get _selectedServices =>
      widget.appointmentId != null ? _appointmentServices : _adHocServices;

  final TextEditingController _customerSearchController =
      TextEditingController();

  String _customerSearchQuery = '';

  @override
  void dispose() {
    _customerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // EXISTING APPOINTMENT BILLING
    // ============================================================
    if (widget.appointmentId != null) {
      final AsyncValue<List<Appointment>> apptsAsync =
          ref.watch(allAppointmentsProvider);
      final AsyncValue<List<Service>> servicesAsync =
          ref.watch(servicesProvider);

      return apptsAsync.when(
        loading: () => const Scaffold(
          body: LoadingWidget(),
        ),
        error: (Object e, _) => Scaffold(
          body: AppErrorWidget(
            message: '$e',
          ),
        ),
        data: (List<Appointment> all) {
          final Appointment? appt = all
              .where(
                (Appointment a) => a.id == widget.appointmentId,
              )
              .firstOrNull;

          if (appt == null) {
            return Scaffold(
              appBar: AppTopBar(
                title: 'Invoice',
                onBack: widget.onBack,
              ),
              body: const EmptyWidget(
                icon: Icons.receipt_long_outlined,
                title: 'Appointment not found',
                message: '',
              ),
            );
          }

          return servicesAsync.when(
            loading: () => const Scaffold(
              body: LoadingWidget(),
            ),
            error: (Object e, _) => Scaffold(
              body: AppErrorWidget(
                message: '$e',
              ),
            ),
            data: (List<Service> allServices) {
              // Initialize the appointment's services only once. After that,
              // Add/Remove changes are kept in local state until collection.
              if (!_appointmentServicesInitialized) {
                final List<String> appointmentServiceNames = appt.services
                    .split(',')
                    .map((String s) => s.trim())
                    .where((String s) => s.isNotEmpty)
                    .toList();

                _appointmentServices
                  ..clear()
                  ..addAll(
                    allServices.where(
                      (Service service) =>
                          appointmentServiceNames.contains(service.name),
                    ),
                  );

                _appointmentServicesInitialized = true;
              }

              final String customerPhone =
                  ref.watch(customersProvider).maybeWhen(
                        data: (List<Customer> customers) {
                          return customers
                                  .where(
                                    (Customer c) => c.id == appt.customerId,
                                  )
                                  .firstOrNull
                                  ?.phone ??
                              '';
                        },
                        orElse: () => '',
                      );

              // While the user is choosing services, show the service picker.
              if (_pickingServices) {
                return _buildServicePicker(
                  allServices: allServices,
                  title: 'Edit Services',
                  onBack: () {
                    setState(() {
                      _pickingServices = false;
                    });
                  },
                );
              }

              final List<InvoiceLineItem> lineItems = <InvoiceLineItem>[
                for (final Service service in _appointmentServices)
                  InvoiceLineItem(
                    name: service.name,
                    price: service.price,
                  ),
              ];

              final now = DateTime.now();
              final dateLabel = '${now.year}-'
                  '${now.month.toString().padLeft(2, '0')}-'
                  '${now.day.toString().padLeft(2, '0')}';
              final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
              final amPm = now.hour >= 12 ? 'PM' : 'AM';

              final timeLabel = '${hour.toString().padLeft(2, '0')}:'
                  '${now.minute.toString().padLeft(2, '0')} $amPm';

              return _buildScaffold(
                customerName: appt.customerName,
                customerPhone: customerPhone,
                dateTimeLabel: '${appt.date} · ${appt.time}',
                lineItems: lineItems,
                onCollect: () => _collectForAppointment(appt),
                onAddMore: () {
                  setState(() {
                    _pickingServices = true;
                  });
                },
                onRemoveItem: (int index) {
                  if (index < 0 || index >= _appointmentServices.length) {
                    return;
                  }

                  setState(() {
                    _appointmentServices.removeAt(index);
                  });
                },
                onSendWhatsApp: () => _finalizeAndSendWhatsApp(
                  onFinalize: () => _collectForAppointment(appt),
                  customerName: appt.customerName,
                  customerPhone: customerPhone,
                  dateTimeLabel: '$dateLabel · $timeLabel',
                  lineItems: lineItems,
                ),
              );
            },
          );
        },
      );
    }

    // ============================================================
    // AD-HOC BILLING - SELECT CUSTOMER
    // ============================================================
    if (_adHocCustomer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(
          title: 'Generate Invoice',
          onBack: widget.onBack,
        ),
        body: Consumer(
          builder: (
            BuildContext context,
            WidgetRef ref,
            Widget? child,
          ) {
            final AsyncValue<List<Customer>> customersAsync =
                ref.watch(customersProvider);

            return customersAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, _) => AppErrorWidget(
                message: '$e',
              ),
              data: (List<Customer> customers) {
                final String query = _customerSearchQuery.trim().toLowerCase();

                final List<Customer> filteredCustomers = query.isEmpty
                    ? customers
                    : customers.where(
                        (Customer customer) {
                          final String name = customer.name.toLowerCase();

                          final String phone = customer.phone.toLowerCase();

                          return name.contains(query) || phone.contains(query);
                        },
                      ).toList();

                return ListView(
                  padding: EdgeInsets.all(
                    AppSpacing.md,
                  ),
                  children: <Widget>[
                    Text(
                      'Select Customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3(
                        AppColors.foreground,
                      ).copyWith(
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(
                      height: AppSpacing.sm,
                    ),
                    AppSearchBar(
                      controller: _customerSearchController,
                      hint: 'Search customer or phone',
                      onChanged: (String value) {
                        setState(() {
                          _customerSearchQuery = value;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _customerSearchQuery = '';
                        });
                      },
                    ),
                    SizedBox(
                      height: AppSpacing.sm,
                    ),
                    if (filteredCustomers.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.xxl,
                        ),
                        child: EmptyWidget(
                          icon: Icons.person_search_outlined,
                          title: 'No customers found',
                          message: query.isEmpty
                              ? 'No customers are available.'
                              : 'Try another name or phone number.',
                        ),
                      )
                    else
                      for (final Customer customer in filteredCustomers)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: AppSpacing.xs,
                          ),
                          child: AppCard(
                            onTap: () {
                              setState(() {
                                _adHocCustomer = customer;
                                _pickingServices = true;
                              });
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                AppAvatar(
                                  initials: customer.avatarInitials,
                                  size: AppAvatarSize.sm,
                                ),
                                SizedBox(
                                  width: AppSpacing.sm,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        customer.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.label(
                                          AppColors.foreground,
                                        ).copyWith(
                                          fontWeight: AppTypography.bold,
                                        ),
                                      ),
                                      if (customer.phone.trim().isNotEmpty)
                                        Text(
                                          customer.phone,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.caption(
                                            AppColors.mutedForeground,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: AppSpacing.xs,
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFFC9B0B8),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                );
              },
            );
          },
        ),
      );
    }

    // ============================================================
    // SERVICES
    // ============================================================
    return Consumer(
      builder: (
        BuildContext context,
        WidgetRef ref,
        Widget? child,
      ) {
        final AsyncValue<List<Service>> servicesAsync =
            ref.watch(servicesProvider);

        return servicesAsync.when(
          loading: () => const Scaffold(
            body: LoadingWidget(),
          ),
          error: (Object e, _) => Scaffold(
            body: AppErrorWidget(
              message: '$e',
            ),
          ),
          data: (List<Service> allServices) {
            // ========================================================
            // PICK SERVICES
            // ========================================================
            if (_pickingServices) {
              return _buildServicePicker(
                allServices: allServices,
                title: 'Add Services',
                onBack: () {
                  setState(() {
                    if (_adHocServices.isEmpty) {
                      _adHocCustomer = null;
                      _pickingServices = false;
                    } else {
                      _pickingServices = false;
                    }
                  });
                },
              );
            }

            // ========================================================
            // INVOICE
            // ========================================================
            final Customer customer = _adHocCustomer!;

            final List<InvoiceLineItem> lineItems = <InvoiceLineItem>[
              for (final Service service in _adHocServices)
                InvoiceLineItem(
                  name: service.name,
                  price: service.price,
                ),
            ];

            final String dateTimeLabel = DateTime.now()
                .toIso8601String()
                .substring(0, 16)
                .replaceFirst('T', ' · ');

            return _buildScaffold(
              customerName: customer.name,
              customerPhone: customer.phone,
              dateTimeLabel: dateTimeLabel,
              lineItems: lineItems,
              onCollect: () => _collectAndSendThankYou(
                onCollect: _collectAdHoc,
                customerName: customer.name,
                customerPhone: customer.phone,
              ),
              onAddMore: () {
                setState(() {
                  _pickingServices = true;
                });
              },
              onRemoveItem: (int index) {
                setState(() {
                  _adHocServices.removeAt(index);
                });
              },
              onSendWhatsApp: () => _finalizeAndSendWhatsApp(
                onFinalize: _collectAdHoc,
                customerName: customer.name,
                customerPhone: customer.phone,
                dateTimeLabel: dateTimeLabel,
                lineItems: lineItems,
              ),
            );
          },
        );
      },
    );
  }

  // ========================================================================
  // SERVICE PICKER
  // ========================================================================

  Widget _buildServicePicker({
    required List<Service> allServices,
    required String title,
    required VoidCallback onBack,
  }) {
    final List<Service> selectedServices = _selectedServices;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: title,
        onBack: onBack,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                Text(
                  'Tap to add/remove — you can pick multiple services.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    AppColors.mutedForeground,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                for (final Service service in allServices) ...<Widget>[
                  _SelectableServiceRow(
                    service: service,
                    selected: selectedServices.any(
                      (Service selectedService) =>
                          selectedService.id == service.id,
                    ),
                    onTap: () {
                      setState(() {
                        final bool alreadySelected = selectedServices.any(
                          (Service selectedService) =>
                              selectedService.id == service.id,
                        );

                        if (alreadySelected) {
                          selectedServices.removeWhere(
                            (Service selectedService) =>
                                selectedService.id == service.id,
                          );
                        } else {
                          selectedServices.add(service);
                        }
                      });
                    },
                  ),
                  SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Continue (${selectedServices.length} selected)',
                onPressed: selectedServices.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _pickingServices = false;
                        });
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // INVOICE SCAFFOLD
  // ========================================================================

  Widget _buildScaffold({
    required String customerName,
    required String customerPhone,
    required String dateTimeLabel,
    required List<InvoiceLineItem> lineItems,
    required VoidCallback onCollect,
    required Future<void> Function() onSendWhatsApp,
    VoidCallback? onAddMore,
    void Function(int index)? onRemoveItem,
  }) {
    final int subtotal = lineItems.fold<int>(
      0,
      (
        int sum,
        InvoiceLineItem item,
      ) =>
          sum + item.price,
    );

    final int discountAmount = (subtotal * _discount / 100).round();

    final int total = subtotal - discountAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Generate Invoice',
        onBack: widget.onBack,
      ),
      body: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final double width = constraints.maxWidth;

          // Narrow devices get vertically stacked buttons.
          final bool isSmallScreen = width < 360;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxxl,
            ),
            children: <Widget>[
              // ==========================================================
              // CUSTOMER CARD
              // ==========================================================

              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    AppAvatar(
                      initials: customerName.isEmpty
                          ? '?'
                          : customerName.substring(0, 1),
                    ),
                    SizedBox(
                      width: AppSpacing.sm,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label(
                              AppColors.foreground,
                            ).copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          SizedBox(
                            height: 2.h,
                          ),
                          Text(
                            dateTimeLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(
                              AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: AppSpacing.sm,
              ),

              // ==========================================================
              // SERVICES CARD
              // ==========================================================

              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(
                        AppSpacing.md,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Services',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                AppColors.foreground,
                              ).copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ),
                          if (onAddMore != null) ...<Widget>[
                            SizedBox(
                              width: AppSpacing.sm,
                            ),
                            InkWell(
                              onTap: onAddMore,
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                width: 28.r,
                                height: 28.r,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF0F4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ======================================================
                    // SERVICE ITEMS
                    // ======================================================

                    for (int i = 0; i < lineItems.length; i++)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            if (onRemoveItem != null) ...<Widget>[
                              InkWell(
                                onTap: () => onRemoveItem(i),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusPill,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.only(
                                    right: 8,
                                  ),
                                  child: Icon(
                                    Icons.remove_circle_outline,
                                    size: 18,
                                    color: AppColors.destructive,
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                lineItems[i].name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall(
                                  AppColors.foreground,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: AppSpacing.sm,
                            ),
                            Text(
                              '₹${lineItems[i].price}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: AppTypography.label(
                                AppColors.primary,
                              ).copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(
                height: AppSpacing.sm,
              ),

              // ==========================================================
              // DISCOUNT CARD
              // ==========================================================

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Discount',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label(
                              AppColors.foreground,
                            ).copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: AppSpacing.sm,
                        ),
                        Text(
                          '$_discount%',
                          maxLines: 1,
                          style: AppTypography.label(
                            AppColors.primary,
                          ).copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: AppSpacing.sm,
                    ),

                    // Responsive discount buttons.
                    LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints constraints,
                      ) {
                        const List<int> discounts = <int>[
                          0,
                          5,
                          10,
                          15,
                          20,
                        ];

                        final double spacing = 4.w;

                        final double itemWidth = (constraints.maxWidth -
                                (spacing * (discounts.length - 1))) /
                            discounts.length;

                        return Row(
                          children: <Widget>[
                            for (int index = 0;
                                index < discounts.length;
                                index++) ...<Widget>[
                              SizedBox(
                                width: itemWidth,
                                child: _DiscountButton(
                                  value: discounts[index],
                                  selected: _discount == discounts[index],
                                  onTap: () {
                                    setState(() {
                                      _discount = discounts[index];
                                    });
                                  },
                                ),
                              ),
                              if (index != discounts.length - 1)
                                SizedBox(
                                  width: spacing,
                                ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: AppSpacing.sm,
              ),

              // ==========================================================
              // SUMMARY CARD
              // ==========================================================

              AppCard(
                child: Column(
                  children: <Widget>[
                    _SummaryRow(
                      label: 'Subtotal',
                      value: '₹$subtotal',
                    ),
                    _SummaryRow(
                      label: 'Discount ($_discount%)',
                      value: '-₹$discountAmount',
                      valueColor: AppColors.success,
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        top: AppSpacing.xs,
                      ),
                      padding: EdgeInsets.only(
                        top: AppSpacing.xs,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Total',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                AppColors.foreground,
                              ).copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: AppSpacing.sm,
                          ),
                          Flexible(
                            child: Text(
                              '₹$total',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: AppTypography.h2(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: AppSpacing.sm,
              ),

              // ==========================================================
              // PAYMENT METHOD
              // ==========================================================

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Payment Method',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(
                        AppColors.foreground,
                      ).copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    SizedBox(
                      height: AppSpacing.sm,
                    ),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        for (final String method in <String>[
                          'Cash',
                          'UPI',
                          'Card',
                          'Online',
                        ])
                          InkWell(
                            onTap: () {
                              setState(() {
                                _method = method;
                              });
                            },
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: _method == method
                                    ? AppColors.primaryGradient
                                    : null,
                                color: _method == method ? null : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMd,
                                ),
                                border: _method == method
                                    ? null
                                    : Border.all(
                                        color: AppColors.border,
                                      ),
                              ),
                              child: Text(
                                method,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(
                                  _method == method
                                      ? Colors.white
                                      : const Color(
                                          0xFF6B4848,
                                        ),
                                ).copyWith(
                                  fontWeight: AppTypography.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: AppSpacing.md,
              ),

              // ==========================================================
              // ACTION BUTTONS
              // ==========================================================

              if (isSmallScreen)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppButton(
                      label: 'WhatsApp Bill',
                      icon: Icons.chat_bubble_outline,
                      variant: AppButtonVariant.outlined,
                      isLoading: _sendingWhatsApp,
                      onPressed:
                          (_collecting || _sendingWhatsApp || lineItems.isEmpty)
                              ? null
                              : onSendWhatsApp,
                    ),
                    SizedBox(
                      height: AppSpacing.sm,
                    ),
                    AppButton(
                      label: 'Collect ₹$total',
                      icon: Icons.check,
                      onPressed:
                          (_collecting || _sendingWhatsApp) ? null : onCollect,
                      isLoading: _collecting,
                    ),
                  ],
                )
              else
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppButton(
                        label: 'WhatsApp Bill',
                        icon: Icons.chat_bubble_outline,
                        variant: AppButtonVariant.outlined,
                        isLoading: _sendingWhatsApp,
                        onPressed: (_collecting ||
                                _sendingWhatsApp ||
                                lineItems.isEmpty)
                            ? null
                            : onSendWhatsApp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AppButton(
                        label: 'Collect ₹$total',
                        icon: Icons.check,
                        onPressed: (_collecting || _sendingWhatsApp)
                            ? null
                            : onCollect,
                        isLoading: _collecting,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  // ========================================================================
  // COLLECT APPOINTMENT PAYMENT
  // ========================================================================

  Future<void> _collectForAppointment(
    Appointment appt,
  ) async {
    if (_appointmentServices.isEmpty) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Please keep at least one service on the bill.',
          type: AppSnackBarType.error,
        );
      }
      return;
    }

    setState(() {
      _collecting = true;
    });

    final AppointmentsDao appointmentsDao = ref.read(appointmentsDaoProvider);
    final CustomersDao customersDao = ref.read(customersDaoProvider);

    final int subtotal = _appointmentServices.fold<int>(
      0,
      (
        int sum,
        Service service,
      ) =>
          sum + service.price,
    );

    final int discountedTotal = (subtotal * (100 - _discount) / 100).round();

    final int duration = _appointmentServices.fold<int>(
      0,
      (
        int sum,
        Service service,
      ) =>
          sum + service.duration,
    );

    try {
      await appointmentsDao.updateAppointment(
        appt.copyWith(
          status: 'completed',
          services: _appointmentServices
              .map((Service service) => service.name)
              .join(','),
          amount: discountedTotal,
          durationMinutes: duration,
        ),
      );

      await customersDao.recordVisit(
        appt.customerId,
        amountSpent: discountedTotal,
      );

      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        message: 'Payment collected. Bill marked complete.',
        type: AppSnackBarType.success,
      );

      widget.onCollected?.call();
    } finally {
      if (mounted) {
        setState(() {
          _collecting = false;
        });
      }
    }
  }

  // ========================================================================
  // COLLECT + SEND THANK YOU
  // ========================================================================

  Future<void> _collectAndSendThankYou({
    required Future<void> Function() onCollect,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      await onCollect();

      final String digits = customerPhone.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (digits.isEmpty) {
        if (mounted) {
          AppSnackBar.show(
            context,
            message: 'Payment collected, but customer phone number is missing.',
            type: AppSnackBarType.error,
          );
        }

        return;
      }

      final String withCountryCode = digits.length == 10 ? '91$digits' : digits;

      final String message = '''
Hi $customerName,

Thank you for visiting us! 💕

We hope you enjoyed your experience.

We look forward to seeing you again. 😊

Thank you,
Blossom Beauty Studio
''';

      final Uri uri = Uri.parse(
        'https://wa.me/$withCountryCode'
        '?text=${Uri.encodeComponent(message)}',
      );

      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        AppSnackBar.show(
          context,
          message: 'Could not open WhatsApp.',
          type: AppSnackBarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message:
              'Payment was collected, but WhatsApp could not be opened: $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  // ========================================================================
  // COLLECT AD-HOC BILL
  // ========================================================================

  Future<void> _collectAdHoc() async {
    if (_adHocCustomer == null || _adHocServices.isEmpty) {
      return;
    }

    setState(() {
      _collecting = true;
    });

    final AppointmentsDao appointmentsDao = ref.read(appointmentsDaoProvider);

    final CustomersDao customersDao = ref.read(customersDaoProvider);

    final int subtotal = _adHocServices.fold<int>(
      0,
      (
        int sum,
        Service service,
      ) =>
          sum + service.price,
    );

    final int total = (subtotal * (100 - _discount) / 100).round();

    final int duration = _adHocServices.fold<int>(
      0,
      (
        int sum,
        Service service,
      ) =>
          sum + service.duration,
    );

    try {
      final DateTime now = DateTime.now();

      await appointmentsDao.addAppointment(
        AppointmentsCompanion.insert(
          customerId: _adHocCustomer!.id,
          customerName: _adHocCustomer!.name,
          services: _adHocServices
              .map(
                (Service service) => service.name,
              )
              .join(','),
          date: now.toIso8601String().substring(0, 10),
          time: '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}',
          durationMinutes: Value<int>(
            duration,
          ),
          amount: Value<int>(
            total,
          ),
          status: const Value<String>(
            'completed',
          ),
        ),
      );

      await customersDao.recordVisit(
        _adHocCustomer!.id,
        amountSpent: total,
      );

      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        message: 'Payment collected for ${_adHocCustomer!.name}.',
        type: AppSnackBarType.success,
      );

      widget.onCollected?.call();
    } finally {
      if (mounted) {
        setState(() {
          _collecting = false;
        });
      }
    }
  }

  // ========================================================================
  // FINALIZE + GENERATE PDF + WHATSAPP
  // ========================================================================

  Future<void> _finalizeAndSendWhatsApp({
    required Future<void> Function() onFinalize,
    required String customerName,
    required String customerPhone,
    required String dateTimeLabel,
    required List<InvoiceLineItem> lineItems,
  }) async {
    if (lineItems.isEmpty) {
      return;
    }

    setState(() {
      _sendingWhatsApp = true;
    });

    try {
      // ============================================================
      // 1. FINALIZE / COLLECT
      // ============================================================

      await onFinalize();

      // ============================================================
      // 2. CALCULATE TOTALS
      // ============================================================

      final int subtotal = lineItems.fold<int>(
        0,
        (
          int sum,
          InvoiceLineItem item,
        ) =>
            sum + item.price,
      );

      final int discountAmount = (subtotal * _discount / 100).round();

      final int total = subtotal - discountAmount;

      // ============================================================
      // 3. BUSINESS NAME
      // ============================================================

      final String businessName =
          await ref.read(settingsDaoProvider).getSetting(
                    'business_name',
                  ) ??
              'Blossom Beauty Studio';

      // ============================================================
      // 4. GENERATE PDF
      // ============================================================

      final File pdfFile = await PdfInvoiceService.generateInvoice(
        invoiceNumber:
            DateTime.now().millisecondsSinceEpoch.toString().substring(6),
        businessName: businessName,
        customerName: customerName,
        customerPhone: customerPhone,
        dateTimeLabel: dateTimeLabel,
        lineItems: lineItems,
        subtotal: subtotal,
        discountPercent: _discount,
        discountAmount: discountAmount,
        total: total,
        paymentMethod: _method,
      );

      // ============================================================
      // 5. PHONE NUMBER
      // ============================================================

      final String digits = customerPhone.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (digits.isEmpty) {
        throw Exception(
          'Customer phone number is invalid',
        );
      }

      final String withCountryCode = digits.length == 10 ? '91$digits' : digits;

      // ============================================================
      // 6. WHATSAPP MESSAGE
      // ============================================================

      final String message = 'Hi $customerName, here is your invoice from '
          '$businessName for ₹$total. '
          'Thank you for visiting us! 💅';

      // ============================================================
      // 7. SEND PDF + MESSAGE
      // ============================================================

      await WhatsAppService.sendInvoice(
        pdfPath: pdfFile.path,
        phoneNumber: withCountryCode,
        message: message,
      );

      if (mounted) {
        widget.onCollected?.call();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Could not send invoice: $e',
          type: AppSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingWhatsApp = false;
        });
      }
    }
  }
}

// ============================================================================
// SELECTABLE SERVICE ROW
// ============================================================================

class _SelectableServiceRow extends StatelessWidget {
  const _SelectableServiceRow({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final Service service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        AppDimensions.radiusMd,
      ),
      child: Container(
        padding: EdgeInsets.all(
          AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF5F7) : Colors.white,
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMd,
          ),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // ==========================================================
            // CHECK CIRCLE
            // ==========================================================

            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : const Color(
                          0xFFDEC8CC,
                        ),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),

            SizedBox(
              width: AppSpacing.sm,
            ),

            // ==========================================================
            // SERVICE INFORMATION
            // ==========================================================

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      AppColors.foreground,
                    ).copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  SizedBox(
                    height: 2.h,
                  ),
                  Text(
                    '${service.duration} min · ${service.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: AppSpacing.sm,
            ),

            // ==========================================================
            // PRICE
            // ==========================================================

            Text(
              '₹${service.price}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTypography.label(
                AppColors.primary,
              ).copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DISCOUNT BUTTON
// ============================================================================

class _DiscountButton extends StatelessWidget {
  const _DiscountButton({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        AppDimensions.radiusSm,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF0E8EC),
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusSm,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$value%',
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.clip,
          style: AppTypography.caption(
            selected ? Colors.white : const Color(0xFF6B4848),
          ).copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SUMMARY ROW
// ============================================================================

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 3.h,
      ),
      child: Row(
        children: <Widget>[
          // ==========================================================
          // LABEL
          // ==========================================================

          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(
                AppColors.mutedForeground,
              ),
            ),
          ),

          SizedBox(
            width: AppSpacing.sm,
          ),

          // ==========================================================
          // VALUE
          // ==========================================================

          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTypography.bodySmall(
                valueColor ?? AppColors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
