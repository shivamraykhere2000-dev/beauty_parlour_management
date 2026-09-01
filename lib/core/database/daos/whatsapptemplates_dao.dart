import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/whatsappTemplates.dart';

part 'whatsapptemplates_dao.g.dart';

@DriftAccessor(tables: [WhatsappTemplates])
class WhatsappTemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$WhatsappTemplatesDaoMixin {
  WhatsappTemplatesDao(super.db);

  // =========================================================================
  // WhatsApp Templates
  // =========================================================================
  Future<String?> getTemplateBody(String type) async {
    final query = select(whatsappTemplates)
      ..where((tbl) => tbl.type.equals(type))
      ..limit(1);

    final template = await query.getSingleOrNull();

    return template?.body;
  }

  Stream<List<WhatsappTemplate>> watchWhatsappTemplates() =>
      select(whatsappTemplates).watch();

  Future<bool> updateWhatsappTemplate(WhatsappTemplate entry) =>
      update(whatsappTemplates).replace(entry);

  Future<int> addWhatsappTemplate(
      {required String type, required String emoji, required String body}) {
    return into(whatsappTemplates).insert(WhatsappTemplatesCompanion.insert(
      type: type,
      emoji: Value<String>(emoji.isEmpty ? '💬' : emoji),
      body: body,
    ));
  }

  Future<void> deleteWhatsappTemplate(int id) =>
      (delete(whatsappTemplates)..where((t) => t.id.equals(id))).go();
}
