import 'package:beauty_parlour_management/core/database/daos/appointments_dao.dart';
import 'package:beauty_parlour_management/core/providers/path_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key, this.onBack, this.onConfirmed});

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
  String _time = '10:00 AM';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _saving = false;

  static const List<String> _slots = <String>[
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '05:00 PM'
  ];

  int get _total => _services.fold<int>(0, (int s, Service sv) => s + sv.price);
  int get _duration =>
      _services.fold<int>(0, (int s, Service sv) => s + sv.duration);

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_customer == null || _services.isEmpty) return;
    setState(() => _saving = true);
    final AppointmentsDao db = ref.read(appointmentsDaoProvider);
    try {
      await db.addAppointment(AppointmentsCompanion.insert(
        customerId: _customer!.id,
        customerName: _customer!.name,
        services: _services.map((Service s) => s.name).join(','),
        date: _date.toIso8601String().substring(0, 10),
        time: _time,
        durationMinutes: Value<int>(_duration),
        amount: Value<int>(_total),
        status: const Value<String>('confirmed'),
        notes: Value<String>(_notesController.text.trim()),
      ));
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Appointment booked for ${_customer!.name}.',
          type: AppSnackBarType.success);
      widget.onConfirmed?.call();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Book Appointment', onBack: widget.onBack),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            color: AppColors.card,
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
                        shape: BoxShape.circle),
                    child: Text('$s',
                        style: AppTypography.caption(_step >= s
                                ? Colors.white
                                : AppColors.mutedForeground)
                            .copyWith(fontWeight: AppTypography.bold)),
                  ),
                  if (s < 3)
                    Container(
                        width: 32.w,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: _step > s
                            ? AppColors.primary
                            : const Color(0xFFF0E8EC)),
                ],
                const Spacer(),
                Text(
                    <String>[
                      'Select Customer',
                      'Add Services',
                      'Date & Time'
                    ][_step - 1],
                    style: AppTypography.caption(AppColors.mutedForeground)
                        .copyWith(fontWeight: AppTypography.semiBold)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
              children: <Widget>[_buildStep()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final AsyncValue<List<Customer>> customersAsync =
                ref.watch(customersProvider);
            return customersAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, _) => AppErrorWidget(message: '$e'),
              data: (List<Customer> all) {
                final String query = _searchController.text.toLowerCase();
                final List<Customer> filtered = query.isEmpty
                    ? all
                    : all
                        .where((Customer c) =>
                            c.name.toLowerCase().contains(query) ||
                            c.phone.contains(query))
                        .toList();
                return Column(
                  children: <Widget>[
                    AppSearchBar(
                        controller: _searchController,
                        hint: 'Search customer...',
                        onChanged: (_) => setState(() {})),
                    SizedBox(height: AppSpacing.sm),
                    if (filtered.isEmpty)
                      const EmptyWidget(
                          icon: Icons.person_search_outlined,
                          title: 'No customers found',
                          message: 'Try a different search.')
                    else
                      for (final Customer c in filtered)
                        Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _SelectableRow(
                            selected: _customer?.id == c.id,
                            onTap: () => setState(() {
                              _customer = c;
                              _step = 2;
                            }),
                            leading: AppAvatar(
                                initials: c.avatarInitials,
                                size: AppAvatarSize.sm),
                            title: c.name,
                            subtitle: c.phone,
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
          builder: (BuildContext context, WidgetRef ref, _) {
            final AsyncValue<List<Service>> servicesAsync =
                ref.watch(servicesProvider);
            return servicesAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, _) => AppErrorWidget(message: '$e'),
              data: (List<Service> all) {
                return Column(
                  children: <Widget>[
                    for (final Service sv in all)
                      Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xs),
                        child: _ServiceRow(
                          service: sv,
                          selected: _services.any((Service s) => s.id == sv.id),
                          onTap: () => setState(() {
                            if (_services.any((Service s) => s.id == sv.id)) {
                              _services
                                  .removeWhere((Service s) => s.id == sv.id);
                            } else {
                              _services.add(sv);
                            }
                          }),
                        ),
                      ),
                    SizedBox(height: AppSpacing.md),
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: AppButton(
                                label: 'Back',
                                variant: AppButtonVariant.outlined,
                                onPressed: () => setState(() => _step = 1))),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                            child: AppButton(
                                label: 'Next (${_services.length})',
                                onPressed: _services.isEmpty
                                    ? null
                                    : () => setState(() => _step = 3))),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppDatePickerField(
              label: 'DATE',
              selectedDate: _date,
              onDateSelected: (DateTime d) => setState(() => _date = d),
              firstDate: DateTime.now(),
            ),
            SizedBox(height: AppSpacing.md),
            Text('TIME SLOT',
                style: AppTypography.caption(const Color(0xFF6B4848)).copyWith(
                    fontWeight: AppTypography.bold, letterSpacing: 1)),
            SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _slots.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.xs,
                  crossAxisSpacing: AppSpacing.xs,
                  childAspectRatio: 2.4),
              itemBuilder: (BuildContext context, int index) {
                final String t = _slots[index];
                final bool selected = _time == t;
                return InkWell(
                  onTap: () => setState(() => _time = t),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.primaryGradient : null,
                      color: selected ? null : Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      border:
                          selected ? null : Border.all(color: AppColors.border),
                    ),
                    child: Text(t,
                        style: AppTypography.caption(selected
                                ? Colors.white
                                : const Color(0xFF6B4848))
                            .copyWith(fontWeight: AppTypography.bold)),
                  ),
                );
              },
            ),
            SizedBox(height: AppSpacing.md),
            AppTextField(
                label: 'NOTES',
                hint: 'Special requests...',
                controller: _notesController,
                maxLines: 2),
            SizedBox(height: AppSpacing.md),
            AppCard(
              color: const Color(0xFFFFF5F7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Booking Summary',
                      style: AppTypography.label(AppColors.primary)
                          .copyWith(fontWeight: AppTypography.bold)),
                  SizedBox(height: AppSpacing.xs),
                  Text('👤 ${_customer?.name ?? ''}',
                      style: AppTypography.bodySmall(const Color(0xFF6B4848))),
                  Text('📅 ${_date.day}/${_date.month}/${_date.year} at $_time',
                      style: AppTypography.bodySmall(const Color(0xFF6B4848))),
                  Text('✂️ ${_services.map((Service s) => s.name).join(', ')}',
                      style: AppTypography.bodySmall(const Color(0xFF6B4848))),
                  Text('Total: ₹$_total',
                      style: AppTypography.label(AppColors.primary)
                          .copyWith(fontWeight: AppTypography.bold)),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                    child: AppButton(
                        label: 'Back',
                        variant: AppButtonVariant.outlined,
                        onPressed: () => setState(() => _step = 2))),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: AppButton(
                        label: 'Confirm',
                        onPressed: _saving ? null : _confirm,
                        isLoading: _saving)),
              ],
            ),
          ],
        );
    }
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow(
      {required this.selected,
      required this.onTap,
      required this.leading,
      required this.title,
      required this.subtitle});

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF5F7) : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            leading,
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: AppTypography.label(AppColors.foreground)
                          .copyWith(fontWeight: AppTypography.semiBold)),
                  Text(subtitle,
                      style: AppTypography.caption(AppColors.mutedForeground)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow(
      {required this.service, required this.selected, required this.onTap});

  final Service service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF5F7) : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
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
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFDEC8CC),
                      width: 2)),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(service.name,
                      style: AppTypography.label(AppColors.foreground)
                          .copyWith(fontWeight: AppTypography.semiBold)),
                  Text('${service.duration} min · ${service.category}',
                      style: AppTypography.caption(AppColors.mutedForeground)),
                ],
              ),
            ),
            Text('₹${service.price}',
                style: AppTypography.label(AppColors.primary)
                    .copyWith(fontWeight: AppTypography.bold)),
          ],
        ),
      ),
    );
  }
}
