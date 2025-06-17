import 'database.dart';
import 'dao/categories_dao.dart';
import 'dao/products_dao.dart';

class DatabaseProvider {
  static final DatabaseProvider _instance = DatabaseProvider._internal();
  factory DatabaseProvider() => _instance;
  DatabaseProvider._internal();

  late final BnwDatabase _database;
  late final CategoriesDao _categoriesDao;
  late final ProductsDao _productsDao;

  // Initialize database and DAOs
  Future<void> initialize() async {
    _database = BnwDatabase();
    _categoriesDao = CategoriesDao(_database);
    _productsDao = ProductsDao(_database);
  }

  // Getters for database and DAOs
  BnwDatabase get database => _database;
  CategoriesDao get categoriesDao => _categoriesDao;
  ProductsDao get productsDao => _productsDao;

  // Close database connection
  Future<void> close() async {
    await _database.close();
  }
}