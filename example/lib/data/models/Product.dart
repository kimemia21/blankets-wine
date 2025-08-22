class Product {
  final int id;
  final String name;
  final String image;
  final String price; // keep as string since JSON gives "4500.00"
  final int category;
  final String bar;
  final int stock;
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
      id: json['id'],
      name: json['name'],
      image: json['image'],
      price: json['price']??0.00,
      category: json['category'] ,
      bar: json['bar'],
      stock: json['stock'],
      isDiscount: json['is_discount'],
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
