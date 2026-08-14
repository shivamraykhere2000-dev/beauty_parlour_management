import '../core/enums/app_status.dart';

/// Plain data holder for a customer row. UI-only mock model — not a domain
/// entity or Drift row.
class MockCustomer {
  const MockCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.birthday,
    required this.joinDate,
    required this.visits,
    required this.totalSpent,
    required this.points,
    required this.membership,
    required this.avatar,
    required this.lastVisit,
    required this.tags,
    required this.notes,
  });

  final int id;
  final String name;
  final String phone;
  final String email;
  final String birthday;
  final String joinDate;
  final int visits;
  final int totalSpent;
  final int points;
  final String? membership;
  final String avatar;
  final String lastVisit;
  final List<String> tags;
  final String notes;
}

class MockAppointment {
  const MockAppointment({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.service,
    required this.time,
    required this.durationMinutes,
    required this.amount,
    required this.status,
  });

  final int id;
  final int customerId;
  final String customerName;
  final String service;
  final String time;
  final int durationMinutes;
  final int amount;
  final AppStatus status;
}

class MockService {
  const MockService({
    required this.id,
    required this.category,
    required this.name,
    required this.price,
    required this.duration,
    required this.popular,
  });

  final int id;
  final String category;
  final String name;
  final int price;
  final int duration;
  final bool popular;
}

class MockInventoryItem {
  const MockInventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.minStock,
    required this.unit,
    required this.price,
  });

  final int id;
  final String name;
  final String category;
  final int stock;
  final int minStock;
  final String unit;
  final int price;
}

class MockExpense {
  const MockExpense({
    required this.id,
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    required this.method,
  });

  final int id;
  final String date;
  final String category;
  final String description;
  final int amount;
  final String method;
}

class MockMembershipPlan {
  const MockMembershipPlan({
    required this.name,
    required this.price,
    required this.validityMonths,
    required this.discountPercent,
    required this.perks,
    required this.emoji,
  });

  final String name;
  final int price;
  final int validityMonths;
  final int discountPercent;
  final List<String> perks;
  final String emoji;
}

class MockPackage {
  const MockPackage({
    required this.name,
    required this.services,
    required this.originalPrice,
    required this.price,
    required this.validityDays,
    required this.sold,
  });

  final String name;
  final List<String> services;
  final int originalPrice;
  final int price;
  final int validityDays;
  final int sold;
}

class MockWhatsAppTemplate {
  const MockWhatsAppTemplate({
    required this.id,
    required this.type,
    required this.emoji,
    required this.body,
  });

  final int id;
  final String type;
  final String emoji;
  final String body;
}

class MockExpenseCategory {
  const MockExpenseCategory({required this.name, required this.value, required this.colorHex});

  final String name;
  final int value;
  final int colorHex;
}

/// ── Demo data mirroring the Figma export 1:1 ──────────────────────────────
abstract class MockData {
  const MockData._();

