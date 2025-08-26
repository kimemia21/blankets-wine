import 'package:hive/hive.dart';
import 'hive_type_ids.dart';
part 'DrinkItem.g.dart';

@HiveType(typeId: HiveTypeId.drinkItem)
class DrinkItem extends HiveObject {
  @HiveField(0)
  final String? productName;

  @HiveField(1)
  final int quantity;

  @HiveField(2)
  final double price;

  DrinkItem({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory DrinkItem.fromJson(Map<String, dynamic> json) {
    return DrinkItem(
      productName: json['productName'],
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "productName": productName,
      "quantity": quantity,
      "price": price.toStringAsFixed(2),
    };
  }
}
