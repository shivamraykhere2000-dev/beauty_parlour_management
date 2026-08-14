// import 'package:drift/drift.dart';
//
// import '../app_database.dart';
// import '../tables/settings.dart';
//
// part 'settings_dao.g.dart';
//
// @DriftAccessor(tables: [Settings])
// class SettingsDao extends DatabaseAccessor<AppDatabase>
//     with _$SettingsDaoMixin {
//   SettingsDao(AppDatabase db) : super(db);
//
//   Future<List<Setting>> getSettings() => select(settings).get();
//
//   Stream<List<Setting>> watchSettings() => select(settings).watch();
//
//   Future<Setting?> getSetting(
//     String key,
//   ) {
//     return (select(settings)..where((tbl) => tbl.settingKey.equals(key)))
//         .getSingleOrNull();
//   }
//
//   Future<int> insertSetting(
//     SettingsCompanion data,
//   ) {
//     return into(settings).insert(data);
//   }
//
//   Future<bool> updateSetting(
//     Setting data,
//   ) {
//     return update(settings).replace(data);
//   }
//
//   Future<int> deleteSetting(int id) {
//     return (delete(settings)..where((tbl) => tbl.id.equals(id))).go();
//   }
// }
