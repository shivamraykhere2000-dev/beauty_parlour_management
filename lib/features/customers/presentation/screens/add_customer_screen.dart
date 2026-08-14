import 'package:beauty_parlour_management/core/database/daos/customers_dao.dart';
import 'package:beauty_parlour_management/core/providers/path_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key, this.onBack, this.onSaved});

  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _source = 'Walk-in';
  bool _saving = false;

  static const List<String> _sources = <String>[
    'Walk-in',
    'Referral',
    'Instagram',
    'Google',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _initialsFor(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      AppSnackBar.show(context,
          message: 'Name and phone number are required.',
          type: AppSnackBarType.error);
      return;
    }
    setState(() => _saving = true);
    final CustomersDao db = ref.read(customersDaoProvider);
    try {
      await db.addCustomer(CustomersCompanion.insert(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: Value<String>(_emailController.text.trim()),
        birthday: Value<String?>(_birthdayController.text.trim().isEmpty
            ? null
            : _birthdayController.text.trim()),
        joinDate: DateTime.now().toIso8601String().substring(0, 10),
        avatarInitials: _initialsFor(_nameController.text.trim()),
        tags: Value<String>(_source == 'Walk-in' ? 'New' : 'New,$_source'),
        notes: Value<String>(_notesController.text.trim()),
      ));
      if (!mounted) return;
      AppSnackBar.show(context,
          message: '${_nameController.text.trim()} added.',
          type: AppSnackBarType.success);
      widget.onSaved?.call();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Add Customer', onBack: widget.onBack),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
        children: <Widget>[
          Center(
            child: Stack(
              children: <Widget>[
                Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 28),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(Icons.add,
                        size: 14, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          AppTextField(
              label: 'FULL NAME *',
              hint: 'e.g. Anita Verma',
              controller: _nameController),
          SizedBox(height: AppSpacing.md),
          AppTextField(
              label: 'PHONE NUMBER *',
              hint: '10-digit mobile number',
              controller: _phoneController,
              keyboardType: TextInputType.phone),
          SizedBox(height: AppSpacing.md),
          AppTextField(
              label: 'EMAIL ADDRESS',
              hint: 'email@example.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress),
          SizedBox(height: AppSpacing.md),
          AppTextField(
              label: 'BIRTHDAY',
              hint: 'DD/MM/YYYY',
              controller: _birthdayController,
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
          SizedBox(height: AppSpacing.md),
          Text('HOW DID THEY FIND US?',
              style: AppTypography.caption(const Color(0xFF6B4848))
                  .copyWith(fontWeight: AppTypography.bold, letterSpacing: 1)),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final String s in _sources)
                ChoiceChip(
                  label: Text(s),
                  selected: _source == s,
                  onSelected: (_) => setState(() => _source = s),
                  labelStyle: AppTypography.caption(
                          _source == s ? Colors.white : const Color(0xFF6B4848))
                      .copyWith(fontWeight: AppTypography.semiBold),
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                      color:
                          _source == s ? AppColors.primary : AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusPill)),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'NOTES & PREFERENCES',
            hint: 'Allergies, preferences, special notes...',
            controller: _notesController,
            maxLines: 3,
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
              label: 'Save Customer',
              onPressed: _saving ? null : _save,
              isLoading: _saving),
        ],
      ),
    );
  }
}
