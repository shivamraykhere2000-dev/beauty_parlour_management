import 'package:drift/drift.dart';

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().withDefault(const Constant(''))();

  /// Stored as `YYYY-MM-DD` so we can filter "today's birthdays" with a
  /// simple string suffix match (`LIKE '%-MM-DD'`).
  TextColumn get birthday => text().nullable()();
  TextColumn get joinDate => text()();
  IntColumn get visits => integer().withDefault(const Constant(0))();
  IntColumn get totalSpent => integer().withDefault(const Constant(0))();
  IntColumn get points => integer().withDefault(const Constant(0))();

  /// null | Silver | Gold | Platinum
  TextColumn get membership => text().nullable()();
  TextColumn get avatarInitials => text()();
  TextColumn get lastVisit => text().nullable()();

  /// Comma-separated tags, e.g. "VIP,Regular".
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}
