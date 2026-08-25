import 'package:beauty_parlour_management/core/providers/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/notifications/notification_sync_service.dart';
import '../database/app_database.dart';
import '../database/daos/appnotifications_dao.dart';

final appNotificationsDaoProvider = Provider<AppNotificationsDao>((ref) {
  final AppDatabase database = ref.watch(databaseProvider);

  return AppNotificationsDao(database);
});

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final AppNotificationsDao dao = ref.watch(appNotificationsDaoProvider);

  return dao.watchNotifications();
});

final unreadNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final AppNotificationsDao dao = ref.watch(appNotificationsDaoProvider);

  return dao.watchUnreadNotifications();
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final AppNotificationsDao dao = ref.watch(appNotificationsDaoProvider);

  return dao.watchUnreadNotificationCount();
});

final notificationsPurgeProvider = FutureProvider<void>((ref) async {
  final AppNotificationsDao dao = ref.read(appNotificationsDaoProvider);

  await dao.deleteExpiredNotifications();
});

final autoNotificationsSyncProvider = FutureProvider<void>((ref) async {
  final NotificationSyncService service =
      ref.read(notificationSyncServiceProvider);

  await service.sync();
});
