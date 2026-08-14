import 'package:drift/drift.dart';

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()(); // YYYY-MM-DD
  TextColumn get category => text()();
  TextColumn get description => text()();
  IntColumn get amount => integer()();
  TextColumn get method => text()();
}
