import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/inventoryitems.dart';

part 'inventoryitems_dao.g.dart';

@DriftAccessor(tables: [InventoryItems])
class InventoryitemsDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryitemsDaoMixin {
  InventoryitemsDao(super.db);

  Stream<List<InventoryItem>> watchInventory() =>
      select(inventoryItems).watch();

  Future<int> addInventoryItem(InventoryItemsCompanion entry) =>
      into(inventoryItems).insert(entry);

  Future<bool> updateInventoryItem(InventoryItem entry) =>
      update(inventoryItems).replace(entry);

  Future<void> deleteInventoryItem(int id) =>
      (delete(inventoryItems)..where((t) => t.id.equals(id))).go();

  Future<void> adjustStock(int itemId, int delta) async {
    final InventoryItem item = await (select(inventoryItems)
          ..where((t) => t.id.equals(itemId)))
        .getSingle();
    final int next = (item.stock + delta).clamp(0, 1 << 30);
    await updateInventoryItem(item.copyWith(stock: next));
  }
}
