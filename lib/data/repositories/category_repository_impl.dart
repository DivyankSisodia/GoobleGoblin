import '../../core/DB/db_helper.dart';
import '../../core/app_images.dart';
import '../../core/errors/failures.dart';
import '../../core/models/category.dart';
import '../../core/utils/result.dart';
import '../../core/utils/validators.dart';
import 'category_repository.dart';

/// Implementation of CategoryRepository using SQLite database
class CategoryRepositoryImpl implements CategoryRepository {
  final DatabaseHelper _dbHelper;

  CategoryRepositoryImpl({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  AsyncResult<List<Category>> getAllCategories() async {
    try {
      final categories = await _dbHelper.getAllCategories();
      return ResultHelper.success(categories);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.fetchFailed('categories', e));
    }
  }

  @override
  AsyncResult<Category> getCategoryById(int id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        return ResultHelper.failure(DatabaseFailure.notFound('Category'));
      }

      return ResultHelper.success(Category.fromMap(result.first));
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.fetchFailed('category', e));
    }
  }

  @override
  AsyncResult<int> insertCategory(Category category) async {
    // Validate category data
    final validation = Validators.validateCategory(
      label: category.label,
      icon: category.icon,
    );

    if (validation.isFailure) {
      return ResultHelper.failure(validation.failureValue);
    }

    try {
      final id = await _dbHelper.insertCategory(category);
      return ResultHelper.success(id);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.insertFailed('category', e));
    }
  }

  @override
  AsyncResult<bool> updateCategory(Category category) async {
    if (category.id == null) {
      return ResultHelper.failure(
        const ValidationFailure(
          message: 'Category ID is required for update',
          code: 'VALIDATION_MISSING_ID',
        ),
      );
    }

    // Validate category data
    final validation = Validators.validateCategory(
      label: category.label,
      icon: category.icon,
    );

    if (validation.isFailure) {
      return ResultHelper.failure(validation.failureValue);
    }

    try {
      final rowsAffected = await _dbHelper.updateCategory(category);
      return ResultHelper.success(rowsAffected > 0);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.updateFailed('category', e));
    }
  }

  @override
  AsyncResult<bool> deleteCategory(int id) async {
    try {
      final rowsAffected = await _dbHelper.deleteCategory(id);
      return ResultHelper.success(rowsAffected > 0);
    } catch (e) {
      return ResultHelper.failure(DatabaseFailure.deleteFailed('category', e));
    }
  }

  @override
  List<Category> getDefaultCategories() {
    return [
      Category(label: 'Food & Dining', icon: 'restaurant'),
      Category(label: 'Shopping', icon: 'shopping_bag'),
      Category(label: 'Transportation', icon: 'directions_car'),
      Category(label: 'Entertainment', icon: 'movie'),
      Category(label: 'Bills & Utilities', icon: 'receipt_long'),
      Category(label: 'Health & Fitness', icon: 'fitness_center'),
      Category(label: 'Travel', icon: 'flight'),
      Category(label: 'Education', icon: 'school'),
      Category(label: 'Subscriptions', icon: 'subscriptions'),
      Category(label: 'Grocery', icon: 'grocery', assetPath: AppImages.grocery),
      Category(label: 'Personal Care', icon: 'spa'),
      Category(label: 'Others', icon: 'category'),
    ];
  }

  @override
  AsyncResult<bool> seedDefaultCategories() async {
    try {
      final existingResult = await getAllCategories();

      if (existingResult.isFailure) {
        return ResultHelper.failure(existingResult.failureValue);
      }

      final existing = existingResult.successValue;

      // Only seed if no categories exist
      if (existing.isNotEmpty) {
        return ResultHelper.success(true);
      }

      final defaultCategories = getDefaultCategories();

      for (final category in defaultCategories) {
        final insertResult = await insertCategory(category);
        if (insertResult.isFailure) {
          return ResultHelper.failure(insertResult.failureValue);
        }
      }

      return ResultHelper.success(true);
    } catch (e) {
      return ResultHelper.failure(
        DatabaseFailure.insertFailed('default categories', e),
      );
    }
  }
}
