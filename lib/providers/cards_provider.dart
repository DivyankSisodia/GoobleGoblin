import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/card.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/card_repository_impl.dart';

/// Provider for CardRepository
final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepositoryImpl();
});

/// State class for cards
class CardsState {
  final List<BankCard> cards;
  final bool isLoading;
  final String? errorMessage;

  const CardsState({
    this.cards = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CardsState copyWith({
    List<BankCard>? cards,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CardsState(
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Get selected card
  BankCard? get selectedCard {
    try {
      return cards.firstWhere((card) => card.isSelected);
    } catch (e) {
      return null;
    }
  }

  /// Get primary card
  BankCard? get primaryCard {
    try {
      return cards.firstWhere((card) => card.isPrimary);
    } catch (e) {
      return null;
    }
  }

  /// Get debit cards
  List<BankCard> get debitCards => cards.where((c) => c.isDebit).toList();

  /// Get credit cards
  List<BankCard> get creditCards => cards.where((c) => c.isCredit).toList();

  /// Get total balance
  double get totalBalance => cards.fold(0.0, (sum, card) => sum + card.balance);

  /// Get total debit balance
  double get debitBalance =>
      debitCards.fold(0.0, (sum, card) => sum + card.balance);

  /// Get total credit balance
  double get creditBalance =>
      creditCards.fold(0.0, (sum, card) => sum + card.balance);
}

/// Cards notifier using modern Riverpod patterns
class CardsNotifier extends StateNotifier<CardsState> {
  final CardRepository _repository;

  CardsNotifier(this._repository, Ref ref) : super(const CardsState()) {
    loadCards();
  }

  /// Load all cards from repository
  Future<void> loadCards() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.getAllCards();

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (cards) {
        state = state.copyWith(cards: cards, isLoading: false);
      },
    );
  }

  /// Add a new card
  Future<bool> addCard(BankCard card) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.insertCard(card);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (id) {
        loadCards();
        return true;
      },
    );
  }

  /// Update an existing card
  Future<bool> updateCard(BankCard card) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.updateCard(card);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadCards();
        return success;
      },
    );
  }

  /// Delete a card
  Future<bool> deleteCard(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.deleteCard(id);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadCards();
        return success;
      },
    );
  }

  /// Set primary card
  Future<bool> setPrimaryCard(int cardId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.setPrimaryCard(cardId);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadCards();
        return success;
      },
    );
  }

  /// Toggle card selection
  void toggleCardSelection(int? cardId) {
    if (cardId == null) return;

    state = state.copyWith(
      cards: state.cards.map((card) {
        if (card.id == cardId) {
          return card.copyWith(isSelected: !card.isSelected);
        }
        return card.copyWith(isSelected: false);
      }).toList(),
    );
  }

  /// Select a specific card
  void selectCard(int? cardId) {
    if (cardId == null) return;

    state = state.copyWith(
      cards: state.cards.map((card) {
        return card.copyWith(isSelected: card.id == cardId);
      }).toList(),
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Main cards provider
final cardsProvider = StateNotifierProvider<CardsNotifier, CardsState>((ref) {
  final repository = ref.watch(cardRepositoryProvider);
  return CardsNotifier(repository, ref);
});

/// Provider for primary card
final primaryCardProvider = Provider<BankCard?>((ref) {
  final state = ref.watch(cardsProvider);
  return state.primaryCard;
});

/// Provider for total balance
final totalBalanceProvider = Provider<double>((ref) {
  final state = ref.watch(cardsProvider);
  return state.totalBalance;
});

/// Provider for cards by type
final cardsByTypeProvider = Provider.family<List<BankCard>, String>((
  ref,
  type,
) {
  final state = ref.watch(cardsProvider);
  return state.cards.where((c) => c.type == type).toList();
});

/// Credit card summary data
class CreditCardSummary {
  final List<BankCard> creditCards;
  final double totalCreditLimit;
  final double totalUsedAmount;
  final double totalAvailableCredit;
  final double overallUsagePercentage;

  const CreditCardSummary({
    this.creditCards = const [],
    this.totalCreditLimit = 0,
    this.totalUsedAmount = 0,
    this.totalAvailableCredit = 0,
    this.overallUsagePercentage = 0,
  });

  bool get hasCreditCards => creditCards.isNotEmpty;
}

/// Provider for aggregated credit card summary
final creditCardSummaryProvider = Provider<CreditCardSummary>((ref) {
  final state = ref.watch(cardsProvider);
  final creditCards = state.creditCards;

  if (creditCards.isEmpty) {
    return const CreditCardSummary();
  }

  final totalLimit = creditCards.fold(0.0, (sum, c) => sum + c.creditLimit);
  final totalUsed = creditCards.fold(0.0, (sum, c) => sum + c.usedAmount);
  final totalAvailable = creditCards.fold(
    0.0,
    (sum, c) => sum + c.availableCredit,
  );
  final usagePct = totalLimit > 0 ? (totalUsed / totalLimit) : 0.0;

  return CreditCardSummary(
    creditCards: creditCards,
    totalCreditLimit: totalLimit,
    totalUsedAmount: totalUsed,
    totalAvailableCredit: totalAvailable,
    overallUsagePercentage: usagePct.clamp(0.0, 1.0),
  );
});
