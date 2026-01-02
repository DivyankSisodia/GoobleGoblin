import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/DB/db_helper.dart';
import '../../../core/models/card.dart';

class CardsNotifier extends StateNotifier<List<BankCard>> {
  CardsNotifier() : super([]) {
    loadCards();
  }

  Future<void> loadCards() async {
    final cards = await DatabaseHelper.instance.getAllCards();
    state = cards;
  }

  Future<void> addCard(BankCard card) async {
    await DatabaseHelper.instance.insertCard(card);
    await loadCards();
  }

  void toggleCardSelection(int? cardId) {
    if (cardId == null) return;
    state = state.map((card) {
      if (card.id == cardId) {
        return card.copyWith(isSelected: !card.isSelected);
      }
      return card.copyWith(isSelected: false); // Deselect other cards
    }).toList();
  }

  void selectCard(int? cardId) {
    if (cardId == null) return;
    state = state.map((card) {
      return card.copyWith(isSelected: card.id == cardId);
    }).toList();
  }

  BankCard? get selectedCard {
    try {
      return state.firstWhere((card) => card.isSelected);
    } catch (e) {
      return null;
    }
  }
}

final cardsProvider = StateNotifierProvider<CardsNotifier, List<BankCard>>((ref) {
  return CardsNotifier();
});