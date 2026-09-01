import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import 'notification_action_types.dart';
import 'notification_types.dart';

AppNotificationsCompanion buildNotification({
  required String type,
  required String title,
  required String body,
  required String uniqueKey,
  String? actionType,
  int? customerId,
  int? appointmentId,
  int? inventoryItemId,
  DateTime? expiresAt,
}) {
  return AppNotificationsCompanion.insert(
    type: type,
    title: title,
    body: body,
    customerId: Value(customerId),
    appointmentId: Value(appointmentId),
    inventoryItemId: Value(inventoryItemId),
    actionType: Value(
      actionType ?? NotificationActionType.none,
    ),
    isRead: const Value(false),
    readAt: const Value.absent(),
    isActionCompleted: const Value(false),
    actionCompletedAt: const Value.absent(),
    createdAt: Value(DateTime.now()),
    expiresAt: Value(expiresAt),
    uniqueKey: uniqueKey,
  );
}

AppNotificationsCompanion birthdayNotification({
  required Customer customer,
  required DateTime today,
}) {
  final String dateKey =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  return buildNotification(
    type: NotificationType.birthday,
    title: customer.name,
    body: 'Today is ${customer.name}\'s birthday 🎂',
    customerId: customer.id,
    actionType: NotificationActionType.whatsapp,
    uniqueKey: 'birthday_${customer.id}_$dateKey',
    expiresAt: DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 30)),
  );
}

AppNotificationsCompanion followUpNotification({
  required Customer customer,
  required DateTime lastAppointmentDate,
}) {
  final String dateKey =
      '${lastAppointmentDate.year}-${lastAppointmentDate.month.toString().padLeft(2, '0')}-${lastAppointmentDate.day.toString().padLeft(2, '0')}';

  return buildNotification(
    type: NotificationType.followUp,
    title: customer.name,
    body: 'No appointment in the last 30 days. Time to follow up.',
    customerId: customer.id,
    actionType: NotificationActionType.whatsapp,
    uniqueKey: 'follow_up_${customer.id}_$dateKey',
    expiresAt: DateTime.now().add(const Duration(days: 30)),
  );
}

AppNotificationsCompanion lowStockNotification({
  required InventoryItem item,
  required DateTime today,
}) {
  final String dateKey =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  return buildNotification(
    type: NotificationType.lowStock,
    title: item.name,
    body: '${item.stock} left (min: ${item.minStock})',
    inventoryItemId: item.id,
    actionType: NotificationActionType.inventory,
    uniqueKey: 'lowStock_${item.id}_$dateKey',
    expiresAt: DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 30)),
  );
}
