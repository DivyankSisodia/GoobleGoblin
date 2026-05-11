import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/DB/db_helper.dart';

import 'cards_provider.dart';

// ============================================================
// BALANCE VISIBILITY TOGGLE
// ============================================================

/// Toggles visibility of sensitive balance/amount values across the app.
/// true = visible, false = hidden (shows ••••••).
final balanceVisibilityProvider = StateProvider<bool>((ref) => true);

// ============================================================
// BALANCE INCLUSION TOGGLES
// ============================================================

/// When true, Cash account balance is added to the displayed total.
final balanceIncludeCashProvider = StateProvider<bool>((ref) => false);

/// When true, Credit Card used amount is subtracted from the displayed total.
/// Only shown / meaningful when there are credit card transactions.
final balanceSubtractCreditProvider = StateProvider<bool>((ref) => false);

// ============================================================
// COMPUTED BALANCE PROVIDERS
// ============================================================

/// Sum of all Debit Card balances.
final debitBalanceOnlyProvider = Provider<double>((ref) {
  final state = ref.watch(cardsProvider);
  return state.debitBalance;
});

/// Sum of all Cash account balances.
final cashBalanceProvider = Provider<double>((ref) {
  final state = ref.watch(cardsProvider);
  return state.cards
      .where((c) => c.isCash)
      .fold<double>(0.0, (sum, c) => sum + c.balance);
});

/// Sum of all Credit Card used amounts (what is owed / spent on credit).
final creditUsedAmountProvider = Provider<double>((ref) {
  final state = ref.watch(cardsProvider);
  return state.creditCards.fold<double>(0.0, (sum, c) => sum + c.usedAmount);
});

/// Whether any Credit Card has a non-zero used amount
/// (i.e. transactions have occurred on credit cards).
final hasCreditTransactionsProvider = Provider<bool>((ref) {
  final state = ref.watch(cardsProvider);
  return state.creditCards.any((c) => c.usedAmount > 0);
});

/// The current displayed balance derived from toggle states.
///
/// Base = debit card balance.
/// If [balanceIncludeCashProvider] is true, cash is added.
/// If [balanceSubtractCreditProvider] is true, credit used amount is subtracted.
final displayBalanceProvider = Provider<double>((ref) {
  final cardsState = ref.watch(cardsProvider);
  final showCash = ref.watch(balanceIncludeCashProvider);
  final showCredit = ref.watch(balanceSubtractCreditProvider);

  double balance = cardsState.debitBalance;

  if (showCash) {
    balance += cardsState.cards
        .where((c) => c.isCash)
        .fold<double>(0.0, (sum, c) => sum + c.balance);
  }

  if (showCredit) {
    final creditUsed = cardsState.creditCards.fold<double>(
      0.0,
      (sum, c) => sum + c.usedAmount,
    );
    balance -= creditUsed;
  }

  return balance;
});

// ============================================================
// MONTHLY BUDGET
// ============================================================

/// Fetches the monthly budget from the database.
final monthlyBudgetProvider = FutureProvider<double>((ref) async {
  return DatabaseHelper.instance.getMonthlyBudget();
});

/// Writes a new monthly budget to the database and invalidates the provider.
final monthlyBudgetActionProvider = FutureProvider.family<void, double>((
  ref,
  newBudget,
) async {
  await DatabaseHelper.instance.setMonthlyBudget(newBudget);
  ref.invalidate(monthlyBudgetProvider);
});
