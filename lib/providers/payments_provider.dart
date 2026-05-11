import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/payment.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/payment_repository_impl.dart';
import 'analytics_provider.dart';
import 'cards_provider.dart';

/// Provider for PaymentRepository
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl();
});

/// State class for payments
class PaymentsState {
  final List<Payment> payments;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? selectedCategoryFilter;
  final DateRange? dateRangeFilter;

  const PaymentsState({
    this.payments = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedCategoryFilter,
    this.dateRangeFilter,
  });

  PaymentsState copyWith({
    List<Payment>? payments,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedCategoryFilter,
    DateRange? dateRangeFilter,
    bool clearCategoryFilter = false,
    bool clearDateFilter = false,
  }) {
    return PaymentsState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryFilter: clearCategoryFilter
          ? null
          : (selectedCategoryFilter ?? this.selectedCategoryFilter),
      dateRangeFilter: clearDateFilter
          ? null
          : (dateRangeFilter ?? this.dateRangeFilter),
    );
  }

  /// Get filtered payments based on current filters
  List<Payment> get filteredPayments {
    var result = payments;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((p) {
        final note = p.note?.toLowerCase() ?? '';
        final category = p.category?.label.toLowerCase() ?? '';
        return note.contains(query) || category.contains(query);
      }).toList();
    }

    // Apply category filter
    if (selectedCategoryFilter != null) {
      result = result
          .where((p) => p.category?.label == selectedCategoryFilter)
          .toList();
    }

    // Apply date range filter
    if (dateRangeFilter != null) {
      result = result.where((p) {
        final date = AppDateUtils.parseIso(p.date);
        if (date == null) return false;
        return date.isAfter(dateRangeFilter!.start) &&
            date.isBefore(dateRangeFilter!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return result;
  }

  /// Get recurring payments
  List<Payment> get recurringPayments =>
      payments.where((p) => p.isRecurring).toList();

  /// Get payments grouped by date (keyed as yyyy-MM-dd ISO strings for reliable parsing)
  Map<String, List<Payment>> get paymentsByDate {
    final grouped = <String, List<Payment>>{};
    for (final payment in filteredPayments) {
      final date = AppDateUtils.parseIso(payment.date);
      if (date != null) {
        // Must use ISO date format so the key can be re-parsed in the UI
        final dateKey = AppDateUtils.formatIso(date);
        grouped.putIfAbsent(dateKey, () => []).add(payment);
      }
    }
    return grouped;
  }

  /// Get recurring payments grouped by date (keyed as yyyy-MM-dd ISO strings)
  Map<String, List<Payment>> get recurringPaymentsByDate {
    final grouped = <String, List<Payment>>{};
    final recurring = payments.where((p) => p.isRecurring);
    for (final payment in recurring) {
      final date = AppDateUtils.parseIso(payment.date);
      if (date != null) {
        final dateKey = AppDateUtils.formatIso(date);
        grouped.putIfAbsent(dateKey, () => []).add(payment);
      }
    }
    return grouped;
  }

  /// Get total spending
  double get totalSpending => payments.fold(0.0, (sum, p) => sum + p.amount);

  /// Get current month spending (based on billing cycle starting 7th)
  double get currentMonthSpending {
    return payments
        .where((p) {
          final date = AppDateUtils.parseIso(p.date);
          return date != null && AppDateUtils.isCurrentBillingCycle(date);
        })
        .fold(0.0, (sum, p) => sum + p.amount);
  }
}

/// Date range for filtering
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});
}

/// Payments notifier using modern Riverpod patterns
class PaymentsNotifier extends StateNotifier<PaymentsState> {
  final PaymentRepository _repository;
  final Ref _ref;

  PaymentsNotifier(this._repository, this._ref) : super(const PaymentsState()) {
    loadPayments();
  }

  /// Load all payments from repository
  Future<void> loadPayments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.getAllPayments();

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (payments) {
        state = state.copyWith(payments: payments, isLoading: false);
      },
    );
  }

  /// Add a new payment
  Future<bool> addPayment(Payment payment) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.insertPayment(payment);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (id) {
        loadPayments();
        // Refresh cards to update balances
        _ref.read(cardsProvider.notifier).loadCards();
        return true;
      },
    );
  }

  /// Update an existing payment
  Future<bool> updatePayment(Payment payment) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.updatePayment(payment);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadPayments();
        _ref.read(cardsProvider.notifier).loadCards();
        return success;
      },
    );
  }

  /// Delete a payment
  Future<bool> deletePayment(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.deletePayment(id);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadPayments();
        _ref.read(cardsProvider.notifier).loadCards();
        return success;
      },
    );
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Set category filter
  void setCategoryFilter(String? category) {
    state = state.copyWith(
      selectedCategoryFilter: category,
      clearCategoryFilter: category == null,
    );
  }

  /// Set date range filter
  void setDateRangeFilter(DateRange? range) {
    state = state.copyWith(
      dateRangeFilter: range,
      clearDateFilter: range == null,
    );
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearCategoryFilter: true,
      clearDateFilter: true,
    );
  }

  /// Delete all payments
  Future<bool> deleteAllPayments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.deleteAllPayments();

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadPayments();
        _ref.read(cardsProvider.notifier).loadCards();
        return success;
      },
    );
  }

  /// Seed test data
  Future<bool> seedTestData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.seedTestData();

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadPayments();
        _ref.read(cardsProvider.notifier).loadCards();
        try {
          _ref.read(analyticsProvider.notifier).refresh();
        } catch (_) {}
        return success;
      },
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Main payments provider
final paymentsProvider = StateNotifierProvider<PaymentsNotifier, PaymentsState>(
  (ref) {
    final repository = ref.watch(paymentRepositoryProvider);
    return PaymentsNotifier(repository, ref);
  },
);

/// Provider for recurring payments
final recurringPaymentsProvider = Provider<List<Payment>>((ref) {
  final state = ref.watch(paymentsProvider);
  return state.recurringPayments;
});

/// Provider for current month spending
final currentMonthSpendingProvider = Provider<double>((ref) {
  final state = ref.watch(paymentsProvider);
  return state.currentMonthSpending;
});

/// Provider for filtered payments
final filteredPaymentsProvider = Provider<List<Payment>>((ref) {
  final state = ref.watch(paymentsProvider);
  return state.filteredPayments;
});

/// Provider for payments grouped by date
final paymentsByDateProvider = Provider<Map<String, List<Payment>>>((ref) {
  final state = ref.watch(paymentsProvider);
  return state.paymentsByDate;
});
