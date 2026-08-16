import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/screens/book_appointment_screen.dart';
import '../../features/auth/presentation/screens/owner_setup_screen.dart';
import '../../features/auth/presentation/screens/pin_lock_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/backup/presentation/screens/backup_screen.dart';
import '../../features/billing/presentation/screens/billing_screen.dart';
import '../../features/customers/presentation/screens/add_customer_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/loyalty/presentation/screens/loyalty_screen.dart';
import '../../features/memberships/presentation/screens/memberships_screen.dart';
import '../../features/notifications/presentation/screens/notification_screen.dart';
import '../../features/packages/presentation/screens/packages_screen.dart';
import '../../features/services/presentation/screens/services_screen.dart';
import '../../features/whatsapp/presentation/screens/whatsapp_screen.dart';
import '../config/route_constants.dart';
import '../database/app_database.dart';
import '../shell/root_shell.dart';

/// Root [GoRouter] configuration.
///
/// - [RouteConstants.splash] / [RouteConstants.pinLock] boot the app.
/// - [RouteConstants.root] hosts [RootShell] — the persistent bottom-nav
///   shell for Home / Appointments / Clients / Reports / Settings.
/// - Every other route below is a full-screen push *on top of* the shell
///   (so the bottom nav is intentionally hidden on them, matching the
///   Figma design) for screens reached via a quick action, FAB, or a list
///   item (Customer Detail, Add Customer, Book Appointment, Billing,
///   Services, Memberships, Packages, Loyalty, Inventory, Expenses,
///   WhatsApp, Notifications, Backup).
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(
        path: RouteConstants.splash,
        name: RouteConstants.splashName,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: RouteConstants.pinLock,
        name: RouteConstants.pinLockName,
        builder: (BuildContext context, GoRouterState state) =>
            const PinLockScreen(),
      ),
      GoRoute(
        path: RouteConstants.ownerSetup,
        name: RouteConstants.ownerSetupName,
        builder: (BuildContext context, GoRouterState state) =>
            OwnerSetupScreen(
          onComplete: () => context.goNamed(RouteConstants.rootName),
        ),
      ),
      GoRoute(
        path: RouteConstants.root,
        name: RouteConstants.rootName,
        builder: (BuildContext context, GoRouterState state) =>
            const RootShell(),
      ),

      // ---------------------------------------------------------------
      // Customers
      // ---------------------------------------------------------------
      GoRoute(
        path: RouteConstants.customerDetail,
        name: RouteConstants.customerDetailName,
        builder: (BuildContext context, GoRouterState state) {
          final int customerId = state.extra as int;
          return CustomerDetailScreen(
            customerId: customerId,
            onBack: () => context.pop(),
            onBookAppointment: () =>
                context.pushNamed(RouteConstants.bookAppointmentName),
            onEdit: (Customer c) =>
                context.pushNamed(RouteConstants.addCustomerName, extra: c),
          );
        },
      ),
      GoRoute(
        path: RouteConstants.addCustomer,
        name: RouteConstants.addCustomerName,
        builder: (BuildContext context, GoRouterState state) =>
            AddCustomerScreen(
          // existingCustomer: state.extra as Customer?,
          onBack: () => context.pop(),
          onSaved: () => context.pop(),
        ),
      ),

      // ---------------------------------------------------------------
      // Appointments & Billing
      // ---------------------------------------------------------------
      GoRoute(
        path: RouteConstants.bookAppointment,
        name: RouteConstants.bookAppointmentName,
        builder: (BuildContext context, GoRouterState state) =>
            BookAppointmentScreen(
          onBack: () => context.pop(),
          onConfirmed: () => context.pop(),
        ),
      ),
      GoRoute(
        path: RouteConstants.billing,
        name: RouteConstants.billingName,
        builder: (BuildContext context, GoRouterState state) => BillingScreen(
          appointmentId: state.extra as int?,
          onBack: () => context.pop(),
          onCollected: () => context.pop(),
        ),
      ),

      // ---------------------------------------------------------------
      // Catalog: Services, Memberships, Packages, Loyalty
      // ---------------------------------------------------------------
      GoRoute(
        path: RouteConstants.services,
        name: RouteConstants.servicesName,
        builder: (BuildContext context, GoRouterState state) =>
            const ServicesScreen(),
      ),
      GoRoute(
        path: RouteConstants.memberships,
        name: RouteConstants.membershipsName,
        builder: (BuildContext context, GoRouterState state) =>
            MembershipsScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: RouteConstants.packages,
        name: RouteConstants.packagesName,
        builder: (BuildContext context, GoRouterState state) =>
            PackagesScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: RouteConstants.loyalty,
        name: RouteConstants.loyaltyName,
        builder: (BuildContext context, GoRouterState state) =>
            LoyaltyScreen(onBack: () => context.pop()),
      ),

      // ---------------------------------------------------------------
      // Operations: Inventory, Expenses
      // ---------------------------------------------------------------
      GoRoute(
        path: RouteConstants.inventory,
        name: RouteConstants.inventoryName,
        builder: (BuildContext context, GoRouterState state) =>
            InventoryScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: RouteConstants.expenses,
        name: RouteConstants.expensesName,
        builder: (BuildContext context, GoRouterState state) =>
            ExpensesScreen(onBack: () => context.pop()),
      ),

      // ---------------------------------------------------------------
      // Communication & Settings sub-screens
      // ---------------------------------------------------------------
      GoRoute(
        path: RouteConstants.whatsapp,
        name: RouteConstants.whatsappName,
        builder: (BuildContext context, GoRouterState state) =>
            WhatsAppScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: RouteConstants.notifications,
        name: RouteConstants.notificationsName,
        builder: (BuildContext context, GoRouterState state) =>
            NotificationsScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: RouteConstants.backup,
        name: RouteConstants.backupName,
        builder: (BuildContext context, GoRouterState state) =>
            BackupScreen(onBack: () => context.pop()),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});
