import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../utils/app_logger.dart';

/// Global GetIt service locator instance. Used for framework-level
/// singletons (logger, database, shared preferences) that Riverpod
/// providers then read from via `Provider((ref) => getIt<...>())`.
final GetIt getIt = GetIt.instance;

/// Registers every singleton the app needs before `runApp`.
Future<void> configureDependencies() async {
  if (!getIt.isRegistered<AppLogger>()) {
    getIt.registerSingleton<AppLogger>(logger);
  }

  if (!getIt.isRegistered<AppDatabase>()) {
    getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  }

  if (!getIt.isRegistered<SharedPreferences>()) {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
  }

  logger.info('Dependency injection configured.', tag: 'DI');
}

Future<void> resetDependencies() async {
  await getIt.reset();
}
