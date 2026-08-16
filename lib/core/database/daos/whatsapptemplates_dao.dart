import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/whatsappTemplates.dart';

part 'whatsapptemplates_dao.g.dart';

@DriftAccessor(tables: [WhatsappTemplates])
class WhatsappTemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$WhatsappTemplatesDaoMixin {
  WhatsappTemplatesDao(super.db);

  Stream<List<WhatsappTemplate>> watchWhatsappTemplates() =>
      select(whatsappTemplates).watch();

  Future<bool> updateWhatsappTemplate(WhatsappTemplate entry) =>
      update(whatsappTemplates).replace(entry);

  Future<void> _seedWhatsappTemplates() async {
    final int existing = await select(whatsappTemplates)
        .get()
        .then((List<WhatsappTemplate> r) => r.length);
    if (existing > 0) return;
    await batch((Batch b) {
      b.insertAll(whatsappTemplates, <WhatsappTemplatesCompanion>[
        WhatsappTemplatesCompanion.insert(
            type: 'Appointment Confirmation',
            emoji: const Value<String>('📅'),
            body:
                'Hi {{name}}! Your appointment at Blossom Beauty Studio is confirmed. We look forward to seeing you! 💅'),
        WhatsappTemplatesCompanion.insert(
            type: 'Birthday Wishes',
            emoji: const Value<String>('🎂'),
            body:
                'Happy Birthday {{name}}! 🎉🌸 Enjoy 20% OFF your next visit this week. Book now: 📞 9876543210'),
        WhatsappTemplatesCompanion.insert(
            type: 'Festival Offer',
            emoji: const Value<String>('🪔'),
            body:
                '🌟 Festival Special at Blossom Beauty Studio 🌟 15% off all services this week. Book now! 📞 9876543210'),
        WhatsappTemplatesCompanion.insert(
            type: 'Thank You Message',
            emoji: const Value<String>('💝'),
            body:
                'Thank you for visiting Blossom Beauty Studio, {{name}}! 🌸 Hope you loved your visit. See you again soon!'),
        WhatsappTemplatesCompanion.insert(
            type: 'Package Expiry Reminder',
            emoji: const Value<String>('⏰'),
            body:
                'Hi {{name}}, your package is expiring soon. Book now to use your remaining sessions! 📞 9876543210'),
      ]);
    });
  }
}
