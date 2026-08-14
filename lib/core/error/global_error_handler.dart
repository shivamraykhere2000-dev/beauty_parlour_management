import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/app_logger.dart';

/// Wires up app-wide error capture so nothing crashes silently.
///
/// Because this app is fully offline with no backend, there is no crash
/// reporting service to forward to — everything is logged locally via
/// [AppLogger]. This is still the single place to plug in a crash reporter
/// later without touching call sites.
abstract class GlobalErrorHandler {
  const GlobalErrorHandler._();

  /// Call once, before `runApp`, from within a `runZonedGuarded` block
  /// (see `main.dart`).
  static void init() {
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.error(
        'FlutterError: ${details.exceptionAsString()}',
        tag: 'GlobalErrorHandler',
        error: details.exception,
        stackTrace: details.stack,
      );
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      logger.error(
        'PlatformDispatcher error',
        tag: 'GlobalErrorHandler',
        error: error,
        stackTrace: stack,
      );
      return true;
    };
  }

  /// Runs [body] inside a guarded zone so uncaught async errors are logged
  /// rather than terminating the isolate.
  static void runGuarded(void Function() body) {
    runZonedGuarded<void>(
      body,
      (Object error, StackTrace stack) {
        logger.error(
          'Uncaught zone error',
          tag: 'GlobalErrorHandler',
          error: error,
          stackTrace: stack,
        );
      },
    );
  }
}
