import 'package:fpdart/fpdart.dart';
import '../errors/failures.dart';

/// Type alias for Either with Failure on the left and success value on the right
typedef Result<T> = Either<Failure, T>;

/// Type alias for async Result operations
typedef AsyncResult<T> = Future<Result<T>>;

/// Extension methods for Result type
extension ResultX<T> on Result<T> {
  /// Returns true if this is a success result
  bool get isSuccess => isRight();

  /// Returns true if this is a failure result
  bool get isFailure => isLeft();

  /// Gets the success value or throws if failure
  T get successValue => getRight().toNullable()!;

  /// Gets the failure or throws if success
  Failure get failureValue => getLeft().toNullable()!;

  /// Gets the success value or returns the provided default
  T getOrElse(T defaultValue) => fold((_) => defaultValue, (value) => value);

  /// Gets the success value or null
  T? getOrNull() => fold((_) => null, (value) => value);

  /// Maps the success value to a new type
  Result<R> mapSuccess<R>(R Function(T) mapper) => map(mapper);

  /// Maps the failure to a new type
  Result<T> mapFailure(Failure Function(Failure) mapper) => mapLeft(mapper);

  /// Executes callback on success
  Result<T> onSuccess(void Function(T) callback) {
    fold((_) {}, callback);
    return this;
  }

  /// Executes callback on failure
  Result<T> onFailure(void Function(Failure) callback) {
    fold(callback, (_) {});
    return this;
  }
}

/// Helper functions for creating Results
class ResultHelper {
  /// Creates a success result
  static Result<T> success<T>(T value) => Right(value);

  /// Creates a failure result
  static Result<T> failure<T>(Failure failure) => Left(failure);
}
