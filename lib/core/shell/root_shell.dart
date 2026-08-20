import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/screens/appointments_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/widgets.dart';
import '../config/route_constants.dart';
import '../database/app_database.dart';
import '../providers/path_provider.dart';

/// Hosts the 5 main tabs (Home, Appointments, Clients, Reports, Settings)
/// behind a single persistent [AppBottomNav] + quick-action FAB, matching
/// the Figma app shell. Every other screen (Customer Detail, Add Customer,
/// Book Appointment, Billing, Services, ...) is pushed on top as a full
/// route via `go_router` and intentionally does *not* show the bottom nav,
/// same as the reference design.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell>
    with WidgetsBindingObserver {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check auto-backup every time the app comes back to the
    // foreground, not just on cold start — covers the app being left
    // open in the background across the 24h boundary without a full
    // process restart.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(autoBackupCheckProvider);
    }
  }

  void _handleQuickAction(String label) {
    switch (label) {
      case 'Add Client':
      case 'Customers':
        setState(() => _tabIndex = 2);
      case 'New Appt':
      case 'Appointments':
        context.pushNamed(RouteConstants.bookAppointmentName);
      case 'Billing':
        context.pushNamed(RouteConstants.billingName);
      case 'Inventory':
        context.pushNamed(RouteConstants.inventoryName);
      case 'Expenses':
        context.pushNamed(RouteConstants.expensesName);
      case 'Reports':
        setState(() => _tabIndex = 3);
      case 'WhatsApp':
        context.pushNamed(RouteConstants.whatsappName);
      case 'Services':
        context.pushNamed(RouteConstants.servicesName);
    }
  }

  void _openFabMenu() {
    FabMenu.show(
      context,
      items: <FabMenuItem>[
        FabMenuItem(
            label: 'New Appointment',
            icon: Icons.calendar_today_outlined,
            onTap: () => context.pushNamed(RouteConstants.bookAppointmentName)),
        FabMenuItem(
            label: 'Add Customer',
            icon: Icons.person_add_alt_outlined,
            onTap: () => setState(() => _tabIndex = 2)),
        FabMenuItem(
            label: 'New Expense',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () => context.pushNamed(RouteConstants.expensesName)),
        FabMenuItem(
            label: 'Generate Invoice',
            icon: Icons.credit_card_outlined,
            onTap: () => context.pushNamed(RouteConstants.billingName)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watching (not just invalidating on resume) is what actually makes
    // this run — a FutureProvider with no active watcher never executes,
    // cold start or otherwise.
    ref.watch(autoBackupCheckProvider);

    final List<Widget> tabs = <Widget>[
      DashboardScreen(onQuickAction: _handleQuickAction),
      AppointmentsScreen(
        onBookAppointment: () =>
            context.pushNamed(RouteConstants.bookAppointmentName),
        onBillAppointment: (int appointmentId) =>
            context.pushNamed(RouteConstants.billingName, extra: appointmentId),
      ),
      CustomersScreen(
        onAddCustomer: () => context.pushNamed(RouteConstants.addCustomerName),
        onOpenCustomer: (Customer c) =>
            context.pushNamed(RouteConstants.customerDetailName, extra: c.id),
        onEditCustomer: (Customer c) =>
            context.pushNamed(RouteConstants.addCustomerName, extra: c),
      ),
      const ReportsScreen(),
      SettingsScreen(
        onOpenBackup: () => context.pushNamed(RouteConstants.backupName),
        onOpenNotifications: () =>
            context.pushNamed(RouteConstants.notificationsName),
        onOpenWhatsApp: () => context.pushNamed(RouteConstants.whatsappName),
        onOpenMemberships: () =>
            context.pushNamed(RouteConstants.membershipsName),
        onOpenPackages: () => context.pushNamed(RouteConstants.packagesName),
        onOpenLoyalty: () => context.pushNamed(RouteConstants.loyaltyName),
        onLockNow: () => context.goNamed(RouteConstants.pinLockName),
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: tabs),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFabMenu,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _tabIndex,
        onTap: (int i) => setState(() => _tabIndex = i),
      ),
    );
  }
}
