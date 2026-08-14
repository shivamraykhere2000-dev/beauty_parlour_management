import 'package:drift/drift.dart';

class WhatsappTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get emoji => text().withDefault(const Constant('💬'))();
  TextColumn get body => text()();
}
