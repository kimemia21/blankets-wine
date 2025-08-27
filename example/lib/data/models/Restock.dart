import 'package:hive/hive.dart';
import 'Product.dart';
import 'hive_type_ids.dart';

part 'Restock.g.dart';

@HiveType(typeId: HiveTypeId.restock)
class Restock extends HiveObject {
  @HiveField(0)
  final Product product; // this will be stored as a Hive reference

  @HiveField(1)
  final int quantity;

  @HiveField(2)
  final int previousQuantity;

  Restock({
    required this.product,
    required this.quantity,
    required this.previousQuantity,
  });

  factory Restock.fromJson(Map<String, dynamic> json, Product product) {
    return Restock(
      product: product,
      quantity: json['quantity'] ?? 0,
      previousQuantity: json['previous_quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id, // reference by id
      'quantity': quantity,
      'previous_quantity': previousQuantity,
    };
  }
}