  static const List<MockCustomer> customers = <MockCustomer>[
    MockCustomer(id: 1, name: 'Anita Verma', phone: '9876543210', email: 'anita@gmail.com', birthday: '1990-07-15', joinDate: '2022-03-10', visits: 42, totalSpent: 38400, points: 920, membership: 'Gold', avatar: 'AV', lastVisit: '2025-07-10', tags: <String>['VIP', 'Regular'], notes: 'Prefers morning slots. Sensitive scalp — use mild shampoo only.'),
    MockCustomer(id: 2, name: 'Kavya Reddy', phone: '9812345678', email: 'kavya.r@email.com', birthday: '1995-03-22', joinDate: '2023-01-15', visits: 18, totalSpent: 14200, points: 340, membership: 'Silver', avatar: 'KR', lastVisit: '2025-07-08', tags: <String>['Regular'], notes: 'Loves hair treatments. Always does gel manicure.'),
    MockCustomer(id: 3, name: 'Sunita Patel', phone: '9765432198', email: '', birthday: '1985-11-08', joinDate: '2021-06-20', visits: 67, totalSpent: 72300, points: 1640, membership: 'Platinum', avatar: 'SP', lastVisit: '2025-07-12', tags: <String>['VIP', 'Member'], notes: 'Long-time customer. Monthly hair color appointment.'),
    MockCustomer(id: 4, name: 'Meera Joshi', phone: '9834567890', email: 'meera.j@gmail.com', birthday: '1992-07-13', joinDate: '2024-02-01', visits: 8, totalSpent: 5600, points: 120, membership: null, avatar: 'MJ', lastVisit: '2025-06-28', tags: <String>['New'], notes: 'Referred by Anita Verma.'),
    MockCustomer(id: 5, name: 'Ritu Agarwal', phone: '9898989898', email: 'ritu.a@yahoo.com', birthday: '1988-12-25', joinDate: '2022-09-14', visits: 29, totalSpent: 24800, points: 580, membership: 'Silver', avatar: 'RA', lastVisit: '2025-07-05', tags: <String>['Regular'], notes: 'Chocolate wax only please.'),
    MockCustomer(id: 6, name: 'Deepika Nair', phone: '9923456789', email: 'deepika.n@gmail.com', birthday: '1997-04-18', joinDate: '2023-08-22', visits: 12, totalSpent: 9800, points: 210, membership: null, avatar: 'DN', lastVisit: '2025-07-11', tags: <String>['Active'], notes: ''),
    MockCustomer(id: 7, name: 'Pooja Mehta', phone: '9741258963', email: 'pooja.m@email.com', birthday: '1991-09-30', joinDate: '2021-12-05', visits: 55, totalSpent: 61200, points: 1380, membership: 'Gold', avatar: 'PM', lastVisit: '2025-07-13', tags: <String>['VIP', 'Regular'], notes: 'Allergy alert — Loreal only, no other hair dye brands.'),
    MockCustomer(id: 8, name: 'Sonia Khanna', phone: '9654321780', email: '', birthday: '1994-06-07', joinDate: '2024-05-18', visits: 5, totalSpent: 3200, points: 70, membership: null, avatar: 'SK', lastVisit: '2025-07-01', tags: <String>['New'], notes: ''),
    MockCustomer(id: 9, name: 'Rekha Singh', phone: '9567891234', email: 'rekha.s@gmail.com', birthday: '1983-02-14', joinDate: '2020-11-30', visits: 89, totalSpent: 95400, points: 2100, membership: 'Platinum', avatar: 'RS', lastVisit: '2025-07-13', tags: <String>['VIP', 'Member', 'Regular'], notes: 'Best customer. Monthly packages pre-booked.'),
    MockCustomer(id: 10, name: 'Lakshmi Iyer', phone: '9845671230', email: 'lakshmi.i@gmail.com', birthday: '1986-08-03', joinDate: '2022-07-01', visits: 34, totalSpent: 31600, points: 720, membership: 'Silver', avatar: 'LI', lastVisit: '2025-07-09', tags: <String>['Regular'], notes: 'Traditional treatment preferences.'),
  ];

  static const List<MockAppointment> todayAppointments = <MockAppointment>[
    MockAppointment(id: 1, customerId: 7, customerName: 'Pooja Mehta', service: 'Hair Color + Blowdry', time: '10:00 AM', durationMinutes: 120, amount: 2400, status: AppStatus.completed),
    MockAppointment(id: 2, customerId: 9, customerName: 'Rekha Singh', service: 'Facial + Threading', time: '11:30 AM', durationMinutes: 90, amount: 1200, status: AppStatus.completed),
    MockAppointment(id: 3, customerId: 4, customerName: 'Meera Joshi', service: 'Haircut & Style', time: '02:00 PM', durationMinutes: 60, amount: 600, status: AppStatus.confirmed),
    MockAppointment(id: 4, customerId: 6, customerName: 'Deepika Nair', service: 'Manicure + Pedicure', time: '03:30 PM', durationMinutes: 75, amount: 900, status: AppStatus.confirmed),
    MockAppointment(id: 5, customerId: 1, customerName: 'Anita Verma', service: 'Hair Spa + Head Massage', time: '05:00 PM', durationMinutes: 90, amount: 1400, status: AppStatus.pending),
  ];

  static const List<({String month, int revenue})> monthlyRevenue = <({String month, int revenue})>[
    (month: 'Jan', revenue: 42000), (month: 'Feb', revenue: 38500),
    (month: 'Mar', revenue: 54200), (month: 'Apr', revenue: 48700),
    (month: 'May', revenue: 61300), (month: 'Jun', revenue: 67800),
    (month: 'Jul', revenue: 29400),
  ];

  static const List<({String name, int revenue})> topServices = <({String name, int revenue})>[
    (name: 'Haircut', revenue: 46500), (name: 'Facial', revenue: 62000),
    (name: 'Hair Color', revenue: 86400), (name: 'Hair Spa', revenue: 46800),
    (name: 'Manicure', revenue: 28400),
  ];

