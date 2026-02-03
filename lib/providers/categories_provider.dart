import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/category_repository_impl.dart';

/// Provider for CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl();
});

/// State class for categories
class CategoriesState {
  final List<Category> categories;
  final bool isLoading;
  final String? errorMessage;

  const CategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CategoriesState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Find category by id
  Category? getCategoryById(int id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Find category by label
  Category? getCategoryByLabel(String label) {
    try {
      return categories.firstWhere(
        (c) => c.label.toLowerCase() == label.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

/// Categories notifier using modern Riverpod patterns
class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final CategoryRepository _repository;

  CategoriesNotifier(this._repository) : super(const CategoriesState()) {
    _initialize();
  }

  /// Initialize - load categories and seed defaults if needed
  Future<void> _initialize() async {
    await loadCategories();

    // Seed default categories if empty
    if (state.categories.isEmpty) {
      await seedDefaultCategories();
    }
  }

  /// Load all categories from repository
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.getAllCategories();

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (categories) {
        state = state.copyWith(categories: categories, isLoading: false);
      },
    );
  }

  /// Add a new category
  Future<bool> addCategory(Category category) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.insertCategory(category);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (id) {
        loadCategories();
        return true;
      },
    );
  }

  /// Update an existing category
  Future<bool> updateCategory(Category category) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.updateCategory(category);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadCategories();
        return success;
      },
    );
  }

  /// Delete a category
  Future<bool> deleteCategory(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.deleteCategory(id);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (success) {
        loadCategories();
        return success;
      },
    );
  }

  /// Seed default categories
  Future<void> seedDefaultCategories() async {
    await _repository.seedDefaultCategories();
    await loadCategories();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Main categories provider
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
      final repository = ref.watch(categoryRepositoryProvider);
      return CategoriesNotifier(repository);
    });

/// Provider for category list only
final categoryListProvider = Provider<List<Category>>((ref) {
  final state = ref.watch(categoriesProvider);
  return state.categories;
});

/// Provider for category by id
final categoryByIdProvider = Provider.family<Category?, int>((ref, id) {
  final state = ref.watch(categoriesProvider);
  return state.getCategoryById(id);
});
