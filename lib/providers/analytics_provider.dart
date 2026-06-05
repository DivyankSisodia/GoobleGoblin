import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/category.dart';
import '../../core/models/payment.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/result.dart';

/// Provider for analytics repository
final analyticsRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl();
});

/// Time period for analytics
enum AnalyticsPeriod { week, month, quarter, year, all }

extension AnalyticsPeriodX on AnalyticsPeriod {
  String get label {
    switch (this) {
      case AnalyticsPeriod.week:
        return '7 Days';
      case AnalyticsPeriod.month:
        return 'This Month';
      case AnalyticsPeriod.quarter:
        return '3 Months';
      case AnalyticsPeriod.year:
        return 'This Year';
      case AnalyticsPeriod.all:
        return 'All Time';
    }
  }

  (DateTime, DateTime) get dateRange {
    final now = DateTime.now();
    switch (this) {
      case AnalyticsPeriod.week:
        // Include 7 days ahead so future-dated transactions this week appear
        return (
          now.subtract(const Duration(days: 7)),
          now.add(const Duration(days: 7)),
        );
      case AnalyticsPeriod.month:
        // Billing cycle: 7th of current month → 6th of next month
        if (now.day >= 7) {
          return (
            DateTime(now.year, now.month, 7),
            DateTime(now.year, now.month + 1, 6, 23, 59, 59),
          );
        }
        return (
          DateTime(now.year, now.month - 1, 7),
          DateTime(now.year, now.month, 6, 23, 59, 59),
        );
      case AnalyticsPeriod.quarter:
        // End of 3 months from start of the quarter window
        return (
          DateTime(now.year, now.month - 2, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case AnalyticsPeriod.year:
        // End of the current year
        return (
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case AnalyticsPeriod.all:
        // Far future so no future transaction is ever excluded
        return (DateTime(2020, 1, 1), DateTime(2100, 12, 31));
    }
  }
}

/// Spending grouped by merchant/service keywords found in transaction notes.
class NoteKeywordSpendingData {
  final String keyword;
  final String label;
  final double amount;
  final int transactionCount;

  const NoteKeywordSpendingData({
    required this.keyword,
    required this.label,
    required this.amount,
    required this.transactionCount,
  });
}

/// Monthly income vs expense data point for graphs.
class IncomeExpenseMonth {
  final String month;
  final double income;
  final double expense;

  const IncomeExpenseMonth({
    required this.month,
    required this.income,
    required this.expense,
  });
}

/// State for analytics
class AnalyticsState {
  final SpendingAnalytics? analytics;
  final List<CategorySpendingData> categoryData;
  final List<DailySpendingData> dailyData;
  final List<NoteKeywordSpendingData> noteKeywordData;
  final AnalyticsPeriod selectedPeriod;
  final bool isLoading;
  final String? errorMessage;

  /// Category breakdown derived from recurring payments (per-occurrence amounts)
  final List<CategorySpendingData> recurringCategoryData;

  /// Total of future-dated one-time scheduled payments
  final double scheduledFutureTotal;

  /// Number of upcoming recurring payment occurrences within the next 30 days
  final int upcomingRecurringCount;

  /// Monthly income vs expense data for graphs
  final List<IncomeExpenseMonth> incomeExpenseData;

  /// Total income for the selected period
  final double totalIncome;

  const AnalyticsState({
    this.analytics,
    this.categoryData = const [],
    this.dailyData = const [],
    this.noteKeywordData = const [],
    this.selectedPeriod = AnalyticsPeriod.month,
    this.isLoading = false,
    this.errorMessage,
    this.recurringCategoryData = const [],
    this.scheduledFutureTotal = 0,
    this.upcomingRecurringCount = 0,
    this.incomeExpenseData = const [],
    this.totalIncome = 0,
  });

  AnalyticsState copyWith({
    SpendingAnalytics? analytics,
    List<CategorySpendingData>? categoryData,
    List<DailySpendingData>? dailyData,
    List<NoteKeywordSpendingData>? noteKeywordData,
    AnalyticsPeriod? selectedPeriod,
    bool? isLoading,
    String? errorMessage,
    List<CategorySpendingData>? recurringCategoryData,
    double? scheduledFutureTotal,
    int? upcomingRecurringCount,
    List<IncomeExpenseMonth>? incomeExpenseData,
    double? totalIncome,
  }) {
    return AnalyticsState(
      analytics: analytics ?? this.analytics,
      categoryData: categoryData ?? this.categoryData,
      dailyData: dailyData ?? this.dailyData,
      noteKeywordData: noteKeywordData ?? this.noteKeywordData,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      recurringCategoryData:
          recurringCategoryData ?? this.recurringCategoryData,
      scheduledFutureTotal: scheduledFutureTotal ?? this.scheduledFutureTotal,
      upcomingRecurringCount:
          upcomingRecurringCount ?? this.upcomingRecurringCount,
      incomeExpenseData: incomeExpenseData ?? this.incomeExpenseData,
      totalIncome: totalIncome ?? this.totalIncome,
    );
  }

  /// Get spending trend (positive = spending more, negative = spending less)
  double get spendingTrend => analytics?.percentageChange ?? 0;

  /// Check if spending is increasing
  bool get isSpendingIncreasing => spendingTrend > 0;

  /// Get max daily spending for normalization
  double get maxDailySpending {
    if (dailyData.isEmpty) return 0;
    return dailyData.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
  }

  /// Get average daily spending
  double get averageDailySpending {
    if (dailyData.isEmpty) return 0;
    final total = dailyData.fold(0.0, (sum, d) => sum + d.amount);
    return total / dailyData.length;
  }

  /// Get spending intensity for a specific day (0.0 to 1.0)
  double getSpendingIntensity(DateTime date) {
    if (maxDailySpending == 0) return 0;

    final dayData = dailyData
        .where(
          (d) =>
              d.date.year == date.year &&
              d.date.month == date.month &&
              d.date.day == date.day,
        )
        .firstOrNull;

    if (dayData == null) return 0;
    return (dayData.amount / maxDailySpending).clamp(0.0, 1.0);
  }
}

/// Analytics notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final PaymentRepository _repository;

  AnalyticsNotifier(this._repository) : super(const AnalyticsState()) {
    loadAnalytics();
  }

  /// Load analytics for selected period
  Future<void> loadAnalytics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final (startDate, endDate) = state.selectedPeriod.dateRange;

    // Load spending analytics
    final analyticsResult = await _repository.getSpendingAnalytics(
      startDate: startDate,
      endDate: endDate,
    );

    // Load category data
    final categoryResult = await _repository.getCategorySpending(
      startDate: startDate,
      endDate: endDate,
    );

    // Load daily data
    final days = endDate.difference(startDate).inDays + 1;
    final dailyResult = await _repository.getDailySpending(days);

    // Load recurring payments for separate pie breakdown
    final recurringResult = await _repository.getRecurringPayments();

    // Load all payments to compute future-dated scheduled total
    final allPaymentsResult = await _repository.getAllPayments();

    // Combine results
    List<CategorySpendingData> categoryList = [];
    if (categoryResult.isSuccess) {
      categoryList = categoryResult.successValue;
    }

    List<DailySpendingData> dailyList = [];
    if (dailyResult.isSuccess) {
      dailyList = dailyResult.successValue;
    }

    // Build recurring category breakdown
    final recurringCategoryList = <CategorySpendingData>[];
    int upcomingRecurringCount = 0;
    if (recurringResult.isSuccess) {
      final recurring = recurringResult.successValue;
      final grouped = <int, Map<String, dynamic>>{};
      double recurringTotal = 0;
      final now = DateTime.now();
      final cutoff = now.add(const Duration(days: 30));

      for (final p in recurring) {
        final catId = p.categoryId ?? 0;
        final catName = p.category?.label ?? 'Uncategorized';
        final catIcon = p.category?.svgIcon ?? p.subcategory?.svgIcon ?? '';
        grouped[catId] ??= {
          'name': catName,
          'icon': catIcon,
          'amount': 0.0,
          'count': 0,
        };
        grouped[catId]!['amount'] =
            (grouped[catId]!['amount'] as double) + p.amount;
        grouped[catId]!['count'] = (grouped[catId]!['count'] as int) + 1;
        recurringTotal += p.amount;

        // Count occurrences due in the next 30 days
        final lastDate = AppDateUtils.parseIso(p.date);
        if (lastDate != null && p.frequency != null) {
          final next = AppDateUtils.getNextOccurrence(lastDate, p.frequency!);
          if (next.isAfter(now) && next.isBefore(cutoff)) {
            upcomingRecurringCount++;
          }
        }
      }

      for (final entry in grouped.entries) {
        final amt = entry.value['amount'] as double;
        recurringCategoryList.add(
          CategorySpendingData(
            categoryId: entry.key,
            categoryName: entry.value['name'] as String,
            categoryIcon: entry.value['icon'] as String,
            amount: amt,
            transactionCount: entry.value['count'] as int,
            percentage: recurringTotal > 0 ? (amt / recurringTotal) * 100 : 0,
          ),
        );
      }
      recurringCategoryList.sort((a, b) => b.amount.compareTo(a.amount));
    }

    // Compute future-dated scheduled one-time payments total
    double scheduledFutureTotal = 0;
    List<NoteKeywordSpendingData> noteKeywordList = [];
    double totalIncome = 0;
    List<IncomeExpenseMonth> incomeExpenseList = [];
    if (allPaymentsResult.isSuccess) {
      final now = DateTime.now();
      final allPayments = allPaymentsResult.successValue;
      scheduledFutureTotal = allPayments
          .where(
            (p) =>
                !p.isRecurring &&
                !p.isDeleted &&
                (AppDateUtils.parseIso(p.date)?.isAfter(now) ?? false),
          )
          .fold(0.0, (sum, p) => sum + p.amount);
      noteKeywordList = _buildNoteKeywordData(
        allPayments,
        startDate: startDate,
        endDate: endDate,
      );

      // Total income for period
      totalIncome = allPayments
          .where((p) {
            if (p.isDeleted) return false;
            final date = AppDateUtils.parseIso(p.date);
            return p.isIncome && date != null && !date.isBefore(startDate) && !date.isAfter(endDate);
          })
          .fold(0.0, (sum, p) => sum + p.amount);

      // Build monthly income vs expense data (last 6 months)
      final monthlyMap = <String, ({double income, double expense})>{};
      for (final p in allPayments) {
        if (p.isDeleted) continue;
        final date = AppDateUtils.parseIso(p.date);
        if (date == null) continue;
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        final current = monthlyMap[key] ?? (income: 0.0, expense: 0.0);
        if (p.isIncome) {
          monthlyMap[key] = (income: current.income + p.amount, expense: current.expense);
        } else {
          monthlyMap[key] = (income: current.income, expense: current.expense + p.amount);
        }
      }
      final sortedKeys = monthlyMap.keys.toList()..sort();
      final last6 = sortedKeys.length > 6 ? sortedKeys.sublist(sortedKeys.length - 6) : sortedKeys;
      incomeExpenseList = last6.map((key) {
        final data = monthlyMap[key]!;
        return IncomeExpenseMonth(month: key, income: data.income, expense: data.expense);
      }).toList();
    }

    state = state.copyWith(
      analytics: analyticsResult.getOrNull(),
      categoryData: categoryList,
      dailyData: dailyList,
      noteKeywordData: noteKeywordList,
      recurringCategoryData: recurringCategoryList,
      scheduledFutureTotal: scheduledFutureTotal,
      upcomingRecurringCount: upcomingRecurringCount,
      incomeExpenseData: incomeExpenseList,
      totalIncome: totalIncome,
      isLoading: false,
      errorMessage: analyticsResult.isFailure
          ? analyticsResult.failureValue.message
          : null,
    );
  }

  /// Change analytics period
  Future<void> setPeriod(AnalyticsPeriod period) async {
    state = state.copyWith(selectedPeriod: period);
    await loadAnalytics();
  }

  /// Refresh analytics
  Future<void> refresh() async {
    await loadAnalytics();
  }

  List<NoteKeywordSpendingData> _buildNoteKeywordData(
    List<Payment> payments, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final grouped = <String, ({double amount, int count})>{};

    for (final payment in payments) {
      if (payment.isDeleted) continue;
      final date = AppDateUtils.parseIso(payment.date);
      if (date == null || date.isBefore(startDate) || date.isAfter(endDate)) {
        continue;
      }

      final note = payment.note?.toLowerCase() ?? '';
      if (note.isEmpty) continue;

      for (final keyword in DefaultCategories.transactionNoteKeywords) {
        if (!note.contains(keyword)) continue;
        final current = grouped[keyword] ?? (amount: 0.0, count: 0);
        grouped[keyword] = (
          amount: current.amount + payment.amount,
          count: current.count + 1,
        );
        break;
      }
    }

    final data = grouped.entries
        .map(
          (entry) => NoteKeywordSpendingData(
            keyword: entry.key,
            label: _titleCase(entry.key),
            amount: entry.value.amount,
            transactionCount: entry.value.count,
          ),
        )
        .toList();

    data.sort((a, b) => b.amount.compareTo(a.amount));
    return data;
  }

  String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

/// Main analytics provider
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
      final repository = ref.watch(analyticsRepositoryProvider);
      return AnalyticsNotifier(repository);
    });

