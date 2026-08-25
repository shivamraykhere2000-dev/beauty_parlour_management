import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../database/daos/appnotifications_dao.dart';
import '../../providers/notification_providers.dart';
import '../../providers/path_provider.dart' hide appNotificationsDaoProvider;
import 'notification_helper.dart';

final notificationSyncServiceProvider =
    Provider<NotificationSyncService>((ref) {
  return NotificationSyncService(ref);
});

class NotificationSyncService {
  NotificationSyncService(this.ref);

  final Ref ref;

  Future<void> sync() async {
    final AppNotificationsDao dao = ref.read(appNotificationsDaoProvider);

    await dao.deleteExpiredNotifications();

    await _syncBirthdays(dao);

    await _syncFollowUps(dao);
  }

  Future<void> _syncBirthdays(
    AppNotificationsDao dao,
  ) async {
    final List<Customer> customers = ref.read(customersProvider).maybeWhen(
          data: (List<Customer> list) => list,
          orElse: () => const <Customer>[],
        );

    if (customers.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();

    final String monthDay = '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    for (final Customer customer in customers) {
      final String birthday = customer.birthday ?? '';

      if (birthday.isEmpty) {
        continue;
      }

      if (!birthday.endsWith(monthDay)) {
        continue;
      }

      await dao.insertNotification(
        birthdayNotification(
          customer: customer,
          today: now,
        ),
      );
    }
  }

  Future<void> _syncFollowUps(
    AppNotificationsDao dao,
  ) async {
    final List<Customer> customers = ref.read(customersProvider).maybeWhen(
          data: (List<Customer> list) => list,
          orElse: () => const <Customer>[],
        );

    /*
     * This section intentionally uses the appointment data already
     * exposed by your application.
     *
     * If your existing appointmentsProvider has a different name,
     * replace only that provider below.
     */
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final appointmentsAsync = ref.watch(appointmentsForDateProvider(today));

    final appointments = appointmentsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Appointment>[],
    );

    if (customers.isEmpty || appointments.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();

    for (final Customer customer in customers) {
      final List<Appointment> customerAppointments = appointments.where(
        (Appointment appointment) {
          return appointment.customerName.trim().toLowerCase() ==
              customer.name.trim().toLowerCase();
        },
      ).where(
        (Appointment appointment) {
          return appointment.status == 'completed';
        },
      ).toList();

      if (customerAppointments.isEmpty) {
        continue;
      }

      final List<DateTime> dates = <DateTime>[];

      for (final Appointment appointment in customerAppointments) {
        final DateTime? date = _appointmentDate(appointment);

        if (date != null) {
          dates.add(date);
        }
      }

      if (dates.isEmpty) {
        continue;
      }

      dates.sort();

      final DateTime lastAppointment = dates.last;

      final int daysSinceLastAppointment =
          now.difference(lastAppointment).inDays;

      if (daysSinceLastAppointment < 30) {
        continue;
      }

      await dao.insertNotification(
        followUpNotification(
          customer: customer,
          lastAppointmentDate: lastAppointment,
        ),
      );
    }
  }

  DateTime? _appointmentDate(
    Appointment appointment,
  ) {
    /*
     * IMPORTANT:
     *
     * If your Appointment generated Drift model already has a DateTime
     * field called appointmentDate/date, use it here.
     *
     * Example:
     *
     * return appointment.appointmentDate;
     *
     * The following implementation tries common formats through
     * dynamic access so the notification service remains isolated.
     */

    try {
      final dynamic value = (appointment as dynamic).appointmentDate;

      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value);
      }
    } catch (_) {}

    try {
      final dynamic value = (appointment as dynamic).date;

      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value);
      }
    } catch (_) {}

    return null;
  }
}
