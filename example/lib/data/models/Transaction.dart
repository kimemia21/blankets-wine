import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/data/models/TransactionsItem.dart';
import 'package:hive/hive.dart';
import 'hive_type_ids.dart';

part 'Transaction.g.dart';

@HiveType(typeId: HiveTypeId.transaction) // You'll need to add this to your hive_type_ids.dart
class Transaction extends HiveObject {
  @HiveField(0)
  final String id; // Unique transaction ID

  @HiveField(1)
  final String storeName;

  @HiveField(2)
  final String receiptType; // "Sale Receipt" or "Stockist Receipt"

  @HiveField(3)
  final DateTime dateTime;

  @HiveField(4)
  final String orderNumber;

  @HiveField(5)
  final List<TransactionItem> items;

  @HiveField(6)
  final double subtotal;

  @HiveField(7)
  final double tax;

  @HiveField(8)
  final double total;

  @HiveField(9)
  final String paymentMethod;

  @HiveField(10)
  final String? lastTransactionDigits; // Last 4 digits for card payments

  @HiveField(11)
  final String sellerName;

  Transaction({
    required this.id,
    required this.storeName,
    required this.receiptType,
    required this.dateTime,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.lastTransactionDigits,
    required this.sellerName,
  });

  // Create from your existing receipt data structure
  factory Transaction.fromReceiptData(
    Map<String, dynamic> receiptData,
    String sellerName, {
    String? lastDigits,
  }) {
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID generation
      storeName: receiptData['storeName'],
      receiptType: receiptData['receiptType'],
      dateTime: DateTime.parse('${receiptData['date']} ${receiptData['time']}'),
      orderNumber: receiptData['orderNumber'],
      items: (receiptData['items'] as List)
          .map((item) => TransactionItem.fromMap(item))
          .toList(),
      subtotal: double.parse(receiptData['subtotal']),
      tax: double.parse(receiptData['tax']),
      total: double.parse(receiptData['total']),
      paymentMethod: receiptData['paymentMethod'],
      lastTransactionDigits: lastDigits,
      sellerName: appUser.fName,
    );
  }

  // Getters for formatted display
  String get formattedDate => '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  String get formattedTime => '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  
  // Convert back to receipt format for printing
  Map<String, dynamic> toReceiptData() {
    return {
      "storeName": storeName,
      "receiptType": receiptType,
      "date": formattedDate,
      "time": formattedTime,
      "orderNumber": orderNumber,
      "items": items.map((item) => item.toMap()).toList(),
      "subtotal": subtotal.toStringAsFixed(2),
      "tax": tax.toStringAsFixed(2),
      "total": total.toStringAsFixed(2),
      "paymentMethod": paymentMethod,
      "sellerName": sellerName,
      if (lastTransactionDigits != null) "lastDigits": lastTransactionDigits,
    };
  }

  @override
  String toString() {
    return 'Transaction(id: $id, total: $total, items: ${items.length}, seller: $sellerName)';
  }
}
