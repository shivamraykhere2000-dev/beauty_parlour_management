/// Generic status used across appointments, bills and package usage.
/// Lives in `core` (not a feature or the widget layer) so both domain
/// entities and the `StatusPill` presentation widget can depend on it
/// without domain code importing UI code.
enum AppStatus {
  confirmed,
  pending,
  completed,
  cancelled;

  /// Stored as plain text in Drift columns (`status.name`), so this maps
  /// that string back to the enum value.
  static AppStatus fromName(String name) {
    return AppStatus.values.firstWhere(
      (AppStatus s) => s.name == name,
      orElse: () => AppStatus.pending,
    );
  }
}
