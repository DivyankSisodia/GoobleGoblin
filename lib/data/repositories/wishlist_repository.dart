import 'package:fpdart/fpdart.dart';
import '../../../core/errors/failures.dart';
import '../../../core/models/wishlist_item.dart';

abstract class WishlistRepository {
  Future<Either<Failure, int>> insertWishlistItem(WishlistItem item);
  Future<Either<Failure, List<WishlistItem>>> getAllWishlistItems();
  Future<Either<Failure, int>> updateWishlistItem(WishlistItem item);
  Future<Either<Failure, int>> deleteWishlistItem(int id);
  Future<Either<Failure, void>> markAsPurchased(int id);
}
