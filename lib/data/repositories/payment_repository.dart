import '../../core/models/payment.dart';
import '../../core/utils/result.dart';

/// Analytics data for spending insights
class SpendingAnalytics {
  final double totalSpending;
  final double averageTransaction;
  final int transactionCount;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> dailySpending;
  final Map<String, double> monthlySpending;
  final double percentageChange;
  final String? topCategory;
  final double? topCategoryAmount;

  const SpendingAnalytics({
    required this.totalSpending,
    required this.averageTransaction,
    required this.transactionCount,
    required this.categoryBreakdown,
    required this.dailySpending,
    required this.monthlySpending,
    required this.percentageChange,
    this.topCategory,
    this.topCategoryAmount,
  });

  factory SpendingAnalytics.empty() {
    return const SpendingAnalytics(
      totalSpending: 0,
      averageTransaction: 0,
      transactionCount: 0,
      categoryBreakdown: {},
      dailySpending: {},
      monthlySpending: {},
      percentageChange: 0,
    );
  }
}

/// Daily spending data point
class DailySpendingData {
  final DateTime date;
  final double amount;
  final int transactionCount;

  const DailySpendingData({
    required this.date,
    required this.amount,
    required this.transactionCount,
  });
}

/// Category spending data
class CategorySpendingData {
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final double amount;
  final int transactionCount;
  final double percentage;

  const CategorySpendingData({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.transactionCount,
    required this.percentage,
  });
}

/// Abstract repository interface for payment operations
abstract class PaymentRepository {
  /// Get all payments
  AsyncResult<List<Payment>> getAllPayments();

  /// Get payment by id
  AsyncResult<Payment> getPaymentById(int id);

  /// Insert a new payment
  AsyncResult<int> insertPayment(Payment payment);

  /// Update an existing payment
  AsyncResult<bool> updatePayment(Payment payment);

  /// Delete a payment
  AsyncResult<bool> deletePayment(int id);

  /// Get payments by category
  AsyncResult<List<Payment>> getPaymentsByCategory(int categoryId);

  /// Get payments by card
  AsyncResult<List<Payment>> getPaymentsByCard(int cardId);

  /// Get recurring payments
  AsyncResult<List<Payment>> getRecurringPayments();

  /// Get payments within date range
  AsyncResult<List<Payment>> getPaymentsInRange(DateTime start, DateTime end);

  /// Get payments for current month
  AsyncResult<List<Payment>> getCurrentMonthPayments();

  /// Get total spending for current month
  AsyncResult<double> getCurrentMonthSpending();

  /// Get daily spending data for the last N days
  AsyncResult<List<DailySpendingData>> getDailySpending(int days);

  /// Get category-wise spending for a date range
  AsyncResult<List<CategorySpendingData>> getCategorySpending({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get spending analytics
  AsyncResult<SpendingAnalytics> getSpendingAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Search payments by note
  AsyncResult<List<Payment>> searchPayments(String query);

  /// Get upcoming payments (recurring payments due soon)
  AsyncResult<List<Payment>> getUpcomingPayments(int daysAhead);

  /// Delete all payments
  AsyncResult<bool> deleteAllPayments();

  /// Seed test data
  AsyncResult<bool> seedTestData();
}
