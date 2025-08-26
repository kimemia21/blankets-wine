import 'package:blankets_and_wines_example/data/models/DrinkCategory.dart';
import 'package:blankets_and_wines_example/data/models/Product.dart';
import 'package:hive/hive.dart';

class CacheService {
  static const String PRODUCTS_BOX = 'products';
  static const String CATEGORIES_BOX = 'drinkCategories';
  static const String LAST_SYNC_KEY = 'lastSync';

  // Cache products with batch operations
  static Future<void> cacheProducts(List<Product> products) async {
    final box = Hive.box<Product>(PRODUCTS_BOX);
    
    // Use batch operations for better performance
    await box.clear();
    final Map<int, Product> productsMap = {};
    for (int i = 0; i < products.length; i++) {
      productsMap[i] = products[i];
    }
    await box.putAll(productsMap);
    await _updateLastSync('products');
  }

  // Get cached products with lazy loading
  static List<Product> getCachedProducts() {
    final box = Hive.box<Product>(PRODUCTS_BOX);
    return box.values.toList();
  }

  // Cache categories with batch operations  
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

  // Get cached categories with lazy loading
  static List<DrinkCategory> getCachedCategories() {
    final box = Hive.box<DrinkCategory>(CATEGORIES_BOX);
    return box.values.toList();
  }

  // Update last sync time
  static Future<void> _updateLastSync(String type) async {
    final box = await Hive.openBox('metadata');
    await box.put('${type}_$LAST_SYNC_KEY', DateTime.now().millisecondsSinceEpoch);
  }

  // Optimized stale check with shorter stale time for more frequent updates
  static Future<bool> isDataStale(String type) async {
    final box = await Hive.openBox('metadata');
    final lastSync = box.get('${type}_$LAST_SYNC_KEY');
    if (lastSync == null) return true;
    
    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    // Reduced stale time to 30 minutes for more frequent background updates
    return DateTime.now().difference(lastSyncTime).inMinutes > 5;
  }

  // Quick cache size check for performance monitoring
  static int getCachedProductsCount() {
    final box = Hive.box<Product>(PRODUCTS_BOX);
    return box.length;
  }

  static int getCachedCategoriesCount() {
    final box = Hive.box<DrinkCategory>(CATEGORIES_BOX);
    return box.length;
  }
}
