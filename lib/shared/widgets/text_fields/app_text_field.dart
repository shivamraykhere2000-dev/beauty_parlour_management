import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme.dart';

/// Standard text input used across every form in the app (Add Customer,
/// Book Appointment, Billing, Settings, ...). Wraps the app's
/// `InputDecorationTheme` and adds label/error/prefix-icon conveniences so
/// screens don't repeat decoration boilerplate.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.validator,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(label!, style: AppTypography.label(AppColors.foreground)),
          SizedBox(height: AppSpacing.xxs),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onTap: onTap,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: AppTypography.input(AppColors.foreground),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: AppDimensions.iconMd)
                : null,
            suffixIcon: suffixIcon,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
