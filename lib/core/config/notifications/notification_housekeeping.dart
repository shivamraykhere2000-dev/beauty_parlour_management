import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_providers.dart';

final notificationHousekeepingProvider = FutureProvider<void>((ref) async {
  final dao = ref.read(appNotificationsDaoProvider);

  await dao.deleteExpiredNotifications();

  ref.invalidate(notificationsProvider);
  ref.invalidate(unreadNotificationsProvider);
  ref.invalidate(unreadNotificationCountProvider);
});
