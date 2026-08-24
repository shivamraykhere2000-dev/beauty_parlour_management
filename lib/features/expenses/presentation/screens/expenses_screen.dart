import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/expenses_dao.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Expense>> expensesAsync = ref.watch(expensesProvider);
    final ExpensesDao dao = ref.watch(expensesDaoProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Expenses',
        onBack: onBack,
        trailing: InkWell(
          onTap: () => _showAddDialog(context, dao),
          child: const Icon(Icons.add, color: Colors.white, size: 22),
        ),
      ),
      body: expensesAsync.when(
        loading: () => const LoadingWidget(),
        error: (Object e, _) => AppErrorWidget(message: '$e'),
        data: (List<Expense> expenses) {
          if (expenses.isEmpty) {
            return const EmptyWidget(
                icon: Icons.wallet_outlined,
                title: 'No expenses yet',
                message: 'Log your first business expense.');
          }
          final int total =
              expenses.fold<int>(0, (int s, Expense e) => s + e.amount);
          return ListView(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
            children: <Widget>[
              AppCard(
                color: const Color(0xFFFFF5F7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Total Expenses',
                        style: AppTypography.label(AppColors.primary)
                            .copyWith(fontWeight: AppTypography.bold)),
                    Text('₹$total', style: AppTypography.h2(AppColors.primary)),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              for (final Expense e in expenses) ...<Widget>[
                AppCard(
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F4),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd)),
                        child: const Icon(Icons.receipt_long_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(e.description,
                                style: AppTypography.label(AppColors.foreground)
                                    .copyWith(fontWeight: AppTypography.bold)),
                            Text('${e.category} · ${e.date} · ${e.method}',
                                style: AppTypography.caption(
                                    AppColors.mutedForeground)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text('₹${e.amount}',
                              style: AppTypography.label(AppColors.destructive)
                                  .copyWith(fontWeight: AppTypography.bold)),
                          InkWell(
                            onTap: () =>
                                _showDeleteConfirmation(context, dao, e.id),
                            child: Text('Delete',
                                style: AppTypography.caption(
                                    AppColors.mutedForeground)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ExpensesDao dao,
    int expenseId,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete this expense?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await dao.deleteExpense(expenseId);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.destructive,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, ExpensesDao db) {
    final TextEditingController description = TextEditingController();
    final TextEditingController category =
        TextEditingController(text: 'Products');
    final TextEditingController amount = TextEditingController();
    final TextEditingController method = TextEditingController(text: 'Cash');

    AppDialog.show(
      context,
      title: 'Add Expense',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppTextField(label: 'DESCRIPTION', controller: description),
            SizedBox(height: AppSpacing.sm),
            AppTextField(label: 'CATEGORY', controller: category),
            SizedBox(height: AppSpacing.sm),
            AppTextField(
                label: 'AMOUNT',
                controller: amount,
                keyboardType: TextInputType.number),
            SizedBox(height: AppSpacing.sm),
            AppTextField(label: 'PAYMENT METHOD', controller: method),
          ],
        ),
      ),
      primaryActionLabel: 'Save',
      onPrimaryAction: () {
        if (description.text.trim().isEmpty) return;
        db.addExpense(ExpensesCompanion.insert(
          date: DateTime.now().toIso8601String().substring(0, 10),
          category:
              category.text.trim().isEmpty ? 'Misc' : category.text.trim(),
          description: description.text.trim(),
          amount: int.tryParse(amount.text) ?? 0,
          method: method.text.trim().isEmpty ? 'Cash' : method.text.trim(),
        ));
        Navigator.of(context).pop();
      },
      secondaryActionLabel: 'Cancel',
    );
  }
}
