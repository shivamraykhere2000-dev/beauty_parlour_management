import 'package:drift/drift.dart';

/// Retail / consumable stock item.
class InventoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(0))();
  TextColumn get unit => text()();
  IntColumn get price => integer()();
}
