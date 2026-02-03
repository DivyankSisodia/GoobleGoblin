/// Base exception for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({required this.message, this.code, this.originalError});

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

/// Database exceptions
class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
  });
}
