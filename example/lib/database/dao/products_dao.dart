import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/products_table.dart';
import '../tables/categories_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products, Categories])
class ProductsDao extends DatabaseAccessor<BnwDatabase> with _$ProductsDaoMixin {
  ProductsDao(BnwDatabase db) : super(db);

  // Get all products
  Future<List<Product>> getAllProducts() => select(products).get();

  // Get product by id
  Future<Product?> getProductById(int id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  // Get products by category
  Future<List<Product>> getProductsByCategory(int categoryId) =>
      (select(products)..where((p) => p.productCategory.equals(categoryId))).get();

  // Get products with low stock (below reorder level)
  Future<List<Product>> getLowStockProducts() =>
      (select(products)..where((p) => p.stock.isSmallerThan(p.reorder))).get();

  // Get out of stock products
  Future<List<Product>> getOutOfStockProducts() =>
      (select(products)..where((p) => p.stock.equals(0))).get();

  // Get products with category info (JOIN)
  Future<List<ProductWithCategory>> getProductsWithCategory() {
    final query = select(products).join([
      leftOuterJoin(categories, categories.id.equalsExp(products.productCategory))
    ]);

    return query.map((row) {
      return ProductWithCategory(
        product: row.readTable(products),
        category: row.readTableOrNull(categories),
      );
    }).get();
  }

  // Search products by name
  Future<List<Product>> searchProductsByName(String searchTerm) =>
      (select(products)..where((p) => p.name.like('%$searchTerm%'))).get();

  // Insert product
  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product);

  // Update product
  Future<bool> updateProduct(Product product) =>
      update(products).replace(product);

  // Update product stock
  Future<int> updateProductStock(int id, int newStock) =>
      (update(products)..where((p) => p.id.equals(id)))
          .write(ProductsCompanion(stock: Value(newStock)));

  // Update reorder level
  Future<int> updateReorderLevel(int id, int reorderLevel) =>
      (update(products)..where((p) => p.id.equals(id)))
          .write(ProductsCompanion(reorder: Value(reorderLevel)));

  // Delete product
  Future<int> deleteProduct(int id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();

  // Watch all products (for real-time updates)
  Stream<List<Product>> watchAllProducts() => select(products).watch();

  // Watch products by category
  Stream<List<Product>> watchProductsByCategory(int categoryId) =>
      (select(products)..where((p) => p.productCategory.equals(categoryId))).watch();

  // Watch low stock products
  Stream<List<Product>> watchLowStockProducts() =>
      (select(products)..where((p) => p.stock.isSmallerThan(p.reorder))).watch();
}



// Custom class for joined data
class ProductWithCategory {
  final Product product;
  final Category? category;

  ProductWithCategory({required this.product, this.category});
}