import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/inventoryitems_dao.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<InventoryItem>> itemsAsync =
        ref.watch(inventoryProvider);
    final InventoryitemsDao db = ref.watch(inventoryitemsDaoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Inventory',
        onBack: onBack,
        trailing: InkWell(
          onTap: () => _showAddDialog(context, db),
          child: const Icon(Icons.add, color: Colors.white, size: 22),
        ),
      ),
      body: itemsAsync.when(
        loading: () => const LoadingWidget(),
        error: (Object e, _) => AppErrorWidget(message: '$e'),
        data: (List<InventoryItem> items) {
          if (items.isEmpty) {
            return const EmptyWidget(
                icon: Icons.shopping_bag_outlined,
                title: 'No inventory yet',
                message: 'Add your first stock item.');
          }
          final List<InventoryItem> lowStock =
              items.where((InventoryItem i) => i.stock <= i.minStock).toList();
          return ListView(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
            children: <Widget>[
              if (lowStock.isNotEmpty)
                AppCard(
                  color: const Color(0xFFFFFBEB),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.warning_amber_rounded,
                          size: 18, color: Color(0xFFF59E0B)),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                            '${lowStock.length} item(s) below minimum stock',
                            style:
                                AppTypography.caption(const Color(0xFFB45309))
                                    .copyWith(fontWeight: AppTypography.bold)),
                      ),
                    ],
                  ),
                ),
              if (lowStock.isNotEmpty) SizedBox(height: AppSpacing.sm),
              for (final InventoryItem item in items) ...<Widget>[
                _InventoryRow(item: item, db: db),
                SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, InventoryitemsDao db) {
    final TextEditingController name = TextEditingController();
    final TextEditingController category = TextEditingController(text: 'Hair');
    final TextEditingController stock = TextEditingController(text: '0');
    final TextEditingController minStock = TextEditingController(text: '0');
    final TextEditingController unit = TextEditingController(text: 'unit');
    final TextEditingController price = TextEditingController(text: '0');

    AppDialog.show(
      context,
      title: 'Add Inventory Item',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppTextField(label: 'NAME', controller: name),
            SizedBox(height: AppSpacing.sm),
            AppTextField(label: 'CATEGORY', controller: category),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                    child: AppTextField(
                        label: 'STOCK',
                        controller: stock,
                        keyboardType: TextInputType.number)),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: AppTextField(
                        label: 'MIN STOCK',
                        controller: minStock,
                        keyboardType: TextInputType.number)),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(child: AppTextField(label: 'UNIT', controller: unit)),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: AppTextField(
                        label: 'PRICE',
                        controller: price,
                        keyboardType: TextInputType.number)),
              ],
            ),
          ],
        ),
      ),
      primaryActionLabel: 'Save',
      onPrimaryAction: () {
        if (name.text.trim().isEmpty) return;
        db.addInventoryItem(InventoryItemsCompanion.insert(
          name: name.text.trim(),
          category:
              category.text.trim().isEmpty ? 'Others' : category.text.trim(),
          stock: Value<int>(int.tryParse(stock.text) ?? 0),
          minStock: Value<int>(int.tryParse(minStock.text) ?? 0),
          unit: unit.text.trim().isEmpty ? 'unit' : unit.text.trim(),
          price: int.tryParse(price.text) ?? 0,
        ));
        Navigator.of(context).pop();
      },
      secondaryActionLabel: 'Cancel',
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.item,
    required this.db,
  });

  final InventoryItem item;
  final InventoryitemsDao db;

  @override
  Widget build(BuildContext context) {
    final bool low = item.stock <= item.minStock;

    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F4),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: AppTypography.label(AppColors.foreground).copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  '${item.category} · ₹${item.price}/${item.unit}',
                  style: AppTypography.caption(
                    AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${item.stock} ${item.unit}',
                style: AppTypography.label(
                  low ? AppColors.destructive : AppColors.foreground,
                ).copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _AdjustButton(
                    icon: Icons.remove,
                    onTap: () => db.adjustStock(item.id, -1),
                  ),
                  SizedBox(width: 6.w),
                  _AdjustButton(
                    icon: Icons.add,
                    onTap: () => db.adjustStock(item.id, 1),
                  ),
                  SizedBox(width: 6.w),
                  _AdjustButton(
                    icon: Icons.delete_outline,
                    color: AppColors.destructive,
                    onTap: () => _showDeleteConfirmation(
                      context,
                      item,
                      db,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    InventoryItem item,
    InventoryitemsDao db,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Inventory Item?'),
          content: Text(
            'Are you sure you want to delete "${item.name}"? '
            'This action cannot be undone.',
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
                await db.deleteInventoryItem(item.id);
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
}

class _AdjustButton extends StatelessWidget {
  const _AdjustButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        AppDimensions.radiusPill,
      ),
      child: Container(
        width: 24.r,
        height: 24.r,
        decoration: const BoxDecoration(
          color: Color(0xFFF0E8EC),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}
