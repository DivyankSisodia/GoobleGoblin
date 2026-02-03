import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        return (now.subtract(const Duration(days: 7)), now);
      case AnalyticsPeriod.month:
        return (DateTime(now.year, now.month, 1), now);
      case AnalyticsPeriod.quarter:
        return (DateTime(now.year, now.month - 2, 1), now);
      case AnalyticsPeriod.year:
        return (DateTime(now.year, 1, 1), now);
      case AnalyticsPeriod.all:
        return (DateTime(2020, 1, 1), now);
    }
  }
}

/// State for analytics
class AnalyticsState {
  final SpendingAnalytics? analytics;
  final List<CategorySpendingData> categoryData;
  final List<DailySpendingData> dailyData;
  final AnalyticsPeriod selectedPeriod;
  final bool isLoading;
  final String? errorMessage;

  const AnalyticsState({
    this.analytics,
    this.categoryData = const [],
    this.dailyData = const [],
    this.selectedPeriod = AnalyticsPeriod.month,
    this.isLoading = false,
    this.errorMessage,
  });

  AnalyticsState copyWith({
    SpendingAnalytics? analytics,
    List<CategorySpendingData>? categoryData,
    List<DailySpendingData>? dailyData,
    AnalyticsPeriod? selectedPeriod,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AnalyticsState(
      analytics: analytics ?? this.analytics,
      categoryData: categoryData ?? this.categoryData,
      dailyData: dailyData ?? this.dailyData,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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

    // Combine results
    List<CategorySpendingData> categoryList = [];
    if (categoryResult.isSuccess) {
      categoryList = categoryResult.successValue;
    }

    List<DailySpendingData> dailyList = [];
    if (dailyResult.isSuccess) {
      dailyList = dailyResult.successValue;
    }

    state = state.copyWith(
      analytics: analyticsResult.getOrNull(),
      categoryData: categoryList,
      dailyData: dailyList,
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

/// Provider for heatmap data (last 30 days)
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
