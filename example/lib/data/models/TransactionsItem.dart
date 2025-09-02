
import 'package:blankets_and_wines_example/data/models/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'TransactionsItem.g.dart';

@HiveType(typeId: HiveTypeId.transactionItem) 
class TransactionItem extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int quantity;

  @HiveField(2)
  final double price;

  TransactionItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      name: map['name'],
      quantity: map['quantity'],
      price: double.parse(map['price']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "quantity": quantity,
      "price": price.toStringAsFixed(2),
    };
  }

  @override
  String toString() {
    return 'TransactionItem(name: $name, qty: $quantity, price: $price)';
  }
}