import 'package:flutter/material.dart';

/// Convenience getters on [BuildContext] to cut down on
/// `Theme.of(context)...` / `MediaQuery.of(context)...` boilerplate
/// throughout the widget tree.
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => Theme.of(this).textTheme;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get screenSize => MediaQuery.sizeOf(this);

  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  bool get isKeyboardVisible => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// True when the shortest side is >= 600dp — used to switch between the
  /// phone and small-tablet layouts.
  bool get isTablet => MediaQuery.sizeOf(this).shortestSide >= 600;

  void hideKeyboard() => FocusScope.of(this).unfocus();

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colorScheme.error : null,
        ),
      );
  }
}
