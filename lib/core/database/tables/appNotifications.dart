import 'package:drift/drift.dart';

class AppNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get type => text()();

  TextColumn get title => text()();

  TextColumn get body => text()();

  IntColumn get customerId => integer().nullable()();

  IntColumn get appointmentId => integer().nullable()();

  IntColumn get inventoryItemId => integer().nullable()();

  TextColumn get actionType => text().nullable()();

  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  DateTimeColumn get readAt => dateTime().nullable()();

  BoolColumn get isActionCompleted =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get actionCompletedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get expiresAt => dateTime().nullable()();

  TextColumn get uniqueKey => text().unique()();
}
