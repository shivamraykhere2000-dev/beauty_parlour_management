import 'dart:io';

import 'package:beauty_parlour_management/core/database/tables/appNotifications.dart';
import 'package:beauty_parlour_management/core/database/tables/appointments.dart';
import 'package:beauty_parlour_management/core/database/tables/customers.dart';
import 'package:beauty_parlour_management/core/database/tables/expenses.dart';
import 'package:beauty_parlour_management/core/database/tables/inventoryitems.dart';
import 'package:beauty_parlour_management/core/database/tables/services.dart';
import 'package:beauty_parlour_management/core/database/tables/settings.dart';
import 'package:beauty_parlour_management/core/database/tables/whatsappTemplates.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/app_constants.dart';
import 'daos/appnotifications_dao.dart';
import 'daos/appointments_dao.dart';
import 'daos/customers_dao.dart';
import 'daos/expenses_dao.dart';
import 'daos/inventoryitems_dao.dart';
import 'daos/services_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/whatsapptemplates_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Expenses,
    Appointments,
    Customers,
    Services,
    InventoryItems,
    WhatsappTemplates,
    Settings,
    AppNotifications,
  ],
  daos: [
    AppointmentsDao,
    CustomersDao,
    ExpensesDao,
    InventoryitemsDao,
    ServicesDao,
    SettingsDao,
    WhatsappTemplatesDao,
    AppNotificationsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Used by tests to inject an in-memory executor.
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seed();
        await _seedWhatsappTemplates();
      },
    );
  }
  Future<void> ensureWhatsappTemplatesSeeded() => _seedWhatsappTemplates();
  // =========================================================================
  // Backup / Restore — local JSON export & import. This is the actual data
  // layer for the Backup screen; Google Drive upload of the exported file
  // is a thin wrapper around this that can be added once OAuth is wired up
  // without touching this method.
  // =========================================================================
  Future<void> _seedWhatsappTemplates() async {
    final int existing = await select(whatsappTemplates)
        .get()
        .then((List<WhatsappTemplate> r) => r.length);
    if (existing > 0) return;
    await batch((Batch b) {
      b.insertAll(whatsappTemplates, <WhatsappTemplatesCompanion>[
        WhatsappTemplatesCompanion.insert(
            type: 'Appointment Confirmation',
            emoji: const Value<String>('📅'),
            body:
                'Hi {{name}}! Your appointment at Blossom Beauty Studio is confirmed. We look forward to seeing you! 💅'),
        WhatsappTemplatesCompanion.insert(
            type: 'Birthday Wishes',
            emoji: const Value<String>('🎂'),
            body:
                'Happy Birthday {{name}}! 🎉🌸 Enjoy 20% OFF your next visit this week. Book now: 📞 9876543210'),
        WhatsappTemplatesCompanion.insert(
            type: 'Thank You Message',
            emoji: const Value<String>('💝'),
            body:
                'Thank you for visiting Blossom Beauty Studio, {{name}}! 🌸 Hope you loved your visit. See you again soon!'),
        WhatsappTemplatesCompanion.insert(
            type: 'Package Expiry Reminder',
            emoji: const Value<String>('⏰'),
            body:
                'Hi {{name}}, your package is expiring soon. Book now to use your remaining sessions! 📞 9876543210'),
      ]);
    });
  }

  Future<Map<String, dynamic>> exportToJson() async {
    final List<Customer> allCustomers = await select(customers).get();
    final List<Appointment> allAppointments = await select(appointments).get();
    final List<Service> allServices = await select(services).get();
    final List<InventoryItem> allInventory = await select(inventoryItems).get();
    final List<Expense> allExpenses = await select(expenses).get();
    final List<Setting> allSettings = await select(settings).get();
    final List<AppNotification> allNotifications =
        await select(appNotifications).get();
    final List<WhatsappTemplate> allTemplates =
        await select(whatsappTemplates).get();

    return <String, dynamic>{
      'version': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'customers': allCustomers.map((Customer c) => c.toJson()).toList(),
      'appointments':
          allAppointments.map((Appointment a) => a.toJson()).toList(),
      'services': allServices.map((Service s) => s.toJson()).toList(),
      'inventoryItems':
          allInventory.map((InventoryItem i) => i.toJson()).toList(),
      'expenses': allExpenses.map((Expense e) => e.toJson()).toList(),
      'settings': allSettings.map((Setting s) => s.toJson()).toList(),
      'notifications':
          allNotifications.map((AppNotification n) => n.toJson()).toList(),
      'whatsappTemplates':
          allTemplates.map((WhatsappTemplate t) => t.toJson()).toList(),
    };
  }

  /// Restores data from a previously exported JSON map. Existing rows are
  /// cleared first so restoring is idempotent rather than duplicating data.
  Future<void> importFromJson(Map<String, dynamic> data) async {
    await transaction(() async {
      await delete(expenses).go();
      await delete(inventoryItems).go();
      await delete(appointments).go();
      await delete(services).go();
      await delete(customers).go();
      await delete(settings).go();
      await delete(appNotifications).go();
      await delete(whatsappTemplates).go();

      final List<dynamic> customersJson =
          (data['customers'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic c in customersJson) {
        await into(customers).insert(
            Customer.fromJson(c as Map<String, dynamic>).toCompanion(true));
      }
      final List<dynamic> servicesJson =
          (data['services'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic s in servicesJson) {
        await into(services).insert(
            Service.fromJson(s as Map<String, dynamic>).toCompanion(true));
      }
      final List<dynamic> appointmentsJson =
          (data['appointments'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic a in appointmentsJson) {
        await into(appointments).insert(
            Appointment.fromJson(a as Map<String, dynamic>).toCompanion(true));
      }
      final List<dynamic> inventoryJson =
          (data['inventoryItems'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic i in inventoryJson) {
        await into(inventoryItems).insert(
            InventoryItem.fromJson(i as Map<String, dynamic>)
                .toCompanion(true));
      }
      final List<dynamic> expensesJson =
          (data['expenses'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic e in expensesJson) {
        await into(expenses).insert(
            Expense.fromJson(e as Map<String, dynamic>).toCompanion(true));
      }
      final List<dynamic> settingsJson =
          (data['settings'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic s in settingsJson) {
        await into(settings).insert(
            Setting.fromJson(s as Map<String, dynamic>).toCompanion(true));
      }
      final List<dynamic> notificationsJson =
          (data['notifications'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic n in notificationsJson) {
        await into(appNotifications).insert(
            AppNotification.fromJson(n as Map<String, dynamic>)
                .toCompanion(true));
      }
      final List<dynamic> templatesJson =
          (data['whatsappTemplates'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic t in templatesJson) {
        await into(whatsappTemplates).insert(
            WhatsappTemplate.fromJson(t as Map<String, dynamic>)
                .toCompanion(true));
      }
      if (templatesJson.isEmpty) {
        await _seedWhatsappTemplates();
      }
    });
  }

  // =========================================================================
  // First-run seed — mirrors the Figma export's demo data so the app isn't
  // empty on first launch. Runs once, only when the DB is first created.
  // =========================================================================

  Future<void> _seed() async {
    await batch((Batch b) {
      b.insertAll(services, <ServicesCompanion>[
        ServicesCompanion.insert(
            category: 'Hair',
            name: 'Haircut & Style',
            price: 500,
            duration: 60,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Hair',
            name: 'Hair Color (Global)',
            price: 1800,
            duration: 120,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Hair',
            name: 'Highlights / Balayage',
            price: 3500,
            duration: 150),
        ServicesCompanion.insert(
            category: 'Hair',
            name: 'Blowdry & Style',
            price: 400,
            duration: 45,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Hair',
            name: 'Hair Spa',
            price: 1200,
            duration: 60,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Hair',
            name: 'Keratin Treatment',
            price: 5000,
            duration: 180),
        ServicesCompanion.insert(
            category: 'Hair', name: 'Head Massage', price: 350, duration: 30),
        ServicesCompanion.insert(
            category: 'Skin',
            name: 'Gold Facial',
            price: 1200,
            duration: 60,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Skin',
            name: 'Cleanup',
            price: 600,
            duration: 45,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Skin',
            name: 'Threading - Eyebrows',
            price: 60,
            duration: 10,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Skin',
            name: 'Threading - Full Face',
            price: 150,
            duration: 20),
        ServicesCompanion.insert(
            category: 'Skin',
            name: 'Waxing - Full Arms',
            price: 300,
            duration: 30,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Skin',
            name: 'Waxing - Full Legs',
            price: 500,
            duration: 45,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Nails',
            name: 'Manicure (Regular)',
            price: 400,
            duration: 45,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Nails',
            name: 'Gel Manicure',
            price: 700,
            duration: 60,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Nails',
            name: 'Pedicure (Regular)',
            price: 600,
            duration: 60,
            popular: const Value<bool>(true)),
        ServicesCompanion.insert(
            category: 'Nails',
            name: 'Pedicure (Spa)',
            price: 900,
            duration: 75),
        ServicesCompanion.insert(
            category: 'Others',
            name: 'Mehendi (Hands)',
            price: 300,
            duration: 60),
        ServicesCompanion.insert(
            category: 'Others',
            name: 'Bridal Package',
            price: 15000,
            duration: 480),
      ]);
      b.insertAll(inventoryItems, <InventoryItemsCompanion>[
        InventoryItemsCompanion.insert(
            name: 'Loreal Hair Color - Ash Blonde',
            category: 'Hair',
            stock: const Value<int>(3),
            minStock: const Value<int>(5),
            unit: 'box',
            price: 850),
        InventoryItemsCompanion.insert(
            name: 'Schwarzkopf Developer 20V',
            category: 'Hair',
            stock: const Value<int>(8),
            minStock: const Value<int>(4),
            unit: 'bottle',
            price: 420),
        InventoryItemsCompanion.insert(
            name: 'Gold Facial Kit',
            category: 'Skin',
            stock: const Value<int>(2),
            minStock: const Value<int>(5),
            unit: 'kit',
            price: 650),
        InventoryItemsCompanion.insert(
            name: 'Rica Chocolate Wax',
            category: 'Skin',
            stock: const Value<int>(6),
            minStock: const Value<int>(3),
            unit: 'can',
            price: 380),
        InventoryItemsCompanion.insert(
            name: 'OPI Nail Polish Set',
            category: 'Nails',
            stock: const Value<int>(1),
            minStock: const Value<int>(2),
            unit: 'set',
            price: 1200),
        InventoryItemsCompanion.insert(
            name: 'Keratin Treatment Solution',
            category: 'Hair',
            stock: const Value<int>(4),
            minStock: const Value<int>(2),
            unit: 'bottle',
            price: 1800),
        InventoryItemsCompanion.insert(
            name: 'Hair Spa Cream',
            category: 'Hair',
            stock: const Value<int>(12),
            minStock: const Value<int>(5),
            unit: 'jar',
            price: 450),
        InventoryItemsCompanion.insert(
            name: 'Rose Water Toner',
            category: 'Skin',
            stock: const Value<int>(9),
            minStock: const Value<int>(3),
            unit: 'bottle',
            price: 220),
        InventoryItemsCompanion.insert(
            name: 'Nail Gel (UV)',
            category: 'Nails',
            stock: const Value<int>(3),
            minStock: const Value<int>(4),
            unit: 'tube',
            price: 680),
        InventoryItemsCompanion.insert(
            name: 'Threading Cotton Rolls',
            category: 'Others',
            stock: const Value<int>(20),
            minStock: const Value<int>(10),
            unit: 'roll',
            price: 45),
      ]);

      b.insertAll(expenses, <ExpensesCompanion>[
        ExpensesCompanion.insert(
            date: '2025-07-12',
            category: 'Products',
            description: 'Loreal Color Stock Refill',
            amount: 4200,
            method: 'UPI'),
        ExpensesCompanion.insert(
            date: '2025-07-10',
            category: 'Utilities',
            description: 'Electricity Bill',
            amount: 2800,
            method: 'Online'),
        ExpensesCompanion.insert(
            date: '2025-07-08',
            category: 'Products',
            description: 'Rica Wax Supply',
            amount: 1900,
            method: 'Cash'),
        ExpensesCompanion.insert(
            date: '2025-07-05',
            category: 'Rent',
            description: 'Monthly Rent',
            amount: 12000,
            method: 'Bank Transfer'),
        ExpensesCompanion.insert(
            date: '2025-07-03',
            category: 'Misc',
            description: 'Cleaning Supplies',
            amount: 450,
            method: 'Cash'),
        ExpensesCompanion.insert(
            date: '2025-07-01',
            category: 'Staff',
            description: 'Assistant Salary',
            amount: 8000,
            method: 'Bank Transfer'),
      ]);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File(p.join(directory.path, AppConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
