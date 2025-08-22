import 'package:blankets_and_wines_example/core/utils/sdkinitializer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';

class DummyPrintPage extends StatelessWidget {
  const DummyPrintPage({super.key});

  Future<void> _testPrint() async {
    // First initialize SDK
    await sdkInitializer();

    // Dummy order details
    final String orderNumber = "ORD12345";
    final double subtotal = 1500.00;
    final double tax = 240.00;
    final double total = subtotal + tax;

    // Dummy items
    final List<Map<String, dynamic>> items = [
      {
        "name": "CASAMIGOS BLANCO 750ML",
        "quantity": 1,
        "price": "1200.00",
      },
      {
        "name": "HEINEKEN BOTTLE",
        "quantity": 2,
        "price": "300.00",
      },
    ];

    await SmartposPlugin.printReceipt({
      "storeName": "Blankets Bar",
      "receiptType": "Sale Receipt", // dummy role
      "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "time": DateFormat('HH:mm:ss').format(DateTime.now()),
      "orderNumber": orderNumber,
      "items": items,
      "subtotal": subtotal.toStringAsFixed(2),
      "tax": tax.toStringAsFixed(2),
      "total": total.toStringAsFixed(2),
      "paymentMethod": "Mpesa",
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dummy Print Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: _testPrint,
          child: const Text("Print Dummy Receipt"),
        ),
      ),
    );
  }
}
