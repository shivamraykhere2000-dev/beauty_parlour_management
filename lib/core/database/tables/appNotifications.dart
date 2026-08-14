import 'package:drift/drift.dart';

class AppNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// birthday | lowStock | appointment | general
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get createdAt => text()(); // ISO8601
  BoolColumn get read => boolean().withDefault(const Constant(false))();
}