  static const List<MockExpenseCategory> expenseCategories = <MockExpenseCategory>[
    MockExpenseCategory(name: 'Products', value: 18000, colorHex: 0xFFA0526A),
    MockExpenseCategory(name: 'Rent', value: 12000, colorHex: 0xFFC9956C),
    MockExpenseCategory(name: 'Staff', value: 8000, colorHex: 0xFFE8B4B8),
    MockExpenseCategory(name: 'Utilities', value: 3200, colorHex: 0xFFF5D5C0),
    MockExpenseCategory(name: 'Misc', value: 2100, colorHex: 0xFFDEB8C0),
  ];

  static const List<MockService> services = <MockService>[
    MockService(id: 1, category: 'Hair', name: 'Haircut & Style', price: 500, duration: 60, popular: true),
    MockService(id: 2, category: 'Hair', name: 'Hair Color (Global)', price: 1800, duration: 120, popular: true),
    MockService(id: 3, category: 'Hair', name: 'Highlights / Balayage', price: 3500, duration: 150, popular: false),
    MockService(id: 4, category: 'Hair', name: 'Blowdry & Style', price: 400, duration: 45, popular: true),
    MockService(id: 5, category: 'Hair', name: 'Hair Spa', price: 1200, duration: 60, popular: true),
    MockService(id: 6, category: 'Hair', name: 'Keratin Treatment', price: 5000, duration: 180, popular: false),
    MockService(id: 7, category: 'Hair', name: 'Head Massage', price: 350, duration: 30, popular: false),
    MockService(id: 8, category: 'Skin', name: 'Gold Facial', price: 1200, duration: 60, popular: true),
    MockService(id: 9, category: 'Skin', name: 'Cleanup', price: 600, duration: 45, popular: true),
    MockService(id: 10, category: 'Skin', name: 'Threading - Eyebrows', price: 60, duration: 10, popular: true),
    MockService(id: 11, category: 'Skin', name: 'Threading - Full Face', price: 150, duration: 20, popular: false),
    MockService(id: 12, category: 'Skin', name: 'Waxing - Full Arms', price: 300, duration: 30, popular: true),
    MockService(id: 13, category: 'Skin', name: 'Waxing - Full Legs', price: 500, duration: 45, popular: true),
    MockService(id: 14, category: 'Nails', name: 'Manicure (Regular)', price: 400, duration: 45, popular: true),
    MockService(id: 15, category: 'Nails', name: 'Gel Manicure', price: 700, duration: 60, popular: true),
    MockService(id: 16, category: 'Nails', name: 'Pedicure (Regular)', price: 600, duration: 60, popular: true),
    MockService(id: 17, category: 'Nails', name: 'Pedicure (Spa)', price: 900, duration: 75, popular: false),
    MockService(id: 18, category: 'Others', name: 'Mehendi (Hands)', price: 300, duration: 60, popular: false),
    MockService(id: 19, category: 'Others', name: 'Bridal Package', price: 15000, duration: 480, popular: false),
  ];

  static const List<MockInventoryItem> inventory = <MockInventoryItem>[
    MockInventoryItem(id: 1, name: 'Loreal Hair Color - Ash Blonde', category: 'Hair', stock: 3, minStock: 5, unit: 'box', price: 850),
    MockInventoryItem(id: 2, name: 'Schwarzkopf Developer 20V', category: 'Hair', stock: 8, minStock: 4, unit: 'bottle', price: 420),
    MockInventoryItem(id: 3, name: 'Gold Facial Kit', category: 'Skin', stock: 2, minStock: 5, unit: 'kit', price: 650),
    MockInventoryItem(id: 4, name: 'Rica Chocolate Wax', category: 'Skin', stock: 6, minStock: 3, unit: 'can', price: 380),
    MockInventoryItem(id: 5, name: 'OPI Nail Polish Set', category: 'Nails', stock: 1, minStock: 2, unit: 'set', price: 1200),
    MockInventoryItem(id: 6, name: 'Keratin Treatment Solution', category: 'Hair', stock: 4, minStock: 2, unit: 'bottle', price: 1800),
    MockInventoryItem(id: 7, name: 'Hair Spa Cream', category: 'Hair', stock: 12, minStock: 5, unit: 'jar', price: 450),
    MockInventoryItem(id: 8, name: 'Rose Water Toner', category: 'Skin', stock: 9, minStock: 3, unit: 'bottle', price: 220),
    MockInventoryItem(id: 9, name: 'Nail Gel (UV)', category: 'Nails', stock: 3, minStock: 4, unit: 'tube', price: 680),
    MockInventoryItem(id: 10, name: 'Threading Cotton Rolls', category: 'Others', stock: 20, minStock: 10, unit: 'roll', price: 45),
  ];

