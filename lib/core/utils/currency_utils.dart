import 'package:intl/intl.dart';

/// Currency utility class for formatting amounts in Indian Rupees (₹).
class CurrencyUtils {
  CurrencyUtils._();

  /// Default currency symbol
  static const String defaultSymbol = '₹';

  /// Locale override — always format numbers in Indian style.
  static const String _locale = 'en_IN';

  /// Format amount with ₹ symbol (e.g. ₹1,234.56).
  static String format(
    double amount, {
    String symbol = defaultSymbol,
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.currency(
      locale: _locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  /// Format amount in compact form (e.g. ₹1.5K, ₹2L, ₹1Cr).
  static String formatCompact(double amount, {String symbol = defaultSymbol}) {
    if (amount >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  /// Format amount without decimal places (e.g. ₹1,234).
  static String formatWhole(double amount, {String symbol = defaultSymbol}) {
    final formatter = NumberFormat.currency(
      locale: _locale,
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format amount with sign (+ or -).
  static String formatWithSign(double amount, {String symbol = defaultSymbol}) {
    final sign = amount >= 0 ? '+' : '';
    return '$sign${format(amount, symbol: symbol)}';
  }

  /// Format percentage.
  static String formatPercentage(double value, {int decimalDigits = 1}) {
    return '${value.toStringAsFixed(decimalDigits)}%';
  }

  /// Calculate percentage change.
  static double percentageChange(double oldValue, double newValue) {
    if (oldValue == 0) return newValue == 0 ? 0 : 100;
    return ((newValue - oldValue) / oldValue) * 100;
  }

  /// Format percentage change with sign.
  static String formatPercentageChange(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  /// Parse amount from string (handles ₹, $, commas, spaces).
  static double? parse(String? amountString) {
    if (amountString == null || amountString.isEmpty) return null;

    // Remove currency symbols, commas, and spaces
    final cleaned = amountString.replaceAll(RegExp(r'[₹$,\s]'), '').trim();

    return double.tryParse(cleaned);
  }

  /// Get amount color based on value (positive = green, negative = red).
  static bool isPositive(double amount) => amount >= 0;

  /// Calculate spending rate (amount per day).
  static double calculateDailyRate(double totalAmount, int days) {
    if (days <= 0) return 0;
    return totalAmount / days;
  }

  /// Project month-end spending based on current rate.
  static double projectMonthEnd(
    double currentSpending,
    int daysElapsed,
    int totalDays,
  ) {
    if (daysElapsed <= 0) return currentSpending;
    final dailyRate = currentSpending / daysElapsed;
    return dailyRate * totalDays;
  }
}
