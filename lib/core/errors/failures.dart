/// Base failure class for all app failures
abstract class Failure {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure({required this.message, this.code, this.originalError});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Database-related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory DatabaseFailure.insertFailed(String entity, [dynamic error]) {
    return DatabaseFailure(
      message: 'Failed to insert $entity',
      code: 'DB_INSERT_FAILED',
      originalError: error,
    );
  }

  factory DatabaseFailure.updateFailed(String entity, [dynamic error]) {
    return DatabaseFailure(
      message: 'Failed to update $entity',
      code: 'DB_UPDATE_FAILED',
      originalError: error,
    );
  }

  factory DatabaseFailure.deleteFailed(String entity, [dynamic error]) {
    return DatabaseFailure(
      message: 'Failed to delete $entity',
      code: 'DB_DELETE_FAILED',
      originalError: error,
    );
  }

  factory DatabaseFailure.fetchFailed(String entity, [dynamic error]) {
    return DatabaseFailure(
      message: 'Failed to fetch $entity',
      code: 'DB_FETCH_FAILED',
      originalError: error,
    );
  }

  factory DatabaseFailure.notFound(String entity) {
    return DatabaseFailure(message: '$entity not found', code: 'DB_NOT_FOUND');
  }

  factory DatabaseFailure.transactionFailed([dynamic error]) {
    return DatabaseFailure(
      message: 'Database transaction failed',
      code: 'DB_TRANSACTION_FAILED',
      originalError: error,
    );
  }
}

/// Validation-related failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory ValidationFailure.emptyField(String fieldName) {
    return ValidationFailure(
      message: '$fieldName cannot be empty',
      code: 'VALIDATION_EMPTY_FIELD',
    );
  }

  factory ValidationFailure.invalidFormat(String fieldName) {
    return ValidationFailure(
      message: 'Invalid $fieldName format',
      code: 'VALIDATION_INVALID_FORMAT',
    );
  }

  factory ValidationFailure.invalidRange(String fieldName, num min, num max) {
    return ValidationFailure(
      message: '$fieldName must be between $min and $max',
      code: 'VALIDATION_INVALID_RANGE',
    );
  }

  factory ValidationFailure.negativeAmount() {
    return const ValidationFailure(
      message: 'Amount cannot be negative',
      code: 'VALIDATION_NEGATIVE_AMOUNT',
    );
  }
}

/// Network-related failures (for future use)
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code, super.originalError});
}
