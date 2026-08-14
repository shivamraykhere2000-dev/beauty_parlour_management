import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme.dart';

/// Root widget of the application.
///
/// Wires together `flutter_screenutil` (responsive sizing), `go_router`
/// (navigation), `easy_localization` (i18n — English only for now, see
/// `AppConstants.supportedLocales`) and the light/dark [AppTheme].
class BeautyParlourApp extends ConsumerWidget {
  const BeautyParlourApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(
        AppConstants.designWidth,
        AppConstants.designHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: router,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        );
      },
    );
  }
}
