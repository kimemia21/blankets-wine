import 'package:hive/hive.dart';
import 'hive_type_ids.dart';
part 'Product.g.dart';

@HiveType(typeId: HiveTypeId.product)
class Product extends HiveObject {
  @HiveField(0)
  final int id; // ID should remain immutable

  @HiveField(1)
  String name; // Allow updates for name changes

  @HiveField(2)
  String image; // Allow image updates

  @HiveField(3)
  String price; // Allow price updates

  @HiveField(4)
  final int category; // Category rarely changes, but could be mutable

  @HiveField(5)
  final String bar; // Bar assignment rarely changes

  @HiveField(6)
  int stock; // ⚡ CRITICAL: Must be mutable for stock updates

  @HiveField(7)
  bool isDiscount; // Allow discount status changes

  // Add fields for tracking changes
  @HiveField(8)
  DateTime? lastModified;

  @HiveField(9)
  String? lastModifiedBy;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.category,
    required this.bar,
    required this.stock,
    required this.isDiscount,
    this.lastModified,
    this.lastModifiedBy,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: json['price']?.toString() ?? '0.00',
      category: json['category'] ?? 0,
      bar: json['bar'] ?? '',
      stock: json['stock'] ?? 0,
      isDiscount: json['is_discount'] is bool
          ? json['is_discount']
          : (json['is_discount'] == 1),
      lastModified: json['last_modified'] != null 
          ? DateTime.tryParse(json['last_modified']) 
          : null,
      lastModifiedBy: json['last_modified_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'price': price,
      'category': category,
      'bar': bar,
      'stock': stock,
      'is_discount': isDiscount,
      'last_modified': lastModified?.toIso8601String(),
      'last_modified_by': lastModifiedBy,
    };
  }

  // Convenience methods for updates
  void updateStock(int newStock, String updatedBy) {
    stock = newStock;
    lastModified = DateTime.now();
    lastModifiedBy = updatedBy;
    save(); // Auto-save to Hive
  }

  void addStock(int quantity, String updatedBy) {
    stock += quantity;
    lastModified = DateTime.now();
    lastModifiedBy = updatedBy;
    save();
  }

  void removeStock(int quantity, String updatedBy) {
    stock = (stock - quantity).clamp(0, double.infinity).toInt();
    lastModified = DateTime.now();
    lastModifiedBy = updatedBy;
    save();
  }

  void updatePrice(String newPrice, String updatedBy) {
    price = newPrice;
    lastModified = DateTime.now();
    lastModifiedBy = updatedBy;
    save();
  }

  void toggleDiscount(String updatedBy) {
    isDiscount = !isDiscount;
    lastModified = DateTime.now();
    lastModifiedBy = updatedBy;
    save();
  }

  // Helper getters
  double get priceAsDouble => double.tryParse(price) ?? 0.0;
  bool get hasStock => stock > 0;
  bool get isLowStock => stock < 10; // Configurable threshold
  
  // For debugging and logs
  @override
  String toString() {
    return 'Product(id: $id, name: $name, stock: $stock, price: $price)';
  }

  // Equality based on ID only
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}