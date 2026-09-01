import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/appointments.dart';

part 'appointments_dao.g.dart';

class CustomerAppointmentSummary {
  final int totalAppointments;
  final int totalAmount;

  const CustomerAppointmentSummary({
    required this.totalAppointments,
    required this.totalAmount,
  });
}

@DriftAccessor(tables: [Appointments])
class AppointmentsDao extends DatabaseAccessor<AppDatabase>
    with _$AppointmentsDaoMixin {
  AppointmentsDao(super.db);
// =========================================================================
  // Appointments
  // =========================================================================

  Stream<List<Appointment>> watchAppointmentsForDate(String date) =>
      (select(appointments)
            ..where((t) => t.date.equals(date))
            ..orderBy(<OrderingTerm Function($AppointmentsTable)>[
              (t) => OrderingTerm.asc(t.time)
            ]))
          .watch();

  Stream<List<Appointment>> watchAllAppointments() => (select(appointments)
        ..orderBy(<OrderingTerm Function($AppointmentsTable)>[
          (t) => OrderingTerm.desc(t.id)
        ]))
      .watch();

  Future<int> addAppointment(AppointmentsCompanion entry) =>
      into(appointments).insert(entry);

  Future<bool> updateAppointment(Appointment entry) =>
      update(appointments).replace(entry);

  Future<void> deleteAppointment(int id) =>
      (delete(appointments)..where((t) => t.id.equals(id))).go();

  Future<CustomerAppointmentSummary> getCustomerAppointmentSummary(
    int customerId,
  ) async {
    final result = await customSelect(
      '''
      SELECT 
        COUNT(*) AS total_appointments,
        COALESCE(SUM(amount), 0) AS total_amount
      FROM appointments
      WHERE customer_id = ?
      ''',
      variables: [
        Variable.withInt(customerId),
      ],
      readsFrom: {appointments},
    ).getSingle();

    return CustomerAppointmentSummary(
      totalAppointments: result.read<int>('total_appointments'),
      totalAmount: result.read<int>('total_amount'),
    );
  }
}
