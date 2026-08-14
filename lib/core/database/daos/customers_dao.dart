import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/customers.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db);

// =========================================================================
// Customers
// =========================================================================

  Stream<List<Customer>> watchCustomers() => (select(customers)
        ..orderBy(<OrderingTerm Function($CustomersTable)>[
          (t) => OrderingTerm.desc(t.id)
        ]))
      .watch();

  Future<Customer> getCustomer(int id) =>
      (select(customers)..where((t) => t.id.equals(id))).getSingle();

  Future<int> addCustomer(CustomersCompanion entry) =>
      into(customers).insert(entry);

  Future<bool> updateCustomer(Customer entry) =>
      update(customers).replace(entry);

  Future<void> deleteCustomer(int id) =>
      (delete(customers)..where((t) => t.id.equals(id))).go();

  /// Bumps visits/spend/points after a bill is collected for [customerId].
  Future<void> recordVisit(int customerId, {required int amountSpent}) async {
    final Customer customer = await getCustomer(customerId);
    final int earnedPoints = (amountSpent / 10).floor();
    await updateCustomer(
      customer.copyWith(
        visits: customer.visits + 1,
        totalSpent: customer.totalSpent + amountSpent,
        points: customer.points + earnedPoints,
        lastVisit:
            Value<String?>(DateTime.now().toIso8601String().substring(0, 10)),
      ),
    );
  }
}
