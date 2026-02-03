import '../../core/models/card.dart';
import '../../core/utils/result.dart';

/// Abstract repository interface for card operations
abstract class CardRepository {
  /// Get all cards
  AsyncResult<List<BankCard>> getAllCards();

  /// Get card by id
  AsyncResult<BankCard> getCardById(int id);

  /// Get primary card
  AsyncResult<BankCard?> getPrimaryCard();

  /// Insert a new card
  AsyncResult<int> insertCard(BankCard card);

  /// Update an existing card
  AsyncResult<bool> updateCard(BankCard card);

  /// Delete a card
  AsyncResult<bool> deleteCard(int id);

  /// Set a card as primary
  AsyncResult<bool> setPrimaryCard(int cardId);

  /// Get card history (when it was primary)
  AsyncResult<List<Map<String, dynamic>>> getCardHistory(int cardId);

  /// Get cards by type (Debit/Credit)
  AsyncResult<List<BankCard>> getCardsByType(String type);

  /// Get total balance across all cards
  AsyncResult<double> getTotalBalance();

  /// Get total balance by card type
  AsyncResult<double> getTotalBalanceByType(String type);
}
