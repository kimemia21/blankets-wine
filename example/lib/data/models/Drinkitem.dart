class DrinkItem {
  final int id;
  final String name;
  final int categoryId;
  final double price;
  final String image;
  final int stock;

  DrinkItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.image,
    required this.stock,
  });

  // ✅ fromJson factory constructor
  factory DrinkItem.fromJson(Map<String, dynamic> json) {
    print("server json $json");
    return DrinkItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      categoryId: json['category'] ?? 0,
      price: ( double.parse(json['price'])),
      image: json['image'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }

  // ✅ toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'price': price,
      'image': image,
      'stock': stock,
    };
  }
}
