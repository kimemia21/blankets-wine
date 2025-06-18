  class Product {
  final int id;
  final String name;
  final String image;
  final int price;
  final int stock;
  final int reorder;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.stock,
    required this.reorder,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      price: json['price'],
      stock: json['stock'],
      reorder: json['reorder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'price': price,
      'stock': stock,
      'reorder': reorder,
    };
  }
}
