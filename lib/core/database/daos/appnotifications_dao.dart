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

  Future<int> addNotification(
      {required String type, required String title, required String body}) {
    return into(appNotifications).insert(AppNotificationsCompanion.insert(
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  Future<void> markNotificationRead(int id) async {
    await (update(appNotifications)..where((t) => t.id.equals(id)))
        .write(const AppNotificationsCompanion(read: Value<bool>(true)));
  }

  Future<void> clearAllNotifications() => delete(appNotifications).go();

  /// Deletes notifications older than 15 days. Safe to call on every app
  /// start / dashboard load — it's a no-op when nothing is old enough.
  Future<void> purgeOldNotifications() async {
    final DateTime cutoff = DateTime.now().subtract(const Duration(days: 15));
    final List<AppNotification> all = await select(appNotifications).get();
    final List<int> staleIds = all
        .where((AppNotification n) {
          final DateTime? created = DateTime.tryParse(n.createdAt);
          return created != null && created.isBefore(cutoff);
        })
        .map((AppNotification n) => n.id)
        .toList();
    if (staleIds.isEmpty) return;
    await (delete(appNotifications)..where((t) => t.id.isIn(staleIds))).go();
  }
}
