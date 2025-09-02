import 'package:blankets_and_wines_example/data/models/DrinkCategory.dart';
import 'package:blankets_and_wines_example/data/models/Product.dart';
import 'package:blankets_and_wines_example/data/models/ProductChangeLog.dart';
import 'package:blankets_and_wines_example/data/models/Restock.dart';


import 'package:hive/hive.dart';

class CacheService {
  static const String PRODUCTS_BOX = 'products';
  static const String CATEGORIES_BOX = 'drinkCategories';
  static const String RESTOCK_BOX = 'restock';
  static const String CHANGE_LOG_BOX = 'productChangeLogs';
  static const String LAST_SYNC_KEY = 'lastSync';

  // Existing methods...
  static Future<void> cacheProducts(List<Product> products) async {
    final box = Hive.box<Product>(PRODUCTS_BOX);
    await box.clear();
    final Map<int, Product> productsMap = {};
    for (int i = 0; i < products.length; i++) {
      productsMap[i] = products[i];
    }
    await box.putAll(productsMap);
    await _updateLastSync('products');
  }

  static List<Product> getCachedProducts() {
    final box = Hive.box<Product>(PRODUCTS_BOX);
    return box.values.toList();
  }

  static Future<void> cacheCategories(List<DrinkCategory> categories) async {
    final box = Hive.box<DrinkCategory>(CATEGORIES_BOX);
    await box.clear();
    final Map<int, DrinkCategory> categoriesMap = {};
    for (int i = 0; i < categories.length; i++) {
      categoriesMap[i] = categories[i];
    }
    await box.putAll(categoriesMap);
    await _updateLastSync('categories');
  }

  static List<DrinkCategory> getCachedCategories() {
    final box = Hive.box<DrinkCategory>(CATEGORIES_BOX);
    return box.values.toList();
  }

  // ⚡ OPTIMIZED: Direct stock updates on existing objects
  static Future<bool> updateProductStock(int productId, int newStock, String updatedBy) async {
    final box = Hive.box<Product>(PRODUCTS_BOX);
    
    try {
      // Find product in box
      final productEntry = box.toMap().entries.firstWhere(
        (entry) => entry.value.id == productId,
        orElse: () => throw Exception('Product not found'),
      );
      
      final product = productEntry.value;
      final originalStock = product.stock;
      
      // ⚡ Direct update - no new object creation!
      product.updateStock(newStock, updatedBy);
      
      // Log the change
      await _logChange(productId, 'stock', originalStock.toString(), newStock.toString(), updatedBy);
      
      return true;
    } catch (e) {
      print("Failed to update product stock: $e");
      return false;
    }
  }

  static Future<bool> addProductStock(int productId, int quantity, String updatedBy) async {
    final box = Hive.box<Product>(PRODUCTS_BOX);
    
    try {
      final productEntry = box.toMap().entries.firstWhere(
        (entry) => entry.value.id == productId,
        orElse: () => throw Exception('Product not found'),
      );
      
      final product = productEntry.value;
      final originalStock = product.stock;
      
      // Add restock record
      await addRestock(product, quantity, originalStock);
      
      // ⚡ Direct update
      product.addStock(quantity, updatedBy);
      
      // Log the change
      await _logChange(productId, 'stock', originalStock.toString(), product.stock.toString(), updatedBy);
      
      return true;
    } catch (e) {
      print("Failed to add product stock: $e");
      return false;
    }
  }

  static Future<bool> removeProductStock(int productId, int quantity, String updatedBy) async {
    final box = Hive.box<Product>(PRODUCTS_BOX);
    
    try {
      final productEntry = box.toMap().entries.firstWhere(
        (entry) => entry.value.id == productId,
        orElse: () => throw Exception('Product not found'),
      );
      
      final product = productEntry.value;
      final originalStock = product.stock;
      
      // ⚡ Direct update
      product.removeStock(quantity, updatedBy);
      
      // Log the change
      await _logChange(productId, 'stock', originalStock.toString(), product.stock.toString(), updatedBy);
      
      return true;
    } catch (e) {
      print("Failed to remove product stock: $e");
      return false;
    }
  }

