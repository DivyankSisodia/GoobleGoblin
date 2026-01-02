import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/DB/db_helper.dart';
import '../../../core/models/category.dart';

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super([]) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    final categories = await DatabaseHelper.instance.getAllCategories();
    state = categories;
  }

  Future<void> addCategory(Category category) async {
    await DatabaseHelper.instance.insertCategory(category);
    await loadCategories();
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});
