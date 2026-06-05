import '../../core/DB/db_helper.dart';
import '../../core/errors/failures.dart';
import '../../core/models/payment.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/result.dart';
import '../../core/utils/validators.dart';
import 'payment_repository.dart';

/// Implementation of PaymentRepository using SQLite database
class PaymentRepositoryImpl implements PaymentRepository {
  final DatabaseHelper _dbHelper;

  PaymentRepositoryImpl({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  AsyncResult<List<Payment>> getAllPayments() async {
    try {
      final payments = await _dbHelper.getAllPayments();
      return ResultHelper.success(payments);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.fetchFailed('payments', e));
    }
  }

  @override
  AsyncResult<Payment> getPaymentById(int id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT p.*, c.label as category_label, c.svgIcon as category_icon
        FROM payments p
        LEFT JOIN categories c ON p.categoryId = c.id
        WHERE p.id = ?
      ''',
        [id],
      );

      if (result.isEmpty) {
        return ResultHelper.failure(DatabaseFailure.notFound('Payment'));
      }

      return ResultHelper.success(Payment.fromMap(result.first));
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.fetchFailed('payment', e));
    }
  }

  @override
  AsyncResult<int> insertPayment(Payment payment) async {
    // Validate payment data
    final validation = Validators.validatePayment(
      amount: payment.amount,
      date: payment.date,
      cardId: payment.cardId,
      categoryId: payment.categoryId,
    );

    if (validation.isFailure) {
      return ResultHelper.failure(validation.failureValue);
    }

    try {
      final id = await _dbHelper.insertPayment(payment);
      return ResultHelper.success(id);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.insertFailed('payment', e));
    }
  }

  @override
  AsyncResult<bool> updatePayment(Payment payment) async {
    if (payment.id == null) {
      return ResultHelper.failure(
        const ValidationFailure(
          message: 'Payment ID is required for update',
          code: 'VALIDATION_MISSING_ID',
        ),
      );
    }

    // Validate payment data
    final validation = Validators.validatePayment(
      amount: payment.amount,
      date: payment.date,
      cardId: payment.cardId,
      categoryId: payment.categoryId,
    );

    if (validation.isFailure) {
      return ResultHelper.failure(validation.failureValue);
    }

    try {
      final rowsAffected = await _dbHelper.updatePayment(payment);
      return ResultHelper.success(rowsAffected > 0);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.updateFailed('payment', e));
    }
  }

  @override
  AsyncResult<bool> deletePayment(int id) async {
    try {
      final rowsAffected = await _dbHelper.deletePayment(id);
      return ResultHelper.success(rowsAffected > 0);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.deleteFailed('payment', e));
    }
  }

  @override
  AsyncResult<List<Payment>> getPaymentsByCategory(int categoryId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT p.*, c.label as category_label, c.svgIcon as category_icon
        FROM payments p
        LEFT JOIN categories c ON p.categoryId = c.id
        WHERE p.categoryId = ?
        ORDER BY p.date DESC
      ''',
        [categoryId],
      );

      final payments = result.map((json) => Payment.fromMap(json)).toList();
      return ResultHelper.success(payments);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('payments by category', e),
      );
    }
  }

  @override
  AsyncResult<List<Payment>> getPaymentsByCard(int cardId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT p.*, c.label as category_label, c.svgIcon as category_icon
        FROM payments p
        LEFT JOIN categories c ON p.categoryId = c.id
        WHERE p.cardId = ?
        ORDER BY p.date DESC
      ''',
        [cardId],
      );

      final payments = result.map((json) => Payment.fromMap(json)).toList();
      return ResultHelper.success(payments);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('payments by card', e),
      );
    }
  }

  @override
  AsyncResult<List<Payment>> getRecurringPayments() async {
    try {
      final payments = await _dbHelper.getRecurringPayment();
      return ResultHelper.success(payments);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('recurring payments', e),
      );
    }
  }

  @override
  AsyncResult<List<Payment>> getPaymentsInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT p.*, c.label as category_label, c.svgIcon as category_icon
        FROM payments p
        LEFT JOIN categories c ON p.categoryId = c.id
        WHERE date(p.date) BETWEEN date(?) AND date(?)
        ORDER BY p.date DESC
      ''',
        [AppDateUtils.formatIso(start), AppDateUtils.formatIso(end)],
      );

      final payments = result.map((json) => Payment.fromMap(json)).toList();
      return ResultHelper.success(payments);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('payments in range', e),
      );
    }
  }

  @override
  AsyncResult<List<Payment>> getCurrentMonthPayments() async {
    final start = AppDateUtils.startOfMonth;
    final end = AppDateUtils.endOfMonth;
    return getPaymentsInRange(start, end);
  }

  @override
  AsyncResult<double> getCurrentMonthSpending() async {
    try {
      final db = await _dbHelper.database;
      final yearMonth = AppDateUtils.currentYearMonth;

      final result = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM payments
        WHERE strftime('%Y-%m', date) = ?
      ''',
        [yearMonth],
      );

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      return ResultHelper.success(total);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('current month spending', e),
      );
    }
  }

  @override
  AsyncResult<List<DailySpendingData>> getDailySpending(int days) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          date(date) as day,
          SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as total,
          COUNT(*) as count
        FROM payments
        WHERE date >= date('now', '-$days days')
          AND isDeleted = 0
        GROUP BY date(date)
        ORDER BY day ASC
      ''');

      final data = result
          .map(
            (row) => DailySpendingData(
              date: DateTime.parse(row['day'] as String),
              amount: (row['total'] as num?)?.toDouble() ?? 0.0,
              transactionCount: (row['count'] as int?) ?? 0,
            ),
          )
          .toList();

      return ResultHelper.success(data);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('daily spending', e),
      );
    }
  }

  @override
  AsyncResult<List<CategorySpendingData>> getCategorySpending({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (startDate != null && endDate != null) {
        whereClause = 'date(p.date) BETWEEN date(?) AND date(?)';
        whereArgs = [
          AppDateUtils.formatIso(startDate),
          AppDateUtils.formatIso(endDate),
        ];
      }

      // Build where clause with isDeleted filter
      final filteredWhereClause = whereClause == '1=1'
          ? 'p.isDeleted = 0'
          : '$whereClause AND p.isDeleted = 0';

      // First get total spending for percentage calculation
      final totalResult = await db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM payments p
        WHERE $filteredWhereClause
      ''', whereArgs);

      final totalSpending =
          (totalResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Get category breakdown
      final result = await db.rawQuery('''
        SELECT 
          COALESCE(c.id, 0) as categoryId,
          COALESCE(c.label, 'Uncategorized') as categoryName,
          COALESCE(c.svgIcon, 'category') as categoryIcon,
          SUM(CASE WHEN p.isIncome = 0 THEN p.amount ELSE 0 END) as totalAmount,
          COUNT(p.id) as transactionCount
        FROM payments p
        LEFT JOIN categories c ON p.categoryId = c.id
        WHERE $filteredWhereClause
        GROUP BY p.categoryId
        HAVING totalAmount > 0
        ORDER BY totalAmount DESC
      ''', whereArgs);

      final data = result.map((row) {
        final amount = (row['totalAmount'] as num?)?.toDouble() ?? 0.0;
        return CategorySpendingData(
          categoryId: row['categoryId'] as int,
          categoryName: row['categoryName'] as String,
          categoryIcon: row['categoryIcon'] as String,
          amount: amount,
          transactionCount: (row['transactionCount'] as int?) ?? 0,
          percentage: totalSpending > 0 ? (amount / totalSpending) * 100 : 0,
        );
      }).toList();

      return ResultHelper.success(data);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('category spending', e),
      );
    }
  }

  @override
  AsyncResult<SpendingAnalytics> getSpendingAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Default to current month if no dates provided
      final start = startDate ?? AppDateUtils.startOfMonth;
      final end = endDate ?? AppDateUtils.endOfMonth;
      final startStr = AppDateUtils.formatIso(start);
      final endStr = AppDateUtils.formatIso(end);

// Get basic stats (expenses only)
      final statsResult = await db.rawQuery(
        '''
        SELECT 
          COALESCE(SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END), 0) as totalSpending,
          COALESCE(AVG(CASE WHEN isIncome = 0 THEN amount ELSE NULL END), 0) as avgTransaction,
          COUNT(*) as transactionCount
        FROM payments
        WHERE date(date) BETWEEN date(?) AND date(?)
          AND isDeleted = 0
      ''',
        [startStr, endStr],
      );

      final stats = statsResult.first;
      final totalSpending = (stats['totalSpending'] as num?)?.toDouble() ?? 0.0;
      final avgTransaction =
          (stats['avgTransaction'] as num?)?.toDouble() ?? 0.0;
      final transactionCount = (stats['transactionCount'] as int?) ?? 0;

      // Get category breakdown
      final categoryResult = await getCategorySpending(
        startDate: start,
        endDate: end,
      );

      final categoryBreakdown = <String, double>{};
      String? topCategory;
      double? topCategoryAmount;

      if (categoryResult.isSuccess) {
        for (final data in categoryResult.successValue) {
          categoryBreakdown[data.categoryName] = data.amount;
          if (topCategory == null || data.amount > (topCategoryAmount ?? 0)) {
            topCategory = data.categoryName;
            topCategoryAmount = data.amount;
          }
        }
      }

      // Get daily spending (expenses only)
      final dailyResult = await db.rawQuery(
        '''
        SELECT 
          date(date) as day,
          SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as total
        FROM payments
        WHERE date(date) BETWEEN date(?) AND date(?)
          AND isDeleted = 0
        GROUP BY date(date)
        ORDER BY day ASC
      ''',
        [startStr, endStr],
      );

      final dailySpending = <String, double>{};
      for (final row in dailyResult) {
        dailySpending[row['day'] as String] =
            (row['total'] as num?)?.toDouble() ?? 0.0;
      }

      // Get monthly spending (expenses only)
      final monthlyResult = await db.rawQuery('''
        SELECT 
          strftime('%Y-%m', date) as month,
          SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as total
        FROM payments
        WHERE date(date) >= date('now', '-12 months')
          AND isDeleted = 0
        GROUP BY strftime('%Y-%m', date)
        ORDER BY month ASC
      ''');

      final monthlySpending = <String, double>{};
      for (final row in monthlyResult) {
        monthlySpending[row['month'] as String] =
            (row['total'] as num?)?.toDouble() ?? 0.0;
      }

      // Calculate percentage change from previous period
      final previousStart = start.subtract(
        Duration(days: end.difference(start).inDays),
      );
      final previousEnd = start.subtract(const Duration(days: 1));

      final previousResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END), 0) as total
        FROM payments
        WHERE date(date) BETWEEN date(?) AND date(?)
          AND isDeleted = 0
      ''',
        [
          AppDateUtils.formatIso(previousStart),
          AppDateUtils.formatIso(previousEnd),
        ],
      );

      final previousSpending =
          (previousResult.first['total'] as num?)?.toDouble() ?? 0.0;
      final percentageChange = previousSpending > 0
          ? ((totalSpending - previousSpending) / previousSpending) * 100
          : 0.0;

      return ResultHelper.success(
        SpendingAnalytics(
          totalSpending: totalSpending,
          averageTransaction: avgTransaction,
          transactionCount: transactionCount,
          categoryBreakdown: categoryBreakdown,
          dailySpending: dailySpending,
          monthlySpending: monthlySpending,
          percentageChange: percentageChange,
          topCategory: topCategory,
          topCategoryAmount: topCategoryAmount,
        ),
      );
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('spending analytics', e),
      );
    }
  }

  @override
  AsyncResult<List<Payment>> searchPayments(String query) async {
    try {
      final db = await _dbHelper.database;
      final searchPattern = '%$query%';

      final result = await db.rawQuery(
        '''
        SELECT p.*, c.label as category_label, c.svgIcon as category_icon
        FROM payments p
        LEFT JOIN categories c ON p.categoryId = c.id
        WHERE p.note LIKE ? OR c.label LIKE ?
        ORDER BY p.date DESC
      ''',
        [searchPattern, searchPattern],
      );

      final payments = result.map((json) => Payment.fromMap(json)).toList();
      return ResultHelper.success(payments);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('search results', e),
      );
    }
  }

  @override
  AsyncResult<List<Payment>> getUpcomingPayments(int daysAhead) async {
    try {
      // Get recurring payments and calculate next occurrence
      final recurringResult = await getRecurringPayments();

      if (recurringResult.isFailure) {
        return ResultHelper.failure(recurringResult.failureValue);
      }

      final recurring = recurringResult.successValue;
      final upcoming = <Payment>[];
      final now = DateTime.now();
      final cutoff = now.add(Duration(days: daysAhead));

      for (final payment in recurring) {
        final lastDate = AppDateUtils.parseIso(payment.date);
        if (lastDate != null && payment.frequency != null) {
          final nextDate = AppDateUtils.getNextOccurrence(
            lastDate,
            payment.frequency!,
          );
          if (nextDate.isAfter(now) && nextDate.isBefore(cutoff)) {
            upcoming.add(payment);
          }
        }
      }

      // Sort by date
      upcoming.sort((a, b) => a.date.compareTo(b.date));

      return ResultHelper.success(upcoming);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('upcoming payments', e),
      );
    }
  }

  @override
  AsyncResult<bool> deleteAllPayments() async {
    try {
      await _dbHelper.deleteAllData();
      return ResultHelper.success(true);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.deleteFailed('all payments', e),
      );
    }
  }

  @override
  AsyncResult<bool> seedTestData() async {
    try {
      await _dbHelper.seedTestData();
      return ResultHelper.success(true);
    } catch (e) {
      return ResultHelper.failure(
        const DatabaseFailure(
          message: 'Failed to seed test data',
          code: 'SEED_FAILED',
        ),
      );
    }
  }
}
