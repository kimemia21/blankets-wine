import 'package:blankets_and_wines_example/data/models/DrinkItem.dart';

class CartItem {
  final DrinkItem drink;
  int quantity;

  CartItem({required this.drink, this.quantity = 1});

  double get totalPrice => drink.price * quantity;
}