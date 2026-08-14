import 'package:drift/drift.dart';

import 'customers.dart';

class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();

  /// Denormalised so list screens don't need a join for the common case.
  TextColumn get customerName => text()();

  /// Comma-separated service names.
  TextColumn get services => text()();
  TextColumn get date => text()(); // YYYY-MM-DD
  TextColumn get time => text()(); // e.g. "10:00 AM"
  IntColumn get durationMinutes => integer().withDefault(const Constant(60))();
  IntColumn get amount => integer().withDefault(const Constant(0))();

  /// confirmed | pending | completed | cancelled
  TextColumn get status => text().withDefault(const Constant('confirmed'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}
