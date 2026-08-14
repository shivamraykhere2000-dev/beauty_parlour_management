import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/services_dao.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String _category = 'Hair';
  static const List<String> _categories = <String>[
    'Hair',
    'Skin',
    'Nails',
    'Others'
  ];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Service>> servicesAsync = ref.watch(servicesProvider);
    final ServicesDao dao = ref.watch(servicesDaoProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xxl, AppSpacing.md, AppSpacing.md),
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Services', style: AppTypography.h2(Colors.white)),
                    InkWell(
                      onTap: () => _showAddDialog(context, dao),
                      child: Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    for (final String c in _categories) ...<Widget>[
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _category = c),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            decoration: BoxDecoration(
                              color: _category == c
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMd),
                            ),
                            alignment: Alignment.center,
                            child: Text(c,
                                style: AppTypography.caption(_category == c
                                        ? AppColors.primary
                                        : Colors.white)
                                    .copyWith(fontWeight: AppTypography.bold)),
                          ),
                        ),
                      ),
                      if (c != _categories.last) SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: servicesAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, _) => AppErrorWidget(message: '$e'),
              data: (List<Service> all) {
                final List<Service> list =
                    all.where((Service s) => s.category == _category).toList();
                if (list.isEmpty) {
                  return const EmptyWidget(
                      icon: Icons.content_cut_outlined,
                      title: 'No services here',
                      message: 'Add a service in this category.');
                }
                return ListView(
                  padding: EdgeInsets.all(AppSpacing.md),
                  children: <Widget>[
                    for (final Service sv in list) ...<Widget>[
                      AppCard(
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 40.r,
                              height: 40.r,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F4),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMd)),
                              child: const Icon(Icons.content_cut,
                                  color: AppColors.primary, size: 20),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Flexible(
                                          child: Text(sv.name,
                                              style: AppTypography.label(
                                                      AppColors.foreground)
                                                  .copyWith(
                                                      fontWeight:
                                                          AppTypography.bold),
                                              overflow: TextOverflow.ellipsis)),
                                      if (sv.popular) ...<Widget>[
                                        SizedBox(width: AppSpacing.xxs),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFFFF0F4),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppDimensions
                                                          .radiusPill)),
                                          child: Text('Popular',
                                              style: AppTypography.caption(
                                                      AppColors.primary)
                                                  .copyWith(
                                                      fontSize: 9.sp,
                                                      fontWeight:
                                                          AppTypography.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text('${sv.duration} minutes',
                                      style: AppTypography.caption(
                                          AppColors.mutedForeground)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text('₹${sv.price}',
                                    style:
                                        AppTypography.label(AppColors.primary)
                                            .copyWith(
                                                fontWeight:
                                                    AppTypography.bold)),
                                InkWell(
                                  onTap: () => dao.deleteService(sv.id),
                                  child: const Icon(Icons.delete_outline,
                                      size: 16, color: Color(0xFFC9B0B8)),
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
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, ServicesDao db) {
    final TextEditingController name = TextEditingController();
    final TextEditingController price = TextEditingController();
    final TextEditingController duration = TextEditingController(text: '30');
    String category = _category;

    AppDialog.show(
      context,
      title: 'Add Service',
      content: StatefulBuilder(
        builder: (BuildContext context,
            void Function(void Function()) setDialogState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppTextField(label: 'SERVICE NAME', controller: name),
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: <Widget>[
                    for (final String c in _categories)
                      ChoiceChip(
                        label: Text(c),
                        selected: category == c,
                        onSelected: (_) => setDialogState(() => category = c),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                        child: AppTextField(
                            label: 'PRICE (₹)',
                            controller: price,
                            keyboardType: TextInputType.number)),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: AppTextField(
                            label: 'DURATION (min)',
                            controller: duration,
                            keyboardType: TextInputType.number)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      primaryActionLabel: 'Save',
      onPrimaryAction: () {
        if (name.text.trim().isEmpty) return;
        db.addService(ServicesCompanion.insert(
          category: category,
          name: name.text.trim(),
          price: int.tryParse(price.text) ?? 0,
          duration: int.tryParse(duration.text) ?? 30,
        ));
        Navigator.of(context).pop();
      },
      secondaryActionLabel: 'Cancel',
    );
  }
}
