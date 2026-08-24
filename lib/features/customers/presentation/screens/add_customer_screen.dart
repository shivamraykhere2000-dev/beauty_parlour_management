import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/customers_dao.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// Add Customer form — also doubles as the Edit Customer form when
/// [existingCustomer] is passed in from the Customer List's edit icon
/// or Customer Detail's edit action.
class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({
    super.key,
    this.existingCustomer,
    this.onBack,
    this.onSaved,
  });

  final Customer? existingCustomer;
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  bool get isEditing => existingCustomer != null;

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController = TextEditingController(
    text: widget.existingCustomer?.name,
  );

  late final TextEditingController _phoneController = TextEditingController(
    text: widget.existingCustomer?.phone,
  );

  late final TextEditingController _emailController = TextEditingController(
    text: widget.existingCustomer?.email,
  );

  late final TextEditingController _notesController = TextEditingController(
    text: widget.existingCustomer?.notes,
  );

  DateTime? _birthday;

  String _source = 'Walk-in';

  bool _saving = false;

  static const List<String> _sources = <String>[
    'Walk-in',
    'Referral',
    'Instagram',
    'Google',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // Load existing birthday when editing.
    final String? existingBirthday = widget.existingCustomer?.birthday;

    if (existingBirthday != null && existingBirthday.isNotEmpty) {
      _birthday = DateTime.tryParse(existingBirthday);
    }

    // Load existing customer source when editing.
    final String? existingTags = widget.existingCustomer?.tags;

    if (existingTags != null) {
      for (final String source in _sources) {
        if (existingTags.contains(source)) {
          _source = source;
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

  /// Generates initials from customer name.
  ///
  /// Example:
  /// Shivam Gurjar -> SG
  /// Anita -> A
  String _initialsFor(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Enter a valid name';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final String digits = value.trim().replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }

    return null;
  }

  /// Email is optional.
  ///
  /// Empty email:
  ///     Valid
  ///
  /// Valid email:
  ///     Valid
  ///
  /// Invalid email:
  ///     Show validation error
  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    // Email is optional.
    if (email.isEmpty) {
      return null;
    }

    final RegExp pattern = RegExp(
      r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$',
    );

    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  Future<void> _save() async {
    // Validate form.
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppSnackBar.show(
        context,
        message: 'Please fix the highlighted fields.',
        type: AppSnackBarType.error,
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    final CustomersDao db = ref.read(customersDaoProvider);

    final String? birthdayIso = _birthday?.toIso8601String().substring(0, 10);

    try {
      if (widget.isEditing) {
        // ------------------------------------
        // UPDATE CUSTOMER
        // ------------------------------------

        final Customer existing = widget.existingCustomer!;

        await db.updateCustomer(
          existing.copyWith(
            name: _nameController.text.trim(),

            phone: _phoneController.text.trim(),

            // Email is optional.
            email: _emailController.text.trim(),

            birthday: Value<String?>(
              birthdayIso,
            ),

            avatarInitials: _initialsFor(
              _nameController.text.trim(),
            ),

            notes: _notesController.text.trim(),
          ),
        );

        if (!mounted) {
          return;
        }

        AppSnackBar.show(
          context,
          message: '${_nameController.text.trim()} updated.',
          type: AppSnackBarType.success,
        );
      } else {
        // ------------------------------------
        // ADD CUSTOMER
        // ------------------------------------

        await db.addCustomer(
          CustomersCompanion.insert(
            name: _nameController.text.trim(),

            phone: _phoneController.text.trim(),

            // Email is optional.
            //
            // Empty email will be saved as an empty string.
            email: Value<String>(
              _emailController.text.trim(),
            ),

            birthday: Value<String?>(
              birthdayIso,
            ),

            joinDate: DateTime.now().toIso8601String().substring(0, 10),

            // No image is being added.
            // We only store initials.
            avatarInitials: _initialsFor(
              _nameController.text.trim(),
            ),

            tags: Value<String>(
              _source == 'Walk-in' ? 'New' : 'New,$_source',
            ),

            notes: Value<String>(
              _notesController.text.trim(),
            ),
          ),
        );

        if (!mounted) {
          return;
        }

        AppSnackBar.show(
          context,
          message: '${_nameController.text.trim()} added.',
          type: AppSnackBarType.success,
        );
      }

      widget.onSaved?.call();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Could not save customer: $e',
          type: AppSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: widget.isEditing ? 'Edit Customer' : 'Add Customer',
        onBack: widget.onBack,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          children: <Widget>[
            // ------------------------------------
            // FULL NAME
            // ------------------------------------

            AppTextField(
              label: 'FULL NAME *',
              hint: 'e.g. Anita Verma',
              controller: _nameController,
              validator: _validateName,
            ),

            SizedBox(height: AppSpacing.md),

            // ------------------------------------
            // PHONE NUMBER
            // ------------------------------------

            AppTextField(
              label: 'PHONE NUMBER *',
              hint: '10-digit mobile number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),

            SizedBox(height: AppSpacing.md),

            // ------------------------------------
            // EMAIL ADDRESS - OPTIONAL
            // ------------------------------------

            AppTextField(
              label: 'EMAIL ADDRESS',
              hint: 'email@example.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),

            SizedBox(height: AppSpacing.md),

            // ------------------------------------
            // BIRTHDAY
            // ------------------------------------

            AppDatePickerField(
              label: 'BIRTHDAY',
              selectedDate: _birthday,
              lastDate: DateTime.now(),
              firstDate: DateTime(
                DateTime.now().year - 90,
              ),
              onDateSelected: (DateTime date) {
                setState(() {
                  _birthday = date;
                });
              },
            ),

            SizedBox(height: AppSpacing.md),

            // ------------------------------------
            // CUSTOMER SOURCE
            // ------------------------------------

            Text(
              'HOW DID THEY FIND US?',
              style: AppTypography.caption(
                const Color(0xFF6B4848),
              ).copyWith(
                fontWeight: AppTypography.bold,
                letterSpacing: 1,
              ),
            ),

            SizedBox(height: AppSpacing.sm),

            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final String source in _sources)
                  ChoiceChip(
                    label: Text(source),
                    selected: _source == source,
                    onSelected: (_) {
                      setState(() {
                        _source = source;
                      });
                    },
                    labelStyle: AppTypography.caption(
                      _source == source
                          ? Colors.white
                          : const Color(0xFF6B4848),
                    ).copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _source == source
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusPill,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: AppSpacing.md),

            // ------------------------------------
            // NOTES & PREFERENCES
            // ------------------------------------

            AppTextField(
              label: 'NOTES & PREFERENCES',
              hint: 'Allergies, preferences, special notes...',
              controller: _notesController,
              maxLines: 3,
            ),

            SizedBox(height: AppSpacing.xl),

            // ------------------------------------
            // SAVE BUTTON
            // ------------------------------------

            AppButton(
              label: widget.isEditing ? 'Save Changes' : 'Save Customer',
              onPressed: _saving ? null : _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
