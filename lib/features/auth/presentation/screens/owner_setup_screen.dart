import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/database/daos/settings_dao.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// First-run owner setup — shown once, in place of the old PIN page, the
/// very first time the app is opened (i.e. `Settings.app_initialized` is
/// not yet `'true'`). Collects the salon owner's profile and writes it
/// into the existing key-value `Settings` table
/// (`owner_name` / `owner_phone` / `owner_gmail` / `business_name`), then
/// marks the app initialized so this screen never shows again.
class OwnerSetupScreen extends ConsumerStatefulWidget {
  const OwnerSetupScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  ConsumerState<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends ConsumerState<OwnerSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _gmailController = TextEditingController();
  final TextEditingController _businessController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _phoneController.dispose();
    _gmailController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Your name is required';
    if (v.trim().length < 2) return 'Enter a valid name';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final String digits = v.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit phone number';
    return null;
  }

  String? _validateGmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Gmail is required';
    final RegExp pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!pattern.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final SettingsDao db = ref.read(settingsDaoProvider);
    try {
      await db.setSetting('first_name', _firstnameController.text.trim());
      await db.setSetting('last_name', _lastnameController.text.trim());
      await db.setSetting('owner_phone', _phoneController.text.trim());
      await db.setSetting('owner_gmail', _gmailController.text.trim());
      await db.setSetting(
          'business_name',
          _businessController.text.trim().isEmpty
              ? 'Blossom Beauty Studio'
              : _businessController.text.trim());
      await db.setSetting('app_initialized', 'true');
      if (!mounted) return;
      widget.onComplete?.call();
    } catch (e) {
      if (mounted)
        AppSnackBar.show(context,
            message: 'Could not save setup: $e', type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
              decoration:
                  const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 72.r,
                    height: 72.r,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.storefront_outlined,
                        color: Colors.white, size: 32),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text('Welcome to Blossom',
                      style: AppTypography.h2(Colors.white)),
                  SizedBox(height: 4.h),
                  Text("Let's set up your salon profile",
                      style: AppTypography.bodySmall(
                          Colors.white.withValues(alpha: 0.75))),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xl,
                      AppSpacing.md, AppSpacing.xxxl),
                  children: <Widget>[
                    _ValidatedField(
                        label: 'YOUR FIRST NAME *',
                        hint: 'e.g. Priya',
                        controller: _firstnameController,
                        validator: _validateName,
                        icon: Icons.person_outline),
                    SizedBox(height: AppSpacing.md),
                    _ValidatedField(
                        label: 'YOUR LAST NAME *',
                        hint: 'e.g. Sharma',
                        controller: _lastnameController,
                        validator: _validateName,
                        icon: Icons.person_outline),
                    SizedBox(height: AppSpacing.md),
                    _ValidatedField(
                        label: 'PHONE NUMBER *',
                        hint: '10-digit mobile number',
                        controller: _phoneController,
                        validator: _validatePhone,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                    SizedBox(height: AppSpacing.md),
                    _ValidatedField(
                        label: 'GMAIL *',
                        hint: 'you@gmail.com',
                        controller: _gmailController,
                        validator: _validateGmail,
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress),
                    SizedBox(height: AppSpacing.md),
                    _ValidatedField(
                        label: 'BUSINESS / SALON NAME',
                        hint: 'e.g. Blossom Beauty Studio',
                        controller: _businessController,
                        icon: Icons.store_outlined),
                    SizedBox(height: AppSpacing.xl),
                    AppButton(
                        label: 'Get Started',
                        onPressed: _saving ? null : _submit,
                        isLoading: _saving),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidatedField extends StatelessWidget {
  const _ValidatedField(
      {required this.label,
      required this.hint,
      required this.controller,
      this.validator,
      this.icon,
      this.keyboardType});

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final IconData? icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTypography.label(AppColors.foreground)),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: AppTypography.input(AppColors.foreground),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                icon != null ? Icon(icon, size: AppDimensions.iconMd) : null,
          ),
        ),
      ],
    );
  }
}
