import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/appNotifications.dart';

part 'appnotifications_dao.g.dart';

@DriftAccessor(tables: [AppNotifications])
class AppNotificationsDao extends DatabaseAccessor<AppDatabase>
    with _$AppNotificationsDaoMixin {
  AppNotificationsDao(super.db);

  Stream<List<AppNotification>> watchNotifications() =>
      (select(appNotifications)
            ..orderBy(<OrderingTerm Function($AppNotificationsTable)>[
              (t) => OrderingTerm.desc(t.id)
            ]))
          .watch();

  // ============================================================
  // WATCH UNREAD NOTIFICATIONS
  // ============================================================

  Stream<List<AppNotification>> watchUnreadNotifications() {
    return (select(appNotifications)
          ..where((tbl) => tbl.isRead.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  // ============================================================
  // UNREAD COUNT
  // ============================================================
  Stream<int> watchUnreadNotificationCount() {
    final query = selectOnly(appNotifications)
      ..addColumns([appNotifications.id.count()])
      ..where(appNotifications.isRead.equals(false));
    return query.map((row) {
      return row.read(appNotifications.id.count()) ?? 0;
    }).watchSingle();
  }

  // ============================================================
  // GET NOTIFICATION BY ID
  // ============================================================

  Future<AppNotification?> getNotificationById(int id) {
    return (select(appNotifications)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  // ============================================================
  // GET BY UNIQUE KEY
  // ============================================================

  Future<AppNotification?> getByUniqueKey(String uniqueKey) {
    return (select(appNotifications)
          ..where((tbl) => tbl.uniqueKey.equals(uniqueKey)))
        .getSingleOrNull();
  }

  // ============================================================
  // INSERT
  // ============================================================

  Future<int> insertNotification(
    AppNotificationsCompanion notification,
  ) {
    return into(appNotifications).insert(
      notification,
      mode: InsertMode.insertOrIgnore,
    );
  }

  // ============================================================
  // MARK AS READ
  // ============================================================

  Future<void> markNotificationRead(int id) async {
    await (update(appNotifications)..where((tbl) => tbl.id.equals(id))).write(
      AppNotificationsCompanion(
        isRead: const Value(true),
        readAt: Value(DateTime.now()),
      ),
    );
  }

  // ============================================================
  // MARK ACTION AS COMPLETED
  // ============================================================

  Future<void> markActionCompleted(int id) async {
    final DateTime now = DateTime.now();

    await (update(appNotifications)..where((tbl) => tbl.id.equals(id))).write(
      AppNotificationsCompanion(
        isRead: const Value(true),
        readAt: Value(now),
        isActionCompleted: const Value(true),
        actionCompletedAt: Value(now),
      ),
    );
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> markAllNotificationsRead() async {
    await update(appNotifications).write(
      AppNotificationsCompanion(
        isRead: const Value(true),
        readAt: Value(DateTime.now()),
      ),
    );
  }

  // ============================================================
  // DELETE ONE
  // ============================================================

  Future<void> deleteNotification(int id) async {
    await (delete(appNotifications)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  Future<void> clearAllNotifications() async {
    await delete(appNotifications).go();
  }

  // ============================================================
  // DELETE EXPIRED
  // ============================================================

  Future<int> deleteExpiredNotifications() async {
    final DateTime now = DateTime.now();

    return (delete(appNotifications)
          ..where(
            (tbl) => tbl.expiresAt.isSmallerThanValue(now),
          ))
        .go();
  }

  // ============================================================
  // DELETE CUSTOMER'S FOLLOW-UP NOTIFICATION
  // ============================================================

  Future<void> deleteCustomerFollowUpNotification(
    int customerId,
  ) async {
    await (delete(appNotifications)
          ..where(
            (tbl) =>
                tbl.customerId.equals(customerId) &
                tbl.type.equals('follow_up'),
          ))
        .go();
  }

  // ============================================================
  // DELETE APPOINTMENT NOTIFICATION
  // ============================================================

  Future<void> deleteAppointmentNotification(
    int appointmentId,
  ) async {
    await (delete(appNotifications)
          ..where(
            (tbl) =>
                tbl.appointmentId.equals(appointmentId) &
                tbl.type.equals('appointment'),
          ))
        .go();
  }

  // ============================================================
  // DELETE LOW STOCK NOTIFICATION
  // ============================================================

  Future<void> deleteLowStockNotification(
    int inventoryItemId,
  ) async {
    await (delete(appNotifications)
          ..where(
            (tbl) =>
                tbl.inventoryItemId.equals(inventoryItemId) &
                tbl.type.equals('low_stock'),
          ))
        .go();
  }
}
