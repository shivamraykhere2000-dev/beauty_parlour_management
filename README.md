# Blossom — Beauty Parlour Management (Part 1: Architecture Foundation)

Offline-first Flutter app for a single beauty parlour owner. No backend, no
Firebase, no REST APIs — all data lives locally in SQLite via **Drift**.

This is **Part 1 only**: the production-ready architecture skeleton. No
business feature modules (Customers, Billing, Appointments, ...) have been
generated yet — see `lib/features/README.md` for what's coming and the
structure each feature will follow.

## Stack

Flutter (latest stable) · Dart · Riverpod · GetIt · Drift · go_router ·
flutter_local_notifications · pdf/printing · fl_chart · Google Drive backup ·
url_launcher (WhatsApp) · flutter_screenutil · easy_localization

## Architecture

Clean Architecture + Feature-First, MVVM on the presentation side:

```
lib/
  main.dart                    # Entrypoint: DI, error handling, i18n bootstrap
  app.dart                     # MaterialApp.router, theme, ScreenUtilInit

  core/
    config/                    # app_constants, route_constants, asset_constants
    theme/                     # color/typography/spacing/dimensions, light/dark ThemeData
    router/                    # app_router.dart (go_router config)
    di/                        # dependency_injection.dart (GetIt)
    database/                  # app_database.dart (Drift, no tables yet)
    error/                     # Failure, Result<T>, GlobalErrorHandler
    utils/                     # app_logger.dart
    extensions/                # context/string/datetime extensions

  shared/
    widgets/                   # AppButton, AppTextField, AppCard, AppDialog,
                                # LoadingWidget, EmptyWidget, AppSearchBar,
                                # AppTopBar, ConfirmationDialog, date/time pickers

  features/                    # Empty — feature-first modules land here next
```

## Design source

UI is recreated pixel-for-pixel from the uploaded Figma export. Every
colour, font and radius in `core/theme/` was pulled directly from the
export's `theme.css` design tokens — headings use **Playfair Display**,
body copy uses **DM Sans**, brand primary is `#A0526A` on a warm
`#FDF8F5` background.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates app_database.g.dart
flutter run
```

Font files (`Playfair Display`, `DM Sans`) referenced in `pubspec.yaml`
under `assets/fonts/` need to be added — download the `.ttf` weights from
Google Fonts and drop them in that folder before building.

## What's next

Each subsequent part adds one feature module end-to-end (domain → data →
application → presentation), wires its routes into `app_router.dart`, its
repositories/services into `dependency_injection.dart`, and its tables into
`app_database.dart`. Planned order follows the screens found in the Figma
export: Splash & PIN Lock → Dashboard → Customers → Appointments → Billing →
Services/Memberships/Packages/Loyalty → Inventory → Expenses → Reports →
WhatsApp → Notifications → Backup → Settings.
