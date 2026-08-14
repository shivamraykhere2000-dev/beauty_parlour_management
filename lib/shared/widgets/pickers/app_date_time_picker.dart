import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/theme/theme.dart';

/// Themed date-picker field. Tapping opens Flutter's [showDatePicker]
/// styled with the app's colour scheme, and the result renders in the
/// field using the app's standard date format.
class AppDatePickerField extends StatelessWidget {
  const AppDatePickerField({
    required this.selectedDate,
    required this.onDateSelected,
    super.key,
    this.label,
    this.firstDate,
    this.lastDate,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    return _PickerField(
      label: label,
      icon: Icons.calendar_today_outlined,
      valueText: selectedDate?.toDisplayDate ?? 'Select date',
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(DateTime.now().year - 5),
          lastDate: lastDate ?? DateTime(DateTime.now().year + 5),
          builder: (BuildContext context, Widget? child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                  ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onDateSelected(picked);
      },
    );
  }
}

/// Themed time-picker field, styled the same way as [AppDatePickerField].
class AppTimePickerField extends StatelessWidget {
  const AppTimePickerField({
    required this.selectedTime,
    required this.onTimeSelected,
    super.key,
    this.label,
  });

  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return _PickerField(
      label: label,
      icon: Icons.access_time_outlined,
      valueText: selectedTime?.format(context) ?? 'Select time',
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
          builder: (BuildContext context, Widget? child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                  ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onTimeSelected(picked);
      },
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.valueText,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final String valueText;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(label!, style: AppTypography.label(AppColors.foreground)),
          SizedBox(height: AppSpacing.xxs),
        ],
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            height: AppDimensions.inputHeight,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: AppDimensions.iconMd, color: AppColors.mutedForeground),
                SizedBox(width: AppSpacing.sm),
                Text(valueText, style: AppTypography.input(AppColors.foreground)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
