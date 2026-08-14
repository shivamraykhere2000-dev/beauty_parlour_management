import 'package:equatable/equatable.dart';

/// Base type for all domain-layer failures.
///
/// Repositories/use-cases never throw raw exceptions across layer
/// boundaries — they catch them at the data layer and surface a typed
/// [Failure] instead, which the presentation layer can pattern-match on to
/// show the right UI state (see `AppErrorWidget`).
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// Local database (Drift/SQLite) read/write failure.
class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'A local database error occurred.']);
}

/// Input/validation failure (e.g. invalid phone number, empty required
/// field).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// File system failure — reading/writing backups, exported PDFs, picked
/// images, etc.
class FileSystemFailure extends Failure {
  const FileSystemFailure([super.message = 'A file system error occurred.']);
}

/// Failure raised while exporting to / importing from Google Drive.
class BackupFailure extends Failure {
  const BackupFailure([super.message = 'Backup operation failed.']);
}

/// Device permission (camera, storage, notifications) was denied.
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Required permission was denied.']);
}

/// Fallback for anything unexpected — logged with full stack trace, shown
/// to the user as a generic friendly message.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}
