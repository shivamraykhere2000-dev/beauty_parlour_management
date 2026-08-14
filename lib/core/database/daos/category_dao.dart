// import 'package:drift/drift.dart';
//
// import '../app_database.dart';
//
// part 'category_dao.g.dart';
//
// @DriftAccessor(tables: [ServiceCategories])
// class CategoryDao extends DatabaseAccessor<AppDatabase>
//     with _$CategoryDaoMixin {
//   CategoryDao(super.db);
//
//   /// Live stream — UI rebuilds automatically on any change
//   Stream<List<ServiceCategory>> watchAllCategories() {
//     return (select(
//       serviceCategories,
//     )..orderBy([(t) => OrderingTerm(expression: t.id)])).watch();
//   }
//
//   Future<int> addCategory(String name) {
//     return into(
//       serviceCategories,
//     ).insert(ServiceCategoriesCompanion.insert(name: name));
//   }
//
//   Future<bool> updateCategory(int id, String name) {
//     return (update(serviceCategories)..where((t) => t.id.equals(id)))
//         .write(ServiceCategoriesCompanion(name: Value(name)))
//         .then((rows) => rows > 0);
//   }
//
//   Future<int> deleteCategory(int id) {
//     return (delete(serviceCategories)..where((t) => t.id.equals(id))).go();
//   }
// }
