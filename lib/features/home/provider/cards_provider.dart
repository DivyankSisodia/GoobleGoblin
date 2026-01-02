import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardModel {
  final String id;
  final String bankName;
  final String balance;
  final bool isCredit;
  final bool isSelected;

  CardModel({
    required this.id,
    required this.bankName,
    required this.balance,
    required this.isCredit,
    this.isSelected = false,
  });

  CardModel copyWith({
    String? id,
    String? bankName,
    String? balance,
    bool? isCredit,
    bool? isSelected,
  }) {
    return CardModel(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      isCredit: isCredit ?? this.isCredit,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class CardsNotifier extends StateNotifier<List<CardModel>> {
  CardsNotifier() : super([]);

  void addCard(CardModel card) {
    state = [...state, card];
  }

  void toggleCardSelection(String cardId) {
    state = state.map((card) {
      if (card.id == cardId) {
        return card.copyWith(isSelected: !card.isSelected);
      }
      return card.copyWith(isSelected: false); // Deselect other cards
    }).toList();
  }

  void selectCard(String cardId) {
    state = state.map((card) {
      return card.copyWith(isSelected: card.id == cardId);
    }).toList();
  }

  CardModel? get selectedCard {
    try {
      return state.firstWhere((card) => card.isSelected);
    } catch (e) {
      return null;
    }
  }
}

final cardsProvider = StateNotifierProvider<CardsNotifier, List<CardModel>>((ref) {
  return CardsNotifier();
});