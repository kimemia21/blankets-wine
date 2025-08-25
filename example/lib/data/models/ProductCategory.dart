import 'package:hive/hive.dart';
import 'Product.dart';
import 'hive_type_ids.dart';
part 'ProductCategory.g.dart';

@HiveType(typeId: HiveTypeId.productCategory)
class ProductCategory extends HiveObject {
  @HiveField(0)
  final int categoryId;

  @HiveField(1)
  final String categoryName;

  @HiveField(2)
  final List<Product> products;

  ProductCategory({
    required this.categoryId,
    required this.categoryName,
    required this.products,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      categoryId: json['category_id'] ?? json['category'] ?? 0,
      categoryName: json['category_name'] ?? json['name'] ?? '',
      products: (json['products'] as List<dynamic>?)
              ?.map((item) => Product.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'products': products.map((product) => product.toJson()).toList(),
    };
  }
}
