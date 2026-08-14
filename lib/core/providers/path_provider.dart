import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

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
