/// Centralised asset path constants. No widget should ever inline a raw
/// `assets/...` string — reference these instead so a renamed/moved file
/// only needs updating in one place.
abstract class AssetConstants {
  const AssetConstants._();

  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';

  // ---------------------------------------------------------------------
  // Images
  // ---------------------------------------------------------------------
  static const String logo = '$_images/logo.png';
  static const String splashBackground = '$_images/splash_background.png';
  static const String placeholderAvatar = '$_images/placeholder_avatar.png';
  static const String emptyStateGeneric = '$_images/empty_state_generic.png';

  // ---------------------------------------------------------------------
  // Icons
  // ---------------------------------------------------------------------
  static const String icAppLogo = '$_icons/ic_app_logo.svg';
}
