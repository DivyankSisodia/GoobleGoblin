import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/DB/db_helper.dart';
import '../core/models/wishlist_item.dart';
import '../data/repositories/wishlist_repository.dart';
import '../data/repositories/wishlist_repository_impl.dart';

/// Provider for WishlistRepository
final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepositoryImpl(DatabaseHelper.instance);
});

/// State class for wishlist
class WishlistState {
  final List<WishlistItem> items;
  final bool isLoading;
  final String? errorMessage;

  const WishlistState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WishlistState copyWith({
    List<WishlistItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  List<WishlistItem> get activeItems =>
      items.where((item) => !item.isPurchased).toList();
  List<WishlistItem> get purchasedItems =>
      items.where((item) => item.isPurchased).toList();
}

/// Wishlist notifier
class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistRepository _repository;

  WishlistNotifier(this._repository) : super(const WishlistState()) {
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getAllWishlistItems();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (items) => state = state.copyWith(items: items, isLoading: false),
    );
  }

  Future<bool> addItem(WishlistItem item) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.insertWishlistItem(item);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (id) {
        loadWishlist();
        return true;
      },
    );
  }

  Future<bool> updateItem(WishlistItem item) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.updateWishlistItem(item);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadWishlist();
        return true;
      },
    );
  }

  Future<bool> deleteItem(int id) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.deleteWishlistItem(id);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadWishlist();
        return true;
      },
    );
  }

  Future<bool> markAsPurchased(int id) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.markAsPurchased(id);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadWishlist();
        return true;
      },
    );
  }
}

/// Main wishlist provider
final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
  (ref) {
    final repository = ref.watch(wishlistRepositoryProvider);
    return WishlistNotifier(repository);
  },
);