/// Provider for category spending data
final categorySpendingProvider = Provider<List<CategorySpendingData>>((ref) {
  final state = ref.watch(analyticsProvider);
  return state.categoryData;
});

/// Provider for daily spending data
final dailySpendingProvider = Provider<List<DailySpendingData>>((ref) {
  final state = ref.watch(analyticsProvider);
  return state.dailyData;
});

/// Provider for spending trend
final spendingTrendProvider = Provider<double>((ref) {
  final state = ref.watch(analyticsProvider);
  return state.spendingTrend;
});

/// Provider for heatmap data (last 30 days) — kept for legacy consumers
final spendingHeatmapProvider = Provider<Map<DateTime, double>>((ref) {
  final state = ref.watch(analyticsProvider);
  final heatmap = <DateTime, double>{};

  // Generate last 30 days
  final days = AppDateUtils.getLastNDays(30);
  for (final day in days) {
    heatmap[day] = state.getSpendingIntensity(day);
  }

  return heatmap;
});

/// Always loads the last 17 weeks of daily spending amounts for the GitHub-style heatmap.
/// Independent of the selected analytics period filter.
final heatmapDailyAmountProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final repo = ref.read(analyticsRepositoryProvider);
  const totalDays = 17 * 7; // 119 days
  final result = await repo.getDailySpending(totalDays);
  if (result.isFailure) return {};
  return {
    for (final d in result.successValue)
      '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}':
          d.amount,
  };
});
