import 'package:intl/intl.dart';

import '../config/app_constants.dart';

/// Date/time formatting shared by every screen that shows appointment
/// times, billing dates or report ranges.
extension DateTimeExtensions on DateTime {
  String get toDisplayDate => DateFormat('dd MMM yyyy').format(this);

  String get toDisplayDateShort => DateFormat('dd MMM').format(this);

  String get toDisplayTime => DateFormat('hh:mm a').format(this);

  String get toDisplayDateTime => DateFormat('dd MMM yyyy, hh:mm a').format(this);

  String get toDayOfWeek => DateFormat('EEEE').format(this);

  bool get isToday {
    final DateTime now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}

/// Currency formatting for billing, expenses and reports — always ₹ with
/// Indian number grouping (e.g. ₹1,23,456).
extension CurrencyExtensions on num {
  String get toCurrency {
    final NumberFormat format = NumberFormat.currency(
      locale: AppConstants.defaultLocale,
      symbol: AppConstants.defaultCurrencySymbol,
      decimalDigits: 0,
    );
    return format.format(this);
  }
}
