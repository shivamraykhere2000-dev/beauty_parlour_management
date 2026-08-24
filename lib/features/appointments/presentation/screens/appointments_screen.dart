import 'package:beauty_parlour_management/core/database/daos/appointments_dao.dart';
import 'package:beauty_parlour_management/core/providers/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart'
    show statusFromString;

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen(
      {super.key, this.onBookAppointment, this.onBillAppointment});

  final VoidCallback? onBookAppointment;
  final ValueChanged<int>? onBillAppointment;

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  late DateTime _selectedDate = DateTime.now();
  late DateTime _visibleMonth =
      DateTime(_selectedDate.year, _selectedDate.month);

  String get _dateKey => _selectedDate.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    final AppointmentsDao db = ref.watch(appointmentsDaoProvider);
    final AsyncValue<List<Appointment>> apptsAsync =
        ref.watch(appointmentsForDateProvider(_dateKey));
    final AsyncValue<List<Appointment>> allApptsAsync =
        ref.watch(allAppointmentsProvider);
    final bool isToday = _isSameDay(_selectedDate, DateTime.now());

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Appointments', style: AppTypography.h2(Colors.white)),
                InkWell(
                  onTap: widget.onBookAppointment,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
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
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: AppSpacing.xxxl),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: AppCard(
                    child: allApptsAsync.maybeWhen(
                      data: (List<Appointment> all) => _Calendar(
                        visibleMonth: _visibleMonth,
                        selectedDate: _selectedDate,
                        datesWithAppointments:
                            all.map((Appointment a) => a.date).toSet(),
                        onPrevMonth: () => setState(() => _visibleMonth =
                            DateTime(
                                _visibleMonth.year, _visibleMonth.month - 1)),
                        onNextMonth: () => setState(() => _visibleMonth =
                            DateTime(
                                _visibleMonth.year, _visibleMonth.month + 1)),
                        onSelectDate: (DateTime d) =>
                            setState(() => _selectedDate = d),
                      ),
                      orElse: () =>
                          const SizedBox(height: 200, child: LoadingWidget()),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      apptsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (List<Appointment> list) => Text(
                          '${isToday ? 'Today' : '${_selectedDate.day}/${_selectedDate.month}'} · ${list.length} appointments',
                          style: AppTypography.h3(AppColors.foreground)
                              .copyWith(fontSize: 14.sp),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      apptsAsync.when(
                        loading: () => const LoadingWidget(),
                        error: (Object e, _) => AppErrorWidget(message: '$e'),
                        data: (List<Appointment> list) {
                          if (list.isEmpty) {
                            return const EmptyWidget(
                                icon: Icons.event_busy_outlined,
                                title: 'No appointments',
                                message: 'Nothing booked for this day.');
                          }
                          return Column(
                            children: <Widget>[
                              for (final Appointment apt in list) ...<Widget>[
                                _AppointmentCard(
                                  appointment: apt,
                                  onBill: () async {
                                    // Clicking Bill completes the appointment first,
                                    // then opens the final billing step.
                                    if (apt.status != 'completed') {
                                      await db.updateAppointment(
                                        apt.copyWith(status: 'completed'),
                                      );
                                    }

                                    if (!context.mounted) {
                                      return;
                                    }

                                    widget.onBillAppointment?.call(apt.id);
                                  },
                                  onMarkCompleted: apt.status == 'confirmed' ||
                                          apt.status == 'pending'
                                      ? () => db.updateAppointment(
                                          apt.copyWith(status: 'completed'))
                                      : null,
                                  onCancel: apt.status != 'cancelled' &&
                                          apt.status != 'completed'
                                      ? () => db.updateAppointment(
                                          apt.copyWith(status: 'cancelled'))
                                      : null,
                                ),
                                SizedBox(height: AppSpacing.sm),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.visibleMonth,
    required this.selectedDate,
    required this.datesWithAppointments,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final Set<String> datesWithAppointments;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  static const List<String> _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  Widget build(BuildContext context) {
    final DateTime firstOfMonth =
        DateTime(visibleMonth.year, visibleMonth.month);
    final int daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final int leadingBlanks = firstOfMonth.weekday % 7;
    final DateTime today = DateTime.now();

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            InkWell(
                onTap: onPrevMonth,
                child: const _CalNavIcon(icon: Icons.chevron_left)),
            Text('${_monthNames[visibleMonth.month - 1]} ${visibleMonth.year}',
                style: AppTypography.label(AppColors.foreground)
                    .copyWith(fontWeight: AppTypography.bold)),
            InkWell(
                onTap: onNextMonth,
                child: const _CalNavIcon(icon: Icons.chevron_right)),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Row(children: <Widget>[
          for (final String d in <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'])
            Expanded(
                child: Center(
                    child: Text(d,
                        style: AppTypography.caption(AppColors.mutedForeground)
                            .copyWith(fontWeight: AppTypography.bold))))
        ]),
        SizedBox(height: AppSpacing.xxs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leadingBlanks + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7),
          itemBuilder: (BuildContext context, int index) {
            if (index < leadingBlanks) return const SizedBox.shrink();
            final int day = index - leadingBlanks + 1;
            final DateTime date =
                DateTime(visibleMonth.year, visibleMonth.month, day);
            final String key = date.toIso8601String().substring(0, 10);
            final bool selected = _isSameDay(date, selectedDate);
            final bool isToday = _isSameDay(date, today);
            final bool hasDot =
                datesWithAppointments.contains(key) && !selected;
            return InkWell(
              onTap: () => onSelectDate(date),
              child: Center(
                child: Container(
                  width: 32.r,
                  height: 32.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.primaryGradient : null,
                    shape: BoxShape.circle,
                    border: !selected && isToday
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Text('$day',
                          style: AppTypography.caption(selected
                                  ? Colors.white
                                  : (isToday
                                      ? AppColors.primary
                                      : AppColors.foreground))
                              .copyWith(fontWeight: AppTypography.semiBold)),
                      if (hasDot)
                        Positioned(
                            bottom: 2,
                            child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle))),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _CalNavIcon extends StatelessWidget {
  const _CalNavIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28.r,
      height: 28.r,
      decoration:
          const BoxDecoration(color: Color(0xFFFFF0F4), shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: AppColors.primary),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard(
      {required this.appointment,
      this.onBill,
      this.onMarkCompleted,
      this.onCancel});

  final Appointment appointment;
  final VoidCallback? onBill;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 48.w,
                child: Column(
                  children: <Widget>[
                    Text(appointment.time,
                        style: AppTypography.caption(AppColors.primary)
                            .copyWith(fontWeight: AppTypography.bold)),
                    Text('${appointment.durationMinutes}m',
                        style:
                            AppTypography.caption(AppColors.mutedForeground)),
                  ],
                ),
              ),
              Container(width: 1, height: 40.h, color: AppColors.border),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(appointment.customerName,
                        style: AppTypography.label(AppColors.foreground)
                            .copyWith(fontWeight: AppTypography.bold)),
                    Text(appointment.services.replaceAll(',', ', '),
                        style: AppTypography.caption(const Color(0xFF6B4848))),
                    Text('₹${appointment.amount}',
                        style: AppTypography.caption(AppColors.primary)
                            .copyWith(fontWeight: AppTypography.bold)),
                  ],
                ),
              ),
              StatusPill(status: statusFromString(appointment.status)),
            ],
          ),
          if (onBill != null ||
              onMarkCompleted != null ||
              onCancel != null) ...<Widget>[
            SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                if (onMarkCompleted != null)
                  Expanded(
                      child: OutlinedButton(
                          onPressed: onMarkCompleted,
                          child: const Text('Mark Done'))),
                if (onMarkCompleted != null && onBill != null)
                  SizedBox(width: AppSpacing.xs),
                if (onBill != null)
                  Expanded(
                      child: AppButton(
                          label: 'Bill',
                          size: AppButtonSize.small,
                          onPressed: onBill)),
                if (onCancel != null) ...<Widget>[
                  SizedBox(width: AppSpacing.xs),
                  IconButton(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.destructive)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
