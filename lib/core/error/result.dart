import 'failure.dart';

/// A lightweight `Result`/`Either` replacement used across the
/// application/domain layers so failures are values, not exceptions.
///
/// Usage:
/// ```dart
/// final Result<Customer> result = await repository.getCustomer(id);
/// result.when(
///   success: (customer) => ...,
///   failure: (failure) => ...,
/// );
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = ResultFailure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultFailure<T>;

  /// Pattern-matches the result, forcing both branches to be handled.
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final Result<T> self = this;
    if (self is Success<T>) return success(self.data);
    if (self is ResultFailure<T>) return failure(self.failure);
    throw StateError('Unreachable: unknown Result subtype.');
  }

  /// Returns the success value or `null` if this is a failure.
  T? get dataOrNull {
    final Result<T> self = this;
    return self is Success<T> ? self.data : null;
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);

  final Failure failure;
}
