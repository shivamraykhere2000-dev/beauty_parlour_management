import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_constants.dart';
import 'core/di/dependency_injection.dart';
import 'core/error/global_error_handler.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  GlobalErrorHandler.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    GlobalErrorHandler.init();

    // The app is designed for portrait use on a reception phone/tablet.
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await EasyLocalization.ensureInitialized();
    await configureDependencies();

    logger.info('App bootstrap complete.', tag: 'main');

    runApp(
      EasyLocalization(
        supportedLocales: AppConstants.supportedLocales
            .map((String code) => Locale(code))
            .toList(),
        path: AppConstants.translationsPath,
        fallbackLocale: const Locale('en'),
        child: const ProviderScope(child: BeautyParlourApp()),
      ),
    );
  });
}
