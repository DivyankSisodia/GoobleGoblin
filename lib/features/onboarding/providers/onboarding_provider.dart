import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/DB/db_helper.dart';
import '../../../core/models/card.dart';

/// State for onboarding flow
class OnboardingState {
  final int currentStep;
  final int totalSteps;
  final bool isLoading;
  final String? error;

  // Step 2: Budget
  final double monthlyBudget;

  // Step 3: Money sources
  final double? cashBalance;
  final List<BankCard> debitCards;
  final List<BankCard> creditCards;

  const OnboardingState({
    this.currentStep = 0,
    this.totalSteps = 3,
    this.isLoading = false,
    this.error,
    this.monthlyBudget = 0,
    this.cashBalance,
    this.debitCards = const [],
    this.creditCards = const [],
  });

  OnboardingState copyWith({
    int? currentStep,
    int? totalSteps,
    bool? isLoading,
    String? error,
    double? monthlyBudget,
    double? cashBalance,
    List<BankCard>? debitCards,
    List<BankCard>? creditCards,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      cashBalance: cashBalance ?? this.cashBalance,
      debitCards: debitCards ?? this.debitCards,
      creditCards: creditCards ?? this.creditCards,
    );
  }

  /// Check if can proceed to next step
  bool get canProceed {
    switch (currentStep) {
      case 0: // Welcome - always can proceed
        return true;
      case 1: // Budget - must have budget > 0
        return monthlyBudget > 0;
      case 2: // Money sources - must have at least one source
        return cashBalance != null ||
            debitCards.isNotEmpty ||
            creditCards.isNotEmpty;
      default:
        return true;
    }
  }

  /// Progress percentage (0.0 to 1.0)
  double get progress => totalSteps > 0 ? (currentStep + 1) / totalSteps : 0;

  /// Check if on last step
  bool get isLastStep => currentStep >= totalSteps - 1;

  /// Check if on first step
  bool get isFirstStep => currentStep == 0;

  /// Total money sources count
  int get totalSources {
    int count = 0;
    if (cashBalance != null) count++;
    count += debitCards.length;
    count += creditCards.length;
    return count;
  }
}

/// Onboarding notifier
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final DatabaseHelper _db;

  OnboardingNotifier(this._db) : super(const OnboardingState());

  /// Go to next step
  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Go to previous step
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Set monthly budget
  void setMonthlyBudget(double amount) {
    state = state.copyWith(monthlyBudget: amount);
  }

  /// Set cash balance
  void setCashBalance(double? amount) {
    state = state.copyWith(cashBalance: amount);
  }

  /// Add a debit card
  void addDebitCard(BankCard card) {
    state = state.copyWith(debitCards: [...state.debitCards, card]);
  }

  /// Remove a debit card
  void removeDebitCard(int index) {
    final cards = List<BankCard>.from(state.debitCards);
    if (index >= 0 && index < cards.length) {
      cards.removeAt(index);
      state = state.copyWith(debitCards: cards);
    }
  }

  /// Add a credit card
  void addCreditCard(BankCard card) {
    state = state.copyWith(creditCards: [...state.creditCards, card]);
  }

  /// Remove a credit card
  void removeCreditCard(int index) {
    final cards = List<BankCard>.from(state.creditCards);
    if (index >= 0 && index < cards.length) {
      cards.removeAt(index);
      state = state.copyWith(creditCards: cards);
    }
  }

  /// Complete onboarding - save all data to database
  Future<bool> completeOnboarding() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Save monthly budget
      await _db.setMonthlyBudget(state.monthlyBudget);

      // 2. Seed predefined categories
      await _db.seedPredefinedCategories();

      // 3. Add cash account if provided
      if (state.cashBalance != null) {
        final cashCard = BankCard.cash(balance: state.cashBalance!);
        await _db.insertCard(cashCard);
      }

      // 4. Add debit cards
      bool isFirst = true;
      for (final card in state.debitCards) {
        final cardToInsert = card.copyWith(isPrimary: isFirst);
        await _db.insertCard(cardToInsert);
        isFirst = false;
      }

      // 5. Add credit cards
      for (final card in state.creditCards) {
        final cardToInsert = card.copyWith(
          isPrimary: isFirst && state.debitCards.isEmpty,
        );
        await _db.insertCard(cardToInsert);
        isFirst = false;
      }

      // 6. If only cash and no cards, make cash primary
      if (state.cashBalance != null &&
          state.debitCards.isEmpty &&
          state.creditCards.isEmpty) {
        final cashAccount = await _db.getCashAccount();
        if (cashAccount != null && cashAccount.id != null) {
          await _db.setPrimaryCard(cashAccount.id!);
        }
      }

      // 7. Mark onboarding as completed
      await _db.completeOnboarding();

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save: ${e.toString()}',
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const OnboardingState();
  }
}

/// Provider for onboarding state
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier(DatabaseHelper.instance);
    });

/// Provider to check if onboarding is needed
final isOnboardingNeededProvider = FutureProvider<bool>((ref) async {
  final completed = await DatabaseHelper.instance.isOnboardingCompleted();
  return !completed;
});
