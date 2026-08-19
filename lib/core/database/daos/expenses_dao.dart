import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/expenses.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [Expenses])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  // =========================================================================
  // Expenses
  // =========================================================================

  Stream<List<Expense>> watchExpenses() => (select(expenses)
        ..orderBy(<OrderingTerm Function($ExpensesTable)>[
          (t) => OrderingTerm.desc(t.id)
        ]))
      .watch();

  Future<int> addExpense(ExpensesCompanion entry) =>
      into(expenses).insert(entry);

  Future<void> deleteExpense(int id) =>
      (delete(expenses)..where((t) => t.id.equals(id))).go();
}
