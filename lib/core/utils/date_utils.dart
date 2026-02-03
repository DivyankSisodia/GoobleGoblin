import 'package:intl/intl.dart';

/// Date utility class for common date operations
class AppDateUtils {
  // Private constructor
  AppDateUtils._();

  /// Format patterns
  static const String isoFormat = 'yyyy-MM-dd';
  static const String displayFormat = 'MMM dd, yyyy';
  static const String monthYearFormat = 'MMM yyyy';
  static const String yearMonthFormat = 'yyyy-MM';
  static const String timeFormat = 'HH:mm';
  static const String fullFormat = 'MMM dd, yyyy HH:mm';
  static const String dayFormat = 'EEE';
  static const String dayOfMonthFormat = 'dd';

  /// Get current date as ISO string
  static String get nowIso => DateTime.now().toIso8601String();

  /// Get today's date at midnight
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get start of current month
  static DateTime get startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Get end of current month
  static DateTime get endOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  /// Get start of current week (Monday)
  static DateTime get startOfWeek {
    final now = DateTime.now();
    final weekday = now.weekday;
    return DateTime(now.year, now.month, now.day - (weekday - 1));
  }

  /// Get year-month string for current date
  static String get currentYearMonth {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Format date to display string
  static String formatDisplay(DateTime date) {
    return DateFormat(displayFormat).format(date);
  }

  /// Format date to ISO string (date only)
  static String formatIso(DateTime date) {
    return DateFormat(isoFormat).format(date);
  }

  /// Format date to month-year string
  static String formatMonthYear(DateTime date) {
    return DateFormat(monthYearFormat).format(date);
  }

  /// Format date to year-month string for database
  static String formatYearMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Parse ISO date string
  static DateTime? parseIso(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get relative time string (e.g., "2 days ago", "Today")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is in current month
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Get list of dates in a date range
  static List<DateTime> getDateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = start;
    while (!current.isAfter(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  /// Get list of last N days
  static List<DateTime> getLastNDays(int n) {
    return List.generate(n, (i) => today.subtract(Duration(days: n - 1 - i)));
  }

  /// Get list of last N months
  static List<DateTime> getLastNMonths(int n) {
    final now = DateTime.now();
    return List.generate(n, (i) {
      final month = now.month - (n - 1 - i);
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;
      return DateTime(year, adjustedMonth, 1);
    });
  }

  /// Get day of week name (abbreviated)
  static String getDayName(DateTime date) {
    return DateFormat(dayFormat).format(date);
  }

  /// Get month name
  static String getMonthName(DateTime date, {bool abbreviated = true}) {
    return DateFormat(abbreviated ? 'MMM' : 'MMMM').format(date);
  }

  /// Get days remaining in month
  static int getDaysRemainingInMonth() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return lastDay.day - now.day;
  }

  /// Calculate next occurrence based on frequency
  static DateTime getNextOccurrence(DateTime lastDate, String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return lastDate.add(const Duration(days: 1));
      case 'weekly':
        return lastDate.add(const Duration(days: 7));
      case 'biweekly':
        return lastDate.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
      case 'quarterly':
        return DateTime(lastDate.year, lastDate.month + 3, lastDate.day);
      case 'yearly':
        return DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
      default:
        return lastDate.add(const Duration(days: 30));
    }
  }
}