  static const List<MockExpense> expenses = <MockExpense>[
    MockExpense(id: 1, date: '12 Jul 2025', category: 'Products', description: 'Loreal Color Stock Refill', amount: 4200, method: 'UPI'),
    MockExpense(id: 2, date: '10 Jul 2025', category: 'Utilities', description: 'Electricity Bill', amount: 2800, method: 'Online'),
    MockExpense(id: 3, date: '08 Jul 2025', category: 'Products', description: 'Rica Wax Supply', amount: 1900, method: 'Cash'),
    MockExpense(id: 4, date: '05 Jul 2025', category: 'Rent', description: 'Monthly Rent', amount: 12000, method: 'Bank Transfer'),
    MockExpense(id: 5, date: '03 Jul 2025', category: 'Misc', description: 'Cleaning Supplies', amount: 450, method: 'Cash'),
    MockExpense(id: 6, date: '01 Jul 2025', category: 'Staff', description: 'Assistant Salary', amount: 8000, method: 'Bank Transfer'),
  ];

  static const List<MockMembershipPlan> memberships = <MockMembershipPlan>[
    MockMembershipPlan(name: 'Silver', price: 2999, validityMonths: 6, discountPercent: 10, perks: <String>['Free Threading x4', '10% off all services'], emoji: '⭐'),
    MockMembershipPlan(name: 'Gold', price: 5999, validityMonths: 12, discountPercent: 15, perks: <String>['Free Threading x12', '15% off all services', 'Priority booking'], emoji: '🥇'),
    MockMembershipPlan(name: 'Platinum', price: 9999, validityMonths: 12, discountPercent: 20, perks: <String>['Unlimited Threading', '20% off all services', 'Priority booking', 'Free monthly facial'], emoji: '💎'),
  ];

  static const List<MockPackage> packages = <MockPackage>[
    MockPackage(name: 'Bridal Glow', services: <String>['Gold Facial x3', 'Threading x5', 'Manicure x2', 'Pedicure x2'], originalPrice: 8400, price: 6500, validityDays: 90, sold: 8),
    MockPackage(name: 'Monthly Refresh', services: <String>['Haircut', 'Hair Spa', 'Cleanup', 'Threading x4'], originalPrice: 2550, price: 1999, validityDays: 30, sold: 24),
    MockPackage(name: 'Nail Care Duo', services: <String>['Gel Manicure', 'Spa Pedicure', 'Nail Art'], originalPrice: 2400, price: 1800, validityDays: 60, sold: 15),
    MockPackage(name: 'Hair Transformation', services: <String>['Haircut', 'Hair Color', 'Hair Spa', 'Blowdry'], originalPrice: 3900, price: 2999, validityDays: 45, sold: 11),
  ];

  static const List<MockWhatsAppTemplate> waTemplates = <MockWhatsAppTemplate>[
    MockWhatsAppTemplate(id: 1, type: 'Appointment Confirmation', emoji: '📅', body: 'Hi {{name}}! Your appointment at Blossom Beauty Studio is confirmed for {{date}} at {{time}} for {{service}}. We look forward to seeing you! 💅\n\nReply CANCEL to cancel.'),
    MockWhatsAppTemplate(id: 2, type: 'Birthday Wishes', emoji: '🎂', body: 'Happy Birthday {{name}}! 🎉🌸\n\nWishing you a day as beautiful as you are! As a special birthday gift, enjoy 20% OFF your next visit this week.\n\nBook now: 📞 9876543210'),
    MockWhatsAppTemplate(id: 3, type: 'Festival Offer', emoji: '🪔', body: '🌟 Festival Special at Blossom Beauty Studio 🌟\n\n✨ 15% off all services this week\n💄 Complimentary threading on visits above ₹1000\n\nBook now! 📞 9876543210'),
    MockWhatsAppTemplate(id: 4, type: 'Thank You Message', emoji: '💝', body: 'Thank you for visiting Blossom Beauty Studio, {{name}}! 🌸\n\nHope you loved your {{service}}. Bill: ₹{{amount}}.\n\nSee you again soon! ⭐ Rate us on Google!'),
    MockWhatsAppTemplate(id: 5, type: 'Bill Sharing', emoji: '🧾', body: 'Hi {{name}},\n\nInvoice — Blossom Beauty Studio 🧾\nDate: {{date}}\nServices: {{services}}\n\n💅 Total: ₹{{amount}}\nPayment: {{method}}\n\nThank you! 💕'),
    MockWhatsAppTemplate(id: 6, type: 'Package Expiry Reminder', emoji: '⏰', body: 'Hi {{name}},\n\nYour {{package}} package expires in {{days}} days. You have {{remaining}} sessions left.\n\nBook now to use them! 📞 9876543210'),
  ];
}
