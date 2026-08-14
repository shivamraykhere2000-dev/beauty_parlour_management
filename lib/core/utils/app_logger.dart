import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Thin, app-wide wrapper around the `logger` package.
///
/// Every layer of the app (data / domain / application / presentation)
/// should log through this class instead of calling `print` or
/// instantiating its own [Logger], so log formatting, levels and output
/// filtering stay consistent and easy to strip from release builds.
class AppLogger {
  AppLogger._internal()
      : _logger = Logger(
          filter: _AppLogFilter(),
          printer: PrettyPrinter(
            methodCount: 1,
            errorMethodCount: 8,
            lineLength: 100,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          ),
          output: ConsoleOutput(),
        );

  static final AppLogger _instance = AppLogger._internal();

  factory AppLogger() => _instance;

  final Logger _logger;

  void debug(String message, {String? tag}) {
    _logger.d(_withTag(message, tag));
  }

  void info(String message, {String? tag}) {
    _logger.i(_withTag(message, tag));
  }

  void warning(String message, {String? tag}) {
    _logger.w(_withTag(message, tag));
  }

  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(_withTag(message, tag), error: error, stackTrace: stackTrace);
  }

  void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.f(_withTag(message, tag), error: error, stackTrace: stackTrace);
  }

  String _withTag(String message, String? tag) {
    return tag == null ? message : '[$tag] $message';
  }
}

/// Suppresses verbose logs in release builds while keeping full logging
/// during development and QA.
class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
    return true;
  }
}

/// Global singleton accessor, e.g. `logger.info('Dashboard loaded');`.
final AppLogger logger = AppLogger();
