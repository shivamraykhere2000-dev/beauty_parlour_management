# Features

This directory is intentionally empty in Part 1 — no business modules are
created yet, per the project's build order.

Each future feature (Customers, Appointments, Billing, Services,
Memberships, Packages, Loyalty, Inventory, Expenses, Reports, WhatsApp,
Notifications, Backup, Settings, Dashboard, Auth/PIN, Splash) will be added
as its own folder here, following **feature-first + Clean Architecture**:

```
features/
  <feature_name>/
    presentation/
      screens/        # Full-page widgets, one per route
      widgets/         # Feature-local widgets not reused elsewhere
      providers/       # Riverpod providers/notifiers exposing view state
    application/
      viewmodels/      # MVVM view-models orchestrating use cases
      usecases/        # Single-responsibility application actions
    domain/
      entities/        # Plain Dart domain models (no Drift/UI dependency)
      repositories/     # Abstract repository contracts
    data/
      datasources/      # Drift table + DAO access
      models/           # Drift-generated row <-> domain entity mapping
      repositories/      # Concrete repository implementations
```

Rules every feature module must follow:

- `domain/` never imports Flutter or Drift — it is pure Dart.
- `data/` implements `domain/repositories` contracts and is the only layer
  that talks to `core/database/app_database.dart`.
- `application/` (view-models/use-cases) depends on `domain/`, never
  directly on `data/`.
- `presentation/` depends on `application/` only, and pulls all styling
  from `core/theme` and all reusable UI from `shared/widgets` — never
  hardcoded colours, spacing or dimensions.
- Each feature registers its own repositories/services in
  `core/di/dependency_injection.dart` and its own routes in
  `core/router/app_router.dart` (`_featureRoutes`) when it is built.
- Each feature adds its own Drift `Table` classes to
  `core/database/app_database.dart`'s `@DriftDatabase(tables: [...])` list
  and bumps `schemaVersion` with a corresponding migration step.

Screens identified from the Figma export, to be built feature-by-feature in
upcoming parts: Splash, PIN Lock, Dashboard, Customers, Customer Detail, Add
Customer, Appointments, Book Appointment, Billing, Services, Memberships,
Packages, Loyalty, Inventory, Expenses, Reports, WhatsApp, Notifications,
Backup, Settings.
