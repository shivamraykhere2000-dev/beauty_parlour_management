import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_constants.dart';
import '../database/app_database.dart';
import '../database/daos/appnotifications_dao.dart';
import '../database/daos/customers_dao.dart';
import '../database/daos/inventoryitems_dao.dart';
import '../di/dependency_injection.dart';
import '../services/google_drive_backup_service.dart';

/// The single [AppDatabase] instance, resolved from GetIt.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();

  ref.onDispose(() {
    db.close();
  });

  return db;
});

// this is a provider and this is write for every deos files  then access the deos method

final customersDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);

  return db.customersDao;
});
final appointmentsDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);

  return db.appointmentsDao;
});

final expensesDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);

  return db.expensesDao;
});

final inventoryitemsDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);

  return db.inventoryitemsDao;
});

final servicesDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);

  return db.servicesDao;
});

final settingsDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);

  return db.settingsDao;
});
final whatsappTemplatesDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);

  return db.whatsappTemplatesDao;
});

final appNotificationsDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);

  return db.appNotificationsDao;
});

final Provider<GoogleDriveBackupService> googleDriveBackupServiceProvider =
    Provider<GoogleDriveBackupService>((ref) => GoogleDriveBackupService());

/// Live, always-up-to-date customer list — updates automatically whenever
/// a customer is added, edited or a visit is recorded.
final StreamProvider<List<Customer>> customersProvider =
    StreamProvider<List<Customer>>(
        (ref) => ref.watch(customersDaoProvider).watchCustomers());

/// Live list of every appointment, most recent first.
final StreamProvider<List<Appointment>> allAppointmentsProvider =
    StreamProvider<List<Appointment>>(
        (ref) => ref.watch(appointmentsDaoProvider).watchAllAppointments());

/// Live appointments for one specific day (`YYYY-MM-DD`).
final StreamProviderFamily<List<Appointment>, String>
    appointmentsForDateProvider =
    StreamProvider.family<List<Appointment>, String>(
  (ref, String date) =>
      ref.watch(appointmentsDaoProvider).watchAppointmentsForDate(date),
);

/// Live service-menu list.
final StreamProvider<List<Service>> servicesProvider =
    StreamProvider<List<Service>>(
        (ref) => ref.watch(servicesDaoProvider).watchServices());

/// Live inventory list.
final StreamProvider<List<InventoryItem>> inventoryProvider =
    StreamProvider<List<InventoryItem>>(
        (ref) => ref.watch(inventoryitemsDaoProvider).watchInventory());

/// Live expenses list, most recent first.
final StreamProvider<List<Expense>> expensesProvider =
    StreamProvider<List<Expense>>(
        (ref) => ref.watch(expensesDaoProvider).watchExpenses());

/// Live key-value settings map (owner profile, app_initialized flag, ...).
final StreamProvider<Map<String, String>> settingsProvider =
    StreamProvider<Map<String, String>>(
        (ref) => ref.watch(settingsDaoProvider).watchSettings());

/// Live notification list for the dashboard bell.
final StreamProvider<List<AppNotification>> notificationsProvider =
    StreamProvider<List<AppNotification>>(
        (ref) => ref.watch(appNotificationsDaoProvider).watchNotifications());

/// Live WhatsApp template list.
final StreamProvider<List<WhatsappTemplate>> whatsappTemplatesProvider =
    StreamProvider<List<WhatsappTemplate>>((ref) =>
        ref.watch(whatsappTemplatesDaoProvider).watchWhatsappTemplates());

final FutureProvider<void> ensureWhatsappTemplatesSeededProvider =
    FutureProvider<void>((ref) async {
  await ref.watch(databaseProvider).ensureWhatsappTemplatesSeeded();
});

/// One-shot, idempotent housekeeping: deletes notifications older than 15
/// days. Watched from the Dashboard on every build — cheap no-op when
/// there's nothing stale to remove.
final FutureProvider<void> notificationsPurgeProvider =
    FutureProvider<void>((ref) async {
  await ref.watch(appNotificationsDaoProvider).purgeOldNotifications();
});

/// Generates today's birthday / low-stock notifications if they don't
/// already exist for today (deduped by title + date), so the dashboard
/// bell has real content without spamming duplicates on every rebuild.
final FutureProvider<void> autoNotificationsSyncProvider =
    FutureProvider<void>((ref) async {
  final CustomersDao customersDao = ref.watch(customersDaoProvider);
  final InventoryitemsDao inventoryitemsDao =
      ref.watch(inventoryitemsDaoProvider);
  final AppNotificationsDao appNotificationsDao =
      ref.watch(appNotificationsDaoProvider);
  final List<Customer> customers = await customersDao.watchCustomers().first;
  final List<InventoryItem> inventory =
      await inventoryitemsDao.watchInventory().first;
  final List<AppNotification> existing =
      await appNotificationsDao.watchNotifications().first;

  final String todayKey = DateTime.now().toIso8601String().substring(0, 10);
  final String todayMonthDay = todayKey.substring(5);
  final Set<String> titlesToday = existing
      .where((AppNotification n) => n.createdAt.startsWith(todayKey))
      .map((AppNotification n) => n.title)
      .toSet();

  for (final Customer c in customers) {
    if ((c.birthday ?? '').endsWith(todayMonthDay)) {
      final String title = "🎂 ${c.name}'s Birthday Today";
      if (!titlesToday.contains(title)) {
        await appNotificationsDao.addNotification(
            type: 'birthday',
            title: title,
            body:
                '${c.name} has a birthday today. Send them a wish from the dashboard!');
      }
    }
  }
  for (final InventoryItem i in inventory) {
    if (i.stock <= i.minStock) {
      final String title = 'Low Stock: ${i.name}';
      if (!titlesToday.contains(title)) {
        await appNotificationsDao.addNotification(
            type: 'lowStock',
            title: title,
            body: 'Only ${i.stock} ${i.unit} left (minimum ${i.minStock}).');
      }
    }
  }
});

final FutureProvider<void> autoBackupCheckProvider =
    FutureProvider<void>((ref) async {
  try {
    final SharedPreferences prefs = getIt<SharedPreferences>();
    final bool enabled =
        prefs.getBool(AppConstants.prefKeyAutoBackupEnabled) ?? false;
    if (!enabled) return;

    final GoogleDriveBackupService drive =
        ref.watch(googleDriveBackupServiceProvider);
    final GoogleSignInAccount? account = await drive.signInSilently();
    if (account == null) return; // Never prompt automatically — silent only.

    final String? lastIso = prefs.getString(AppConstants.prefKeyLastBackupDate);
    final DateTime? last = lastIso == null ? null : DateTime.tryParse(lastIso);
    final bool dueForBackup = last == null ||
        DateTime.now().difference(last) >= const Duration(hours: 24);
    if (!dueForBackup) return;

    final AppDatabase db = ref.watch(databaseProvider);
    final Map<String, dynamic> data = await db.exportToJson();
    await drive.uploadBackup(data);
    await prefs.setString(
        AppConstants.prefKeyLastBackupDate, DateTime.now().toIso8601String());
  } catch (_) {
    // Silent by design — see doc comment above. A failed auto-backup
    // attempt simply gets retried on the next check (next app open/resume,
    // or after 24h), so nothing is lost by staying quiet here.
  }
});