  // ⚡ SUPER FAST: Batch operations with direct updates
  static Future<List<bool>> batchUpdateStock(List<Map<String, dynamic>> updates, String updatedBy) async {
    final box = Hive.box<Product>(PRODUCTS_BOX);
    final results = <bool>[];
    final changeLogs = <ProductChangeLog>[];
    
    // Create a map for faster lookups
    final productMap = <int, Product>{};
    for (final entry in box.toMap().entries) {
      productMap[entry.value.id] = entry.value;
    }
    
    try {
      for (final update in updates) {
        final productId = update['productId'] as int;
        final newStock = update['newStock'] as int;
        
        final product = productMap[productId];
        if (product != null) {
          final originalStock = product.stock;
          
          // ⚡ Direct update - no new object!
          product.updateStock(newStock, updatedBy);
          
          // Prepare change log
          changeLogs.add(ProductChangeLog(
            id: DateTime.now().millisecondsSinceEpoch + productId,
            productId: productId,
            fieldName: 'stock',
            originalValue: originalStock.toString(),
            updatedValue: newStock.toString(),
            updatedBy: updatedBy,
            timestamp: DateTime.now(),
          ));
          
          results.add(true);
        } else {
          print("Product $productId not found");
          results.add(false);
        }
      }
      
      // Batch write change logs only (products auto-saved)
      if (changeLogs.isNotEmpty) {
        final changeLogBox = Hive.box<ProductChangeLog>(CHANGE_LOG_BOX);
        for (final log in changeLogs) {
          await changeLogBox.add(log);
        }
      }
      
      return results;
    } catch (e) {
      print("Batch update failed: $e");
      return List.filled(updates.length, false);
    }
  }

  static Future<List<bool>> batchAddStock(List<Map<String, dynamic>> additions, String updatedBy) async {
    final box = Hive.box<Product>(PRODUCTS_BOX);
    final results = <bool>[];
    final changeLogs = <ProductChangeLog>[];
    
    // Create a map for faster lookups
    final productMap = <int, Product>{};
    for (final entry in box.toMap().entries) {
      productMap[entry.value.id] = entry.value;
    }
    
    try {
      for (final addition in additions) {
        final productId = addition['productId'] as int;
        final quantity = addition['quantity'] as int;
        
        final product = productMap[productId];
        if (product != null) {
          final originalStock = product.stock;
          
          // Add restock record
          await addRestock(product, quantity, originalStock);
          
          // ⚡ Direct update
          product.addStock(quantity, updatedBy);
          
          // Prepare change log
          changeLogs.add(ProductChangeLog(
            id: DateTime.now().millisecondsSinceEpoch + productId,
            productId: productId,
            fieldName: 'stock',
            originalValue: originalStock.toString(),
            updatedValue: product.stock.toString(),
            updatedBy: updatedBy,
            timestamp: DateTime.now(),
          ));
          
          results.add(true);
        } else {
          print("Product $productId not found");
          results.add(false);
        }
      }
      
      // Batch write change logs
      if (changeLogs.isNotEmpty) {
        final changeLogBox = Hive.box<ProductChangeLog>(CHANGE_LOG_BOX);
        for (final log in changeLogs) {
          await changeLogBox.add(log);
        }
      }
      
      return results;
    } catch (e) {
      print("Batch add failed: $e");
      return List.filled(additions.length, false);
    }
  }

  // Helper methods remain the same
  static Future<void> addRestock(Product product, int quantity, int previousQuantity) async {
    final box = Hive.box<Restock>(RESTOCK_BOX);
    final restock = Restock(
      product: product,
      quantity: quantity,
      previousQuantity: previousQuantity,
    );
    await box.add(restock);
  }

  static List<Restock> getPendingRestocks() {
    final box = Hive.box<Restock>(RESTOCK_BOX);
    return box.values.toList();
  }

  static Future<void> clearPendingRestocks() async {
    final box = Hive.box<Restock>(RESTOCK_BOX);
    await box.clear();
  }

  static List<ProductChangeLog> getChangeLog() {
    final box = Hive.box<ProductChangeLog>(CHANGE_LOG_BOX);
    return box.values.toList();
  }

  static Future<void> clearChangeLog() async {
    final box = Hive.box<ProductChangeLog>(CHANGE_LOG_BOX);
    await box.clear();
  }

  static Future<void> _logChange(int productId, String field, String oldValue, String newValue, String updatedBy) async {
    final box = Hive.box<ProductChangeLog>(CHANGE_LOG_BOX);
    final log = ProductChangeLog(
      id: DateTime.now().millisecondsSinceEpoch,
      productId: productId,
      fieldName: field,
      originalValue: oldValue,
      updatedValue: newValue,
      updatedBy: updatedBy,
      timestamp: DateTime.now(),
    );
    await box.add(log);
  }

  static Future<void> _updateLastSync(String type) async {
    final box = await Hive.openBox('metadata');
    await box.put('${type}$LAST_SYNC_KEY', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> isDataStale(String type) async {
    final box = await Hive.openBox('metadata');
    final lastSync = box.get('${type}$LAST_SYNC_KEY');
    if (lastSync == null) return true;
    
    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    return DateTime.now().difference(lastSyncTime).inMinutes > 5;
  }

  static int getCachedProductsCount() {
    final box = Hive.box<Product>(PRODUCTS_BOX);
    return box.length;
  }

  static int getCachedCategoriesCount() {
    final box = Hive.box<DrinkCategory>(CATEGORIES_BOX);
    return box.length;
  }
}