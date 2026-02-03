import '../../core/models/category.dart';
import '../../core/utils/result.dart';

/// Abstract repository interface for category operations
abstract class CategoryRepository {
  /// Get all categories
  AsyncResult<List<Category>> getAllCategories();

  /// Get category by id
  AsyncResult<Category> getCategoryById(int id);

  /// Insert a new category
  AsyncResult<int> insertCategory(Category category);

  /// Update an existing category
  AsyncResult<bool> updateCategory(Category category);

  /// Delete a category
  AsyncResult<bool> deleteCategory(int id);

  /// Get default categories (for seeding)
  List<Category> getDefaultCategories();

  /// Seed default categories if none exist
  AsyncResult<bool> seedDefaultCategories();
}
