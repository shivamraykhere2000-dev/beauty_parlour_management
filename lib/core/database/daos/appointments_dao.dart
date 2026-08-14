import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/appointments.dart';

part 'appointments_dao.g.dart';

@DriftAccessor(tables: [Appointments])
class AppointmentsDao extends DatabaseAccessor<AppDatabase>
    with _$AppointmentsDaoMixin {
  AppointmentsDao(super.db);

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
}
