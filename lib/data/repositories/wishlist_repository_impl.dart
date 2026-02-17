import 'package:fpdart/fpdart.dart';
import '../../core/DB/db_helper.dart';
import '../../core/errors/failures.dart';
import '../../core/models/wishlist_item.dart';
import 'wishlist_repository.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final DatabaseHelper _dbHelper;

  WishlistRepositoryImpl(this._dbHelper);

  @override
  Future<Either<Failure, int>> insertWishlistItem(WishlistItem item) async {
    try {
      final map = item.toMap();
      map['updated_at'] = DateTime.now().toIso8601String();
      final id = await _dbHelper.insertWishlistItem(map);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WishlistItem>>> getAllWishlistItems() async {
    try {
      final results = await _dbHelper.getAllWishlistItems();
      final items = results.map((map) => WishlistItem.fromMap(map)).toList();
      return Right(items);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> updateWishlistItem(WishlistItem item) async {
    try {
      final map = item.toMap();
      map['updated_at'] = DateTime.now().toIso8601String();
      final rows = await _dbHelper.updateWishlistItem(map);
      return Right(rows);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> deleteWishlistItem(int id) async {
    try {
      final rows = await _dbHelper.deleteWishlistItem(id);
      return Right(rows);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsPurchased(int id) async {
    try {
      await _dbHelper.markWishlistAsPurchased(id);

      // Update updated_at
      final now = DateTime.now().toIso8601String();
      await _dbHelper.database.then((db) => db.update(
        'wishlist',
        {'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      ));

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}
