import 'package:blankets_and_wines_example/OFFLINE/CacheService.dart';
import 'package:blankets_and_wines_example/data/models/Product.dart';

/// Simple interface for stock operations in your fast-paced terminal
class StockManager {
  
  /// Update stock for a product (works offline)
  static Future<bool> updateStock({
    required int productId, 
    required int newStock, 
    required String userId
  }) async {
    try {
      return await CacheService.updateProductStock(productId, newStock, userId);
    } catch (e) {
      print("Failed to update stock: $e");
      return false;
    }
  }
  
  /// Add stock to existing quantity
  static Future<bool> addStock({
    required int productId, 
    required int quantity, 
    required String userId
  }) async {
    try {
      final products = CacheService.getCachedProducts();
      final product = products.firstWhere((p) => p.id == productId);
      final newStock = product.stock + quantity;
      
      await CacheService.addRestock(product, quantity, product.stock);
      return await CacheService.updateProductStock(productId, newStock, userId);
    } catch (e) {
      print("Failed to add stock: $e");
      return false;
    }
  }
  
  /// Remove stock from existing quantity
  static Future<bool> removeStock({
    required int productId, 
    required int quantity, 
    required String userId
  }) async {
    try {
      final products = CacheService.getCachedProducts();
      final product = products.firstWhere((p) => p.id == productId);
      final newStock = (product.stock - quantity).clamp(0, double.infinity).toInt();
      
      return await CacheService.updateProductStock(productId, newStock, userId);
    } catch (e) {
      print("Failed to remove stock: $e");
      return false;
    }
  }
  
  /// Get current stock for a product
  static int? getStock(int productId) {
    try {
      final products = CacheService.getCachedProducts();
      final product = products.firstWhere((p) => p.id == productId);
      return product.stock;
    } catch (e) {
      return null;
    }
  }
  
  /// Get product by ID
  static Product? getProduct(int productId) {
    try {
      final products = CacheService.getCachedProducts();
      return products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if there are pending offline changes
  static bool hasPendingChanges() {
    final restocks = CacheService.getPendingRestocks();
    final changeLogs = CacheService.getChangeLog();
    return restocks.isNotEmpty || changeLogs.isNotEmpty;
  }
  
  /// Get count of pending changes
  static int getPendingChangesCount() {
    final restocks = CacheService.getPendingRestocks();
    final changeLogs = CacheService.getChangeLog();
    return restocks.length + changeLogs.length;
  }

  // BULK OPERATIONS for fast-paced terminal
  
  /// Bulk update stock for multiple products
  static Future<BatchResult> bulkUpdateStock(List<StockUpdate> updates, String userId) async {
    final updateMaps = updates.map((u) => {
      'productId': u.productId,
      'newStock': u.newStock,
    }).toList();
    
    final results = await CacheService.batchUpdateStock(updateMaps, userId);
    final successful = results.where((r) => r).length;
    
    return BatchResult(
      total: updates.length,
      successful: successful,
      failed: updates.length - successful,
    );
  }
  
  /// Bulk add stock to multiple products
  static Future<BatchResult> bulkAddStock(List<StockAddition> additions, String userId) async {
    final additionMaps = additions.map((a) => {
      'productId': a.productId,
      'quantity': a.quantity,
    }).toList();
    
    final results = await CacheService.batchAddStock(additionMaps, userId);
    final successful = results.where((r) => r).length;
    
    return BatchResult(
      total: additions.length,
      successful: successful,
      failed: additions.length - successful,
    );
  }
  
  /// Quick bulk update from CSV-like data
  static Future<BatchResult> bulkUpdateFromData(String csvData, String userId) async {
    final lines = csvData.trim().split('\n');
    final updates = <StockUpdate>[];
    
    for (int i = 1; i < lines.length; i++) { // Skip header
      final parts = lines[i].split(',');
      if (parts.length >= 2) {
        try {
          final productId = int.parse(parts[0].trim());
          final newStock = int.parse(parts[1].trim());
          updates.add(StockUpdate(productId: productId, newStock: newStock));
        } catch (e) {
          print("Invalid data on line $i: ${lines[i]}");
        }
      }
    }
    
    return await bulkUpdateStock(updates, userId);
  }
}

// Helper classes for bulk operations
class StockUpdate {
  final int productId;
  final int newStock;
  
  StockUpdate({required this.productId, required this.newStock});
}

class StockAddition {
  final int productId;
  final int quantity;
  
  StockAddition({required this.productId, required this.quantity});
}

class BatchResult {
  final int total;
  final int successful;
  final int failed;
  
  BatchResult({
    required this.total,
    required this.successful,
    required this.failed,
  });
  
  bool get isFullySuccessful => failed == 0;
  double get successRate => successful / total;
  
  @override
  String toString() {
    return 'BatchResult: $successful/$total successful (${(successRate * 100).toStringAsFixed(1)}%)';
  }
}