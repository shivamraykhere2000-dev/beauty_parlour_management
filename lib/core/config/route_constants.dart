/// Route path & name constants for go_router.
abstract class RouteConstants {
  const RouteConstants._();

  // Core / shell
  static const String splash = '/splash';
  static const String splashName = 'splash';

  static const String pinLock = '/pin-lock';
  static const String pinLockName = 'pinLock';

  static const String root = '/';
  static const String rootName = 'root';

  // Pushed feature screens (no bottom nav)
  static const String customerDetail = '/customer-detail';
  static const String customerDetailName = 'customerDetail';

  static const String addCustomer = '/add-customer';
  static const String addCustomerName = 'addCustomer';

  static const String bookAppointment = '/book-appointment';
  static const String bookAppointmentName = 'bookAppointment';

  static const String billing = '/billing';
  static const String billingName = 'billing';

  static const String services = '/services';
  static const String servicesName = 'services';

  static const String memberships = '/memberships';
  static const String membershipsName = 'memberships';

  static const String packages = '/packages';
  static const String packagesName = 'packages';

  static const String loyalty = '/loyalty';
  static const String loyaltyName = 'loyalty';

  static const String inventory = '/inventory';
  static const String inventoryName = 'inventory';

  static const String expenses = '/expenses';
  static const String expensesName = 'expenses';

  static const String whatsapp = '/whatsapp';
  static const String whatsappName = 'whatsapp';

  static const String notifications = '/notifications';
  static const String notificationsName = 'notifications';

  static const String backup = '/backup';
  static const String backupName = 'backup';

  // Error / fallback
  static const String notFound = '/not-found';
  static const String notFoundName = 'notFound';
}