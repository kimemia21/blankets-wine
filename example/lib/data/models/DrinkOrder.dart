import 'package:blankets_and_wines_example/data/models/DrinkItem.dart';
import 'package:hive/hive.dart';

import 'hive_type_ids.dart';

 part 'DrinkOrder.g.dart';

@HiveType(typeId: HiveTypeId.drinkOrder)
class DrinkOrder extends HiveObject {
  @HiveField(0)
  final String orderNo;

  @HiveField(1)
  final int paymentStatus; // 0 = pending, 1 = paid, etc.

  @HiveField(2)
  final DateTime orderDate;

  @HiveField(3)
  final double orderTotal;

  @HiveField(4)
  final String customerFirstName;

  @HiveField(5)
  final String customerLastName;

  @HiveField(6)
  final String customerEmail;

  @HiveField(7)
  final String customerPhone;

  @HiveField(8)
  List<DrinkItem> orderItems;

  DrinkOrder({
    required this.orderNo,
    required this.paymentStatus,
    required this.orderDate,
    required this.orderTotal,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerEmail,
    required this.customerPhone,
    required this.orderItems,
  });

  factory DrinkOrder.fromJson(Map<String, dynamic> json) {
    final order = json['order'] ?? {};

    return DrinkOrder(
      orderNo: order['orderNo'] ?? '',
      paymentStatus: order['paymentStatus'] ?? 0,
      orderDate: DateTime.tryParse(order['orderDate'] ?? '') ?? DateTime.now(),
      orderTotal: double.tryParse(order['orderTotal']?.toString() ?? '0') ?? 0.0,
      customerFirstName: order['customerFirstName'] ?? '',
      customerLastName: order['customerLastName'] ?? '',
      customerEmail: order['customerEmail'] ?? '',
      customerPhone: order['customerPhone'] ?? '',
      orderItems: (json['orderItems'] as List<dynamic>?)
              ?.map((item) => DrinkItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "order": {
        "orderNo": orderNo,
        "paymentStatus": paymentStatus,
        "orderDate": orderDate.toIso8601String(),
        "orderTotal": orderTotal.toStringAsFixed(2),
        "customerFirstName": customerFirstName,
        "customerLastName": customerLastName,
        "customerEmail": customerEmail,
        "customerPhone": customerPhone,
      },
      "orderItems": orderItems.map((e) => e.toJson()).toList(),
    };
  }
}
