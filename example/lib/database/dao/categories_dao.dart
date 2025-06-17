import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<BnwDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(BnwDatabase db) : super(db);

  // Get all categories
  Future<List<Category>> getAllCategories() => select(categories).get();

  // Get category by id
  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  // Get category by name
  Future<Category?> getCategoryByName(String name) =>
      (select(categories)..where((c) => c.name.equals(name))).getSingleOrNull();

  // Insert category
  Future<int> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  // Update category
  Future<bool> updateCategory(Category category) =>
      update(categories).replace(category);

  // Delete category
  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  // Watch all categories (for real-time updates)
  Stream<List<Category>> watchAllCategories() => select(categories).watch();
}