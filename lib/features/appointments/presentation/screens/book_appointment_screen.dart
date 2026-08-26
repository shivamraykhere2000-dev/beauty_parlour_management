import 'package:beauty_parlour_management/core/database/daos/appointments_dao.dart';
import 'package:beauty_parlour_management/core/providers/path_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({
    super.key,
    this.onBack,
    this.onConfirmed,
  });

  final VoidCallback? onBack;
  final VoidCallback? onConfirmed;

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  int _step = 1;

  Customer? _customer;

  final List<Service> _services = <Service>[];

  DateTime _date = DateTime.now();

  // Store time in 24-hour format: HH:mm
  String _time = '10:00';

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _saving = false;

  int get _total => _services.fold<int>(0, (int sum, Service service) {
        return sum + service.price;
      });

  int get _duration => _services.fold<int>(0, (int sum, Service service) {
        return sum + service.duration;
      });

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // TIME PICKER
  // ============================================================

  Future<void> _pickTime() async {
    final List<String> parts = _time.split(':');

    final int hour = int.tryParse(parts[0]) ?? 10;
    final int minute = int.tryParse(parts[1]) ?? 0;

    final TimeOfDay initialTime = TimeOfDay(
      hour: hour,
      minute: minute,
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    // Convert TimeOfDay to HH:mm
    final String formattedTime =
        '${pickedTime.hour.toString().padLeft(2, '0')}:'
        '${pickedTime.minute.toString().padLeft(2, '0')}';

    setState(() {
      _time = formattedTime;
    });
  }

  // ============================================================
  // WHATSAPP
  // ============================================================

  Future<void> _openWhatsApp() async {
    if (_customer == null) {
      return;
    }

    final String customerName = _customer!.name;

    // Phone number comes directly from Customer table.
    String phone = _customer!.phone.trim();

    // Remove spaces, -, brackets etc.
    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If number starts with +, remove it for wa.me.
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    }

    // If your database stores Indian numbers as 10 digits,
    // automatically add India country code.
    if (phone.length == 10) {
      phone = '91$phone';
    }

    final String serviceNames =
        _services.map((Service service) => service.name).join(', ');

    final String appointmentDate = '${_date.day.toString().padLeft(2, '0')}/'
        '${_date.month.toString().padLeft(2, '0')}/'
        '${_date.year}';

    final String notes = _notesController.text.trim();

    final StringBuffer message = StringBuffer();

    message.writeln('Hello $customerName,');
    message.writeln();
    message.writeln(
      'Your appointment has been confirmed successfully. 💇‍♀️',
    );
    message.writeln();
    message.writeln('📅 Date: $appointmentDate');
    message.writeln('⏰ Time: $_time');
    message.writeln('✂️ Services: $serviceNames');
    message.writeln('⏱ Duration: $_formattedDuration');
    message.writeln('💰 Total Amount: ₹$_total');

    if (notes.isNotEmpty) {
      message.writeln('📝 Notes: $notes');
    }

    message.writeln();
    message.writeln('Thank you for choosing our beauty parlour. ❤️');
    message.writeln('We look forward to seeing you!');

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message.toString())}',
    );

    try {
      final bool launched = await launchUrl(
        whatsappUri,
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
      if (!mounted) return;

      AppSnackBar.show(
        context,
        message: 'Could not open WhatsApp.',
        type: AppSnackBarType.error,
      );
    }
  }

  String get _formattedDuration {
    if (_duration < 60) {
      return '$_duration minutes';
    }

    final int hours = _duration ~/ 60;
    final int minutes = _duration % 60;

    if (minutes == 0) {
      return hours == 1 ? '1 hour' : '$hours hours';
    }

    return hours == 1
        ? '1 hour $minutes minutes'
        : '$hours hours $minutes minutes';
  }
  // ============================================================
  // CONFIRM APPOINTMENT
  // ============================================================

  Future<void> _confirm() async {
    if (_customer == null || _services.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final AppointmentsDao db = ref.read(appointmentsDaoProvider);

    try {
      await db.addAppointment(
        AppointmentsCompanion.insert(
          customerId: _customer!.id,
          customerName: _customer!.name,

          services: _services.map((Service service) => service.name).join(','),

          date: _date.toIso8601String().substring(0, 10),

          // Save 24-hour format
          time: _time,

          durationMinutes: Value<int>(_duration),

          amount: Value<int>(_total),

          status: const Value<String>('confirmed'),

          notes: Value<String>(
            _notesController.text.trim(),
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        message: 'Appointment booked for ${_customer!.name}.',
        type: AppSnackBarType.success,
      );

      // Open WhatsApp after appointment is successfully saved.
      await _openWhatsApp();

      widget.onConfirmed?.call();
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        message: 'Failed to book appointment: $e',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Book Appointment',
        onBack: widget.onBack,
      ),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            color: AppColors.card,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                for (int s = 1; s <= 3; s++) ...<Widget>[
                  Container(
                    width: 28.r,
                    height: 28.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: _step >= s ? AppColors.primaryGradient : null,
                      color: _step >= s ? null : const Color(0xFFF0E8EC),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$s',
                      style: AppTypography.caption(
                        _step >= s ? Colors.white : AppColors.mutedForeground,
                      ).copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                  if (s < 3)
                    Container(
                      width: 32.w,
                      height: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      color: _step > s
                          ? AppColors.primary
                          : const Color(0xFFF0E8EC),
                    ),
                ],
                const Spacer(),
                Text(
                  <String>[
                    'Select Customer',
                    'Add Services',
                    'Date & Time',
                  ][_step - 1],
                  style: AppTypography.caption(
                    AppColors.mutedForeground,
                  ).copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              children: <Widget>[
                _buildStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEPS
  // ============================================================

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return Consumer(
          builder: (
            BuildContext context,
            WidgetRef ref,
            Widget? child,
          ) {
            final AsyncValue<List<Customer>> customersAsync =
                ref.watch(customersProvider);

            return customersAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, StackTrace stack) {
                return AppErrorWidget(
                  message: '$e',
                );
              },
              data: (List<Customer> all) {
                final String query = _searchController.text.toLowerCase();

                final List<Customer> filtered = query.isEmpty
                    ? all
                    : all.where((Customer customer) {
                        return customer.name.toLowerCase().contains(query) ||
                            customer.phone.contains(query);
                      }).toList();

                return Column(
                  children: <Widget>[
                    AppSearchBar(
                      controller: _searchController,
                      hint: 'Search customer...',
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    SizedBox(
                      height: AppSpacing.sm,
                    ),
                    if (filtered.isEmpty)
                      const EmptyWidget(
                        icon: Icons.person_search_outlined,
                        title: 'No customers found',
                        message: 'Try a different search.',
                      )
                    else
                      for (final Customer customer in filtered)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: AppSpacing.xs,
                          ),
                          child: _SelectableRow(
                            selected: _customer?.id == customer.id,
                            onTap: () {
                              setState(() {
                                _customer = customer;
                                _step = 2;
                              });
                            },
                            leading: AppAvatar(
                              initials: customer.avatarInitials,
                              size: AppAvatarSize.sm,
                            ),
                            title: customer.name,
                            subtitle: customer.phone,
                          ),
                        ),
                  ],
                );
              },
            );
          },
        );

      case 2:
        return Consumer(
          builder: (
            BuildContext context,
            WidgetRef ref,
            Widget? child,
          ) {
            final AsyncValue<List<Service>> servicesAsync =
                ref.watch(servicesProvider);

            return servicesAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, StackTrace stack) {
                return AppErrorWidget(
                  message: '$e',
                );
              },
              data: (List<Service> all) {
                return Column(
                  children: <Widget>[
                    for (final Service service in all)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: AppSpacing.xs,
                        ),
                        child: _ServiceRow(
                          service: service,
                          selected: _services.any(
                            (Service selectedService) =>
                                selectedService.id == service.id,
                          ),
                          onTap: () {
                            setState(() {
                              final bool alreadySelected = _services.any(
                                (Service selectedService) =>
                                    selectedService.id == service.id,
                              );

                              if (alreadySelected) {
                                _services.removeWhere(
                                  (Service selectedService) =>
                                      selectedService.id == service.id,
                                );
                              } else {
                                _services.add(service);
                              }
                            });
                          },
                        ),
                      ),
                    SizedBox(
                      height: AppSpacing.md,
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppButton(
                            label: 'Back',
                            variant: AppButtonVariant.outlined,
                            onPressed: () {
                              setState(() {
                                _step = 1;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: AppSpacing.sm,
                        ),
                        Expanded(
                          child: AppButton(
                            label: 'Next (${_services.length})',
                            onPressed: _services.isEmpty
                                ? null
                                : () {
                                    setState(() {
                                      _step = 3;
                                    });
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );

      case 3:
      default:
        return _buildDateTimeStep();
    }
  }

  // ============================================================
  // DATE & TIME STEP
  // ============================================================

  Widget _buildDateTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppDatePickerField(
          label: 'DATE',
          selectedDate: _date,
          onDateSelected: (DateTime date) {
            setState(() {
              _date = date;
            });
          },
          firstDate: DateTime.now(),
        ),

        SizedBox(
          height: AppSpacing.md,
        ),

        Text(
          'TIME',
          style: AppTypography.caption(
            const Color(0xFF6B4848),
          ).copyWith(
            fontWeight: AppTypography.bold,
            letterSpacing: 1,
          ),
        ),

        SizedBox(
          height: AppSpacing.sm,
        ),

        // ======================================================
        // 24 HOUR TIME SELECTOR
        // ======================================================

        InkWell(
          onTap: _pickTime,
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMd,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                AppDimensions.radiusMd,
              ),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                ),
                SizedBox(
                  width: AppSpacing.sm,
                ),
                Expanded(
                  child: Text(
                    _time,
                    style: AppTypography.bodySmall(
                      AppColors.foreground,
                    ).copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),

        SizedBox(
          height: AppSpacing.xs,
        ),

        Text(
          'Select appointment time in 24-hour format',
          style: AppTypography.caption(
            AppColors.mutedForeground,
          ),
        ),

        SizedBox(
          height: AppSpacing.md,
        ),

        // ======================================================
        // NOTES
        // ======================================================

        AppTextField(
          label: 'NOTES',
          hint: 'Special requests...',
          controller: _notesController,
          maxLines: 2,
        ),

        SizedBox(
          height: AppSpacing.md,
        ),

        // ======================================================
        // SUMMARY
        // ======================================================

        AppCard(
          color: const Color(0xFFFFF5F7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Booking Summary',
                style: AppTypography.label(
                  AppColors.primary,
                ).copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              SizedBox(
                height: AppSpacing.xs,
              ),
              Text(
                '👤 ${_customer?.name ?? ''}',
                style: AppTypography.bodySmall(
                  const Color(0xFF6B4848),
                ),
              ),
              Text(
                '📞 ${_customer?.phone ?? ''}',
                style: AppTypography.bodySmall(
                  const Color(0xFF6B4848),
                ),
              ),
              Text(
                '📅 ${_date.day.toString().padLeft(2, '0')}/'
                '${_date.month.toString().padLeft(2, '0')}/'
                '${_date.year} at $_time',
                style: AppTypography.bodySmall(
                  const Color(0xFF6B4848),
                ),
              ),
              Text(
                '✂️ ${_services.map((Service service) => service.name).join(', ')}',
                style: AppTypography.bodySmall(
                  const Color(0xFF6B4848),
                ),
              ),
              Text(
                '⏱ $_formattedDuration',
                style: AppTypography.bodySmall(
                  const Color(0xFF6B4848),
                ),
              ),
              Text(
                'Total: ₹$_total',
                style: AppTypography.label(
                  AppColors.primary,
                ).copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: AppSpacing.md,
        ),

        // ======================================================
        // BUTTONS
        // ======================================================

        Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Back',
                variant: AppButtonVariant.outlined,
                onPressed: () {
                  setState(() {
                    _step = 2;
                  });
                },
              ),
            ),
            SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: AppButton(
                label: 'Confirm & WhatsApp',
                onPressed: _saving ? null : _confirm,
                isLoading: _saving,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ================================================================
// CUSTOMER ROW
// ================================================================

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

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
          children: <Widget>[
            leading,
            SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.label(
                      AppColors.foreground,
                    ).copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption(
                      AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SERVICE ROW
// ================================================================

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
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
          children: <Widget>[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFDEC8CC),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    service.name,
                    style: AppTypography.label(
                      AppColors.foreground,
                    ).copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  Text(
                    '${service.duration} min · ${service.category}',
                    style: AppTypography.caption(
                      AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${service.price}',
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
