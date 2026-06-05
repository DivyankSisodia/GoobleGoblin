import '../errors/failures.dart';
import 'result.dart';

/// Validation utility class for common validations
class Validators {
  /// Validates that a string is not empty
  static Result<String> notEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ResultHelper.failure(ValidationFailure.emptyField(fieldName));
    }
    return ResultHelper.success(value.trim());
  }

  /// Validates that an amount is positive
  static Result<double> positiveAmount(double? amount) {
    if (amount == null || amount < 0) {
      return ResultHelper.failure(ValidationFailure.negativeAmount());
    }
    return ResultHelper.success(amount);
  }

  /// Validates that an amount is within a range
  static Result<double> amountInRange(double? amount, double min, double max) {
    if (amount == null || amount < min || amount > max) {
      return ResultHelper.failure(
        ValidationFailure.invalidRange('Amount', min, max),
      );
    }
    return ResultHelper.success(amount);
  }

  /// Validates a date string format
  static Result<DateTime> validDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return ResultHelper.failure(ValidationFailure.emptyField('Date'));
    }
    try {
      final date = DateTime.parse(dateString);
      return ResultHelper.success(date);
    } catch (e) {
      return ResultHelper.failure(ValidationFailure.invalidFormat('Date'));
    }
  }

  /// Validates card data
  static Result<bool> validateCard({
    required String? bankName,
    required double? balance,
    required String? type,
  }) {
    final nameResult = notEmpty(bankName, 'Bank name');
    if (nameResult.isFailure) {
      return ResultHelper.failure(nameResult.failureValue);
    }

    final balanceResult = positiveAmount(balance);
    if (balanceResult.isFailure) {
      return ResultHelper.failure(balanceResult.failureValue);
    }

    final typeResult = notEmpty(type, 'Card type');
    if (typeResult.isFailure) {
      return ResultHelper.failure(typeResult.failureValue);
    }

    if (type != 'Debit' && type != 'Credit' && type != 'Cash') {
      return ResultHelper.failure(
        const ValidationFailure(
          message: 'Card type must be either Debit, Credit, or Cash',
          code: 'VALIDATION_INVALID_CARD_TYPE',
        ),
      );
    }

    return ResultHelper.success(true);
  }

  /// Validates payment data
  static Result<bool> validatePayment({
    required double? amount,
    required String? date,
    required int? cardId,
    required int? categoryId,
  }) {
    final amountResult = positiveAmount(amount);
    if (amountResult.isFailure) {
      return ResultHelper.failure(amountResult.failureValue);
    }

    if (amount == 0) {
      return ResultHelper.failure(
        const ValidationFailure(
          message: 'Amount must be greater than 0',
          code: 'VALIDATION_ZERO_AMOUNT',
        ),
      );
    }

    final dateResult = validDate(date);
    if (dateResult.isFailure) {
      return ResultHelper.failure(dateResult.failureValue);
    }

    if (cardId == null || cardId <= 0) {
      return ResultHelper.failure(
        const ValidationFailure(
          message: 'Please select a valid card',
          code: 'VALIDATION_INVALID_CARD',
        ),
      );
    }

    if (categoryId == null || categoryId <= 0) {
      return ResultHelper.failure(
        const ValidationFailure(
          message: 'Please select a category',
          code: 'VALIDATION_INVALID_CATEGORY',
        ),
      );
    }

    return ResultHelper.success(true);
  }

  /// Validates category data
  static Result<bool> validateCategory({
    required String? label,
    required String? svgIcon,
  }) {
    final labelResult = notEmpty(label, 'Category name');
    if (labelResult.isFailure) {
      return ResultHelper.failure(labelResult.failureValue);
    }

    final iconResult = notEmpty(svgIcon, 'Icon');
    if (iconResult.isFailure) {
      return ResultHelper.failure(iconResult.failureValue);
    }

    return ResultHelper.success(true);
  }
}
