/// App-wide constants that are not colours, dimensions or routes.
/// Anything that would otherwise be a magic string/number belongs here.
abstract class AppConstants {
  const AppConstants._();

  // ---------------------------------------------------------------------
  // App identity
  // ---------------------------------------------------------------------
  static const String appName = 'Blossom';
  static const String appTagline = 'Beauty Parlour Management';
  static const String appVersion = '1.0.0';

  // ---------------------------------------------------------------------
  // Design reference size for flutter_screenutil (matches the Figma
  // mobile frame — 390 x 844 is a standard modern phone canvas).
  // ---------------------------------------------------------------------
  static const double designWidth = 390;
  static const double designHeight = 844;

  // ---------------------------------------------------------------------
  // Local database
  // ---------------------------------------------------------------------
  static const String databaseName = 'blossom_beauty.sqlite';

  // ---------------------------------------------------------------------
  // Shared preference / secure storage keys
  // ---------------------------------------------------------------------
  static const String prefKeyThemeMode = 'pref_theme_mode';
  static const String prefKeyLocale = 'pref_locale';
  static const String prefKeyIsPinSet = 'pref_is_pin_set';
  static const String prefKeyHashedPin = 'pref_hashed_pin';
  static const String prefKeyBiometricEnabled = 'pref_biometric_enabled';
  static const String prefKeyOnboardingComplete = 'pref_onboarding_complete';
  static const String prefKeyLastBackupDate = 'pref_last_backup_date';

  // ---------------------------------------------------------------------
  // Animation durations
  // ---------------------------------------------------------------------
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ---------------------------------------------------------------------
  // Business rules / limits
  // ---------------------------------------------------------------------
  static const int pinLength = 4;
  static const int maxPinAttempts = 5;
  static const String defaultCurrencySymbol = '₹';
  static const String defaultLocale = 'en_IN';

  // ---------------------------------------------------------------------
  // Localization
  // ---------------------------------------------------------------------
  static const String translationsPath = 'assets/translations';
  static const List<String> supportedLocales = <String>['en'];
  static const String prefKeyAutoBackupEnabled = 'auto_backup_enabled';
  static const String prefKeyLastAutoBackupDate = 'last_auto_backup_date';
}
