import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/customers_dao.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// Add Customer form — also doubles as the Edit Customer form when
/// [existingCustomer] is passed in (from the Customer List's edit icon or
/// Customer Detail's edit action), reusing the same fields/validation
/// instead of a second screen.
class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen(
      {super.key, this.existingCustomer, this.onBack, this.onSaved});

  final Customer? existingCustomer;
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  bool get isEditing => existingCustomer != null;

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.existingCustomer?.name);
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.existingCustomer?.phone);
  late final TextEditingController _emailController =
      TextEditingController(text: widget.existingCustomer?.email);
  late final TextEditingController _notesController =
      TextEditingController(text: widget.existingCustomer?.notes);
  DateTime? _birthday;
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
  void initState() {
    super.initState();
    final String? existingBirthday = widget.existingCustomer?.birthday;
    if (existingBirthday != null && existingBirthday.isNotEmpty) {
      _birthday = DateTime.tryParse(existingBirthday);
    }
    final String? existingTags = widget.existingCustomer?.tags;
    if (existingTags != null) {
      for (final String s in _sources) {
        if (existingTags.contains(s)) {
          _source = s;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (v.trim().length < 2) return 'Enter a valid name';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final String digits = v.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit phone number';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final RegExp pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!pattern.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppSnackBar.show(context,
          message: 'Please fix the highlighted fields.',
          type: AppSnackBarType.error);
      return;
    }
    setState(() => _saving = true);
    final CustomersDao db = ref.read(customersDaoProvider);
    final String? birthdayIso = _birthday?.toIso8601String().substring(0, 10);
    try {
      if (widget.isEditing) {
        final Customer existing = widget.existingCustomer!;
        await db.updateCustomer(existing.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          birthday: Value<String?>(birthdayIso),
          avatarInitials: _initialsFor(_nameController.text.trim()),
          notes: _notesController.text.trim(),
        ));
        if (!mounted) return;
        AppSnackBar.show(context,
            message: '${_nameController.text.trim()} updated.',
            type: AppSnackBarType.success);
      } else {
        await db.addCustomer(CustomersCompanion.insert(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: Value<String>(_emailController.text.trim()),
          birthday: Value<String?>(birthdayIso),
          joinDate: DateTime.now().toIso8601String().substring(0, 10),
          avatarInitials: _initialsFor(_nameController.text.trim()),
          tags: Value<String>(_source == 'Walk-in' ? 'New' : 'New,$_source'),
          notes: Value<String>(_notesController.text.trim()),
        ));
        if (!mounted) return;
        AppSnackBar.show(context,
            message: '${_nameController.text.trim()} added.',
            type: AppSnackBarType.success);
      }
      widget.onSaved?.call();
    } catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: 'Could not save customer: $e',
            type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
          title: widget.isEditing ? 'Edit Customer' : 'Add Customer',
          onBack: widget.onBack),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
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
                    child: widget.isEditing
                        ? Center(
                            child: Text(
                                _initialsFor(_nameController.text.isEmpty
                                    ? '?'
                                    : _nameController.text),
                                style: AppTypography.h2(Colors.white)))
                        : const Icon(Icons.camera_alt_outlined,
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
                controller: _nameController,
                validator: _validateName),
            SizedBox(height: AppSpacing.md),
            AppTextField(
                label: 'PHONE NUMBER *',
                hint: '10-digit mobile number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: _validatePhone),
            SizedBox(height: AppSpacing.md),
            AppTextField(
                label: 'EMAIL ADDRESS',
                hint: 'email@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail),
            SizedBox(height: AppSpacing.md),
            AppDatePickerField(
              label: 'BIRTHDAY',
              selectedDate: _birthday,
              lastDate: DateTime.now(),
              firstDate: DateTime(DateTime.now().year - 90),
              onDateSelected: (DateTime d) => setState(() => _birthday = d),
            ),
            SizedBox(height: AppSpacing.md),
            Text('HOW DID THEY FIND US?',
                style: AppTypography.caption(const Color(0xFF6B4848)).copyWith(
                    fontWeight: AppTypography.bold, letterSpacing: 1)),
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
                    labelStyle: AppTypography.caption(_source == s
                            ? Colors.white
                            : const Color(0xFF6B4848))
                        .copyWith(fontWeight: AppTypography.semiBold),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: _source == s
                            ? AppColors.primary
                            : AppColors.border),
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
                label: widget.isEditing ? 'Save Changes' : 'Save Customer',
                onPressed: _saving ? null : _save,
                isLoading: _saving),
          ],
        ),
      ),
    );
  }
}
