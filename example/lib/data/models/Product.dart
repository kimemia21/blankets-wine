import 'package:hive/hive.dart';
import 'hive_type_ids.dart';
part 'Product.g.dart';

@HiveType(typeId: HiveTypeId.product)
class Product extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String image;

  /// Kept as string since JSON returns values like "4500.00"
  @HiveField(3)
  final String price;

  @HiveField(4)
  final int category;

  @HiveField(5)
  final String bar;

  @HiveField(6)
  final int stock;

  @HiveField(7)
  final bool isDiscount;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.category,
    required this.bar,
    required this.stock,
    required this.isDiscount,
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
          : (json['is_discount'] == 1), // handles int or bool
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
    };
  }
}
