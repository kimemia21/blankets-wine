
import 'package:blankets_and_wines_example/data/models/Product.dart';

class CartItem {
  final Product drink;
  int quantity;

  CartItem({required this.drink, this.quantity = 1});

  double get totalPrice =>  double.parse(drink.price!)* quantity;

  Map<String, dynamic> toJson() {
    return {
      "productId": drink.id,
      "qty": quantity,
      "price": drink.price
    };
  }
}

class Cart {
  List<CartItem> items;

  Cart({this.items = const []});

  double get total => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  Map<String, dynamic> toOrderFormat() {
    return {
      "total": total,
      "items": items.map((item) => item.toJson()).toList(),
    };
  }
}