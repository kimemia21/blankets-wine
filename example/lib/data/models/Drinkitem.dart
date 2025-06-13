class DrinkItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String image;
  final int quantity;

  DrinkItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
    required this.quantity,
  });

  // ✅ fromJson factory constructor
  factory DrinkItem.fromJson(Map<String, dynamic> json) {
    return DrinkItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] as num).toDouble(), // Ensures double
      image: json['image'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  // ✅ toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'image': image,
      'quantity': quantity,
    };
  }
}
