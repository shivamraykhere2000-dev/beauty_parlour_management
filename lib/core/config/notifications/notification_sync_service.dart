import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../database/daos/appnotifications_dao.dart';
import '../../database/daos/appointments_dao.dart';
import '../../database/daos/inventoryitems_dao.dart';
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
    debugPrint('🔔 Notification sync started');

    final AppNotificationsDao notificationDao =
        ref.read(appNotificationsDaoProvider);

    await notificationDao.deleteExpiredNotifications();

    await _syncBirthdays(notificationDao);

    await _syncFollowUps(notificationDao);

    await _syncLowStock(notificationDao);

    debugPrint('✅ Notification sync completed');
  }

  // =========================================================================
  // 🎂 BIRTHDAY NOTIFICATIONS
  // =========================================================================

  Future<void> _syncBirthdays(
    AppNotificationsDao dao,
  ) async {
    final List<Customer> customers = await ref.read(customersProvider.future);

    debugPrint(
      '🎂 Birthday sync: ${customers.length} customers',
    );

    if (customers.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();

    final String monthDay = '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    debugPrint('🎂 Today month/day: $monthDay');

    for (final Customer customer in customers) {
      final String birthday = customer.birthday ?? '';

      debugPrint(
        '👤 ${customer.name} birthday = $birthday',
      );

      if (birthday.isEmpty) {
        continue;
      }

      if (!birthday.endsWith(monthDay)) {
        continue;
      }

      debugPrint(
        '🎂 Birthday matched: ${customer.name}',
      );

      /*
       * The DAO should prevent duplicate notifications.
       *
       * If your DAO currently does not have duplicate protection,
       * we will add it separately.
       */
      await dao.insertNotification(
        birthdayNotification(
          customer: customer,
          today: now,
        ),
      );

      debugPrint(
        '✅ Birthday notification created for ${customer.name}',
      );
    }
  }

  // =========================================================================
  // 🔄 CUSTOMER FOLLOW-UP NOTIFICATIONS
  // =========================================================================

  Future<void> _syncFollowUps(
    AppNotificationsDao dao,
  ) async {
    final List<Customer> customers = await ref.read(customersProvider.future);

    if (customers.isEmpty) {
      debugPrint('🔄 Follow-up sync: no customers');
      return;
    }

    final AppointmentsDao appointmentsDao = ref.read(appointmentsDaoProvider);

    final List<Appointment> appointments =
        await appointmentsDao.watchAllAppointments().first;

    debugPrint(
      '🔄 Follow-up sync: ${appointments.length} appointments',
    );

    final DateTime now = DateTime.now();

    for (final Customer customer in customers) {
      final List<Appointment> completedAppointments =
          appointments.where((Appointment appointment) {
        if (appointment.status != 'completed') {
          return false;
        }

        return appointment.customerName.trim().toLowerCase() ==
            customer.name.trim().toLowerCase();
      }).toList();

      if (completedAppointments.isEmpty) {
        continue;
      }

      DateTime? lastAppointmentDate;

      for (final Appointment appointment in completedAppointments) {
        final DateTime? appointmentDate = _appointmentDate(appointment);

        if (appointmentDate == null) {
          continue;
        }

        if (lastAppointmentDate == null ||
            appointmentDate.isAfter(lastAppointmentDate)) {
          lastAppointmentDate = appointmentDate;
        }
      }

      if (lastAppointmentDate == null) {
        continue;
      }

      final int daysSinceLastAppointment =
          _differenceInDays(now, lastAppointmentDate);

      debugPrint(
        '🔄 ${customer.name}: '
        'last appointment = $lastAppointmentDate, '
        'days = $daysSinceLastAppointment',
      );

      if (daysSinceLastAppointment < 30) {
        continue;
      }

      debugPrint(
        '🔔 Follow-up required for ${customer.name}',
      );

      await dao.insertNotification(
        followUpNotification(
          customer: customer,
          lastAppointmentDate: lastAppointmentDate,
        ),
      );
    }
  }

  // =========================================================================
  // ⚠️ LOW STOCK NOTIFICATIONS
  // =========================================================================

  Future<void> _syncLowStock(
    AppNotificationsDao dao,
  ) async {
    final InventoryitemsDao inventoryDao = ref.read(inventoryitemsDaoProvider);

    final List<InventoryItem> items = await inventoryDao.watchInventory().first;

    debugPrint(
      '⚠️ Low-stock sync: ${items.length} inventory items',
    );

    for (final InventoryItem item in items) {
      if (item.stock > item.minStock) {
        continue;
      }

      debugPrint(
        '⚠️ Low stock: ${item.name} '
        'stock=${item.stock}, '
        'minimum=${item.minStock}',
      );
      final DateTime now = DateTime.now();

      await dao.insertNotification(
        lowStockNotification(
          item: item,
          today: now,
        ),
      );

      debugPrint(
        '✅ Low-stock notification created for ${item.name}',
      );
    }
  }

  // =========================================================================
  // 📅 APPOINTMENT DATE
  // =========================================================================

  DateTime? _appointmentDate(
    Appointment appointment,
  ) {
    /*
     * Your Appointment table currently appears to have a `date`
     * field based on your existing DAO:
     *
     *     t.date.equals(date)
     *
     * Therefore we use appointment.date here.
     */

    final String date = appointment.date;

    if (date.isEmpty) {
      return null;
    }

    final DateTime? parsedDate = DateTime.tryParse(date);

    return parsedDate;
  }

  // =========================================================================
  // 📅 DATE DIFFERENCE
  // =========================================================================

  int _differenceInDays(
    DateTime current,
    DateTime previous,
  ) {
    final DateTime currentDate = DateTime(
      current.year,
      current.month,
      current.day,
    );

    final DateTime previousDate = DateTime(
      previous.year,
      previous.month,
      previous.day,
    );

    return currentDate.difference(previousDate).inDays;
  }
}
