/// Small, pure string helpers reused across forms and display widgets.
extension StringExtensions on String {
  bool get isValidPhone {
    final RegExp pattern = RegExp(r'^[6-9]\d{9}$');
    return pattern.hasMatch(trim());
  }

  bool get isValidEmail {
    final RegExp pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    return pattern.hasMatch(trim());
  }

  String get capitalized {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String get initials {
    final List<String> parts =
        trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Nullable-and-empty check, e.g. `value?.isNullOrEmpty ?? true`.
  bool get isNullOrEmpty => trim().isEmpty;
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  String orDefault(String fallback) =>
      (this == null || this!.trim().isEmpty) ? fallback : this!;
}
