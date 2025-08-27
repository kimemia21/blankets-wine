import 'package:hive/hive.dart';
import 'hive_type_ids.dart';

part 'ProductChangeLog.g.dart';

@HiveType(typeId: HiveTypeId.productChangeLog)
class ProductChangeLog extends HiveObject {
  @HiveField(0)
  final int id; // Unique log ID

  @HiveField(1)
  final int productId; // References Product.id

  @HiveField(2)
  final String fieldName; // e.g. "price", "stock"

  @HiveField(3)
  final String originalValue; 
  @HiveField(4)
  final String updatedValue; // new value

  @HiveField(5)
  final String updatedBy; // user/admin who made change

  @HiveField(6)
  final DateTime timestamp; // when the change was made

  ProductChangeLog({
    required this.id,
    required this.productId,
    required this.fieldName,
    required this.originalValue,
    required this.updatedValue,
    required this.updatedBy,
    required this.timestamp,
  });

  factory ProductChangeLog.fromJson(Map<String, dynamic> json) {
    return ProductChangeLog(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      fieldName: json['field_name'] ?? '',
      originalValue: json['original_value']?.toString() ?? '',
      updatedValue: json['updated_value']?.toString() ?? '',
      updatedBy: json['updated_by'] ?? 'system',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'field_name': fieldName,
      'original_value': originalValue,
      'updated_value': updatedValue,
      'updated_by': updatedBy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
