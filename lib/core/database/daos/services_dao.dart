import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/services.dart';

part 'services_dao.g.dart';

@DriftAccessor(tables: [Services])
class ServicesDao extends DatabaseAccessor<AppDatabase>
    with _$ServicesDaoMixin {
  ServicesDao(super.db);
  // =========================================================================
  // Services
  // =========================================================================

  Stream<List<Service>> watchServices() => select(services).watch();

  Future<int> addService(ServicesCompanion entry) =>
      into(services).insert(entry);

  Future<bool> updateService(Service entry) => update(services).replace(entry);

  Future<void> deleteService(int id) =>
      (delete(services)..where((t) => t.id.equals(id))).go();
}
