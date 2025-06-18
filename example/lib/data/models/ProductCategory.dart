import 'package:blankets_and_wines_example/data/models/Product.dart';

class ProductCategory {
  final int categoryId;
  final String categoryName;
  final List<Product> products;

  ProductCategory({
    required this.categoryId,
    required this.categoryName,
    required this.products,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      products: (json['products'] as List)
          .map((item) => Product.fromJson(item))
          .toList(),
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


