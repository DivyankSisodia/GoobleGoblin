import '../../core/DB/db_helper.dart';
import '../../core/errors/failures.dart';
import '../../core/models/card.dart';
import '../../core/utils/result.dart';
import '../../core/utils/validators.dart';
import 'card_repository.dart';

/// Implementation of CardRepository using SQLite database
class CardRepositoryImpl implements CardRepository {
  final DatabaseHelper _dbHelper;

  CardRepositoryImpl({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  AsyncResult<List<BankCard>> getAllCards() async {
    try {
      final cards = await _dbHelper.getAllCards();
      return ResultHelper.success(cards);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.fetchFailed('cards', e));
    }
  }

  @override
  AsyncResult<BankCard> getCardById(int id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query('cards', where: 'id = ?', whereArgs: [id]);

      if (result.isEmpty) {
        return ResultHelper.failure(DatabaseFailure.notFound('Card'));
      }

      return ResultHelper.success(BankCard.fromMap(result.first));
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.fetchFailed('card', e));
    }
  }

  @override
  AsyncResult<BankCard?> getPrimaryCard() async {
    try {
      final card = await _dbHelper.getPrimaryCard();
      return ResultHelper.success(card);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('primary card', e),
      );
    }
  }

  @override
  AsyncResult<int> insertCard(BankCard card) async {
    // Validate card data
    final validation = Validators.validateCard(
      bankName: card.bankName,
      balance: card.balance,
      type: card.type,
    );

    if (validation.isFailure) {
      return ResultHelper.failure(validation.failureValue);
    }

    try {
      final map = card.toMap();
      map['updatedAt'] = DateTime.now().toIso8601String();
      final id = await _dbHelper.insertCard(BankCard.fromMap(map));
      return ResultHelper.success(id);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.insertFailed('card', e));
    }
  }

  @override
  AsyncResult<bool> updateCard(BankCard card) async {
    if (card.id == null) {
      return ResultHelper.failure(
        const ValidationFailure(
          message: 'Card ID is required for update',
          code: 'VALIDATION_MISSING_ID',
        ),
      );
    }

    // Validate card data
    final validation = Validators.validateCard(
      bankName: card.bankName,
      balance: card.balance,
      type: card.type,
    );

    if (validation.isFailure) {
      return ResultHelper.failure(validation.failureValue);
    }

    try {
      final map = card.toMap();
      map['updatedAt'] = DateTime.now().toIso8601String();
      final rowsAffected = await _dbHelper.updateCard(BankCard.fromMap(map));
      return ResultHelper.success(rowsAffected > 0);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.updateFailed('card', e));
    }
  }

  @override
  AsyncResult<bool> deleteCard(int id) async {
    try {
      final rowsAffected = await _dbHelper.deleteCard(id);
      return ResultHelper.success(rowsAffected > 0);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.deleteFailed('card', e));
    }
  }

  @override
  AsyncResult<bool> setPrimaryCard(int cardId) async {
    try {
      await _dbHelper.setPrimaryCard(cardId);
      return ResultHelper.success(true);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.updateFailed('primary card', e),
      );
    }
  }

  @override
  AsyncResult<List<Map<String, dynamic>>> getCardHistory(int cardId) async {
    try {
      final history = await _dbHelper.getCardHistory(cardId);
      return ResultHelper.success(history);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('card history', e),
      );
    }
  }

  @override
  AsyncResult<List<BankCard>> getCardsByType(String type) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'cards',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'isPrimary DESC, bankName ASC',
      );

      final cards = result.map((json) => BankCard.fromMap(json)).toList();
      return ResultHelper.success(cards);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('cards by type', e),
      );
    }
  }

  @override
  AsyncResult<double> getTotalBalance() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(balance), 0) as total FROM cards',
      );

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      return ResultHelper.success(total);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('total balance', e),
      );
    }
  }

  @override
  AsyncResult<double> getTotalBalanceByType(String type) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(balance), 0) as total FROM cards WHERE type = ?',
        [type],
      );

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      return ResultHelper.success(total);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.fetchFailed('total balance by type', e),
      );
    }
  }
}
