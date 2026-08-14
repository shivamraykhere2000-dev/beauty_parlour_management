import 'package:drift/drift.dart';

/// Salon service-menu entry.
class Services extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  TextColumn get name => text()();
  IntColumn get price => integer()();
  IntColumn get duration => integer()();
  BoolColumn get popular => boolean().withDefault(const Constant(false))();
}
