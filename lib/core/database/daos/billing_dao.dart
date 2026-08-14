// import 'package:drift/drift.dart';
//
// import '../app_database.dart';
// import '../tables/bills.dart';
//
// part 'billing_dao.g.dart';
//
// @DriftAccessor(tables: [Bills])
// class BillingDao extends DatabaseAccessor<AppDatabase> with _$BillingDaoMixin {
//   BillingDao(AppDatabase db) : super(db);
//
//   Future<List<Bill>> getBills() => select(bills).get();
//
//   Stream<List<Bill>> watchBills() => select(bills).watch();
//
//   Future<int> insertBill(
//     BillsCompanion data,
//   ) {
//     return into(bills).insert(data);
//   }
//
//   Future<bool> updateBill(
//     Bill data,
//   ) {
//     return update(bills).replace(data);
//   }
//
//   Future<int> deleteBill(int id) {
//     return (delete(bills)..where((tbl) => tbl.id.equals(id))).go();
//   }
// }
