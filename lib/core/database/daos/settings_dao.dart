import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/settings.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> getSetting(String key) async {
    final Setting? row = await (select(settings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Stream<Map<String, String>> watchSettings() {
    return select(settings).watch().map((List<Setting> rows) =>
        <String, String>{for (final Setting r in rows) r.key: r.value});
  }

  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: value));
  }

  Future<bool> isAppInitialized() async =>
      (await getSetting('app_initialized')) == 'true';
}
