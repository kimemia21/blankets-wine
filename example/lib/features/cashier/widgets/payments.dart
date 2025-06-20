import 'dart:ui';

import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/core/utils/sdkinitializer.dart';
import 'package:blankets_and_wines_example/features/cashier/functions/fetchDrinks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

class Payments {
  // M-Pesa Payment Method
  static void showMpesaPayment({
    required BuildContext context,
    required double amount,
    required String orderId,
    required Function(bool success, String? transactionId) onPaymentComplete,
    required Function(String orderId) printOrder,
  }) {
    final TextEditingController phoneController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.phone_android, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text('M-Pesa Payment'),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount to Pay: KSHS ${formatWithCommas(amount.toStringAsFixed(0))}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BarPOSTheme.successColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Enter Phone Number:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      prefixStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      if (value.length < 9) {
                        return 'Please enter a valid phone number';
                      }
                      if (!value.startsWith('07') && !value.startsWith('01')) {
                        return 'Phone number must start with 07 or 01';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      'You will receive an M-Pesa prompt on your phone. Enter your M-Pesa PIN to complete the transaction.',
                      style: TextStyle(fontSize: 14, color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onPaymentComplete(false, null);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: BarPOSTheme.errorColor),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop();
                    _processMpesaPayment(
                      context: context,
                      phoneNumber: '${phoneController.text}',
                      amount: amount,
                      orderId: orderId,
                      onPaymentComplete: onPaymentComplete,
                      printOrder: printOrder,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('Send Payment Request'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Card Payment Method
  static void showCardPayment({
    required BuildContext context,
    required double amount,
    required Function(bool success, String? transactionId) onPaymentComplete,
  }) {
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();
    final TextEditingController cvvController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.credit_card, color: Colors.blue, size: 28),
              SizedBox(width: 12),
              Text('Card Payment'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount to Pay: KSHS ${formatWithCommas(amount.toStringAsFixed(0))}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BarPOSTheme.successColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Card Number
                  Text('Card Number:'),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: cardNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberFormatter(),
                    ],
                    decoration: InputDecoration(
                      hintText: '1234 5678 9012 3456',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter card number';
                      }
                      if (value.replaceAll(' ', '').length < 16) {
                        return 'Please enter a valid card number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      // Expiry Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expiry Date:'),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: expiryController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                _ExpiryDateFormatter(),
                              ],
                              decoration: InputDecoration(
                                hintText: 'MM/YY',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter expiry';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // CVV
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CVV:'),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: cvvController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              decoration: InputDecoration(
                                hintText: '123',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter CVV';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onPaymentComplete(false, null);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: BarPOSTheme.errorColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  _processCardPayment(
                    context: context,
                    amount: amount,
                    onPaymentComplete: onPaymentComplete,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Process Payment'),
            ),
          ],
        );
      },
    );
  }

  // Cash Payment Method
  static void showCashPayment({
    required BuildContext context,
    required double amount,
    required Function(bool success, String? transactionId) onPaymentComplete,
  }) {
    final TextEditingController receivedController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double receivedAmount =
                double.tryParse(receivedController.text) ?? 0;
            double change = receivedAmount - amount;

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.money, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Text('Cash Payment'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount to Pay: KSHS ${formatWithCommas(amount.toStringAsFixed(0))}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BarPOSTheme.successColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Amount Received:'),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: receivedController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: 'KSHS ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount received';
                        }
                        double? received = double.tryParse(value);
                        if (received == null || received < amount) {
                          return 'Amount must be at least KSHS ${amount.toStringAsFixed(0)}';
                        }
                        return null;
                      },
                    ),
                    if (receivedAmount > 0) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              change >= 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                change >= 0
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Change:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'KSHS ${formatWithCommas(change.toStringAsFixed(0))}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    change >= 0
                                        ? Colors.green[700]
                                        : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPaymentComplete(false, null);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: BarPOSTheme.errorColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop();
                      onPaymentComplete(
                        true,
                        'CASH_${DateTime.now().millisecondsSinceEpoch}',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Complete Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static processPayment(String orderNumber) async {
    print("Processing sale with order number: $orderNumber");

    try {
      double subtotal = cartG.total;

      double tax = cartG.total - subtotal;

      print("Connecting to socket server...");
      // print("userId: ${currentUser.userId}");

      Socket emitEv = IO.io(
        'ws://167.99.15.36:8080',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(1000)
            .build(),
      );

      emitEv.onConnect((_) {
        print('Connected to server');

        // Now emit after connected
        emitEv.emit('order_created', {"barId": appUser.barId});
      });
      emitEv.onError((error) {
        print('Socket error: $error');
      });

      emitEv.onDisconnect((_) {
        print('Disconnected from server');
      });
      sdkInitializer();

      await SmartposPlugin.printReceipt({

        "storeName": "Blankets Bar",
         "receiptType": userData.userRole=="cashier"? "Sale Receipt" : "Stockist Receipt",
        "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "time": DateFormat('HH:mm:ss').format(DateTime.now()),
        "orderNumber": orderNumber,
        "items":
            cartG.items
                .map(
                  (item) => {
                    "name": item.drink.name,
                    "quantity": item.quantity,
                    "price": item.totalPrice.toStringAsFixed(2),
                  },
                )
                .toList(),
        "subtotal": subtotal.toStringAsFixed(2),
        "tax": tax.toStringAsFixed(2),
        "total": cartG.total.toStringAsFixed(2),
        "paymentMethod": "Mpesa",
      });

      emitEv.dispose();
    } catch (e) {
      print("Error printing receipt: $e");
    }
    cartG.items.clear();
  }

  static void _processMpesaPayment({
    required BuildContext context,
    required String phoneNumber,
    required double amount,
    required String orderId,
    required Function(bool success, String? transactionId) onPaymentComplete,
    required Function(String orderId) printOrder,
  }) async {
    // Store context related values

    // Show processing dialog
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text('Sending M-Pesa request...'),
              SizedBox(height: 8),
              Text(
                'Please check your phone for the M-Pesa prompt',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    try {
      // Call the actual M-Pesa payment API
      await CashierFunctions.SendSdkPush({
        "orderNo": orderId,
        "mpesaNo": phoneNumber,
        "amount": amount.toString(),
      }).then((p0) {
        processPayment(orderId);
        Navigator.pop(context);
        // Navigator.of(dialogContext).pop();
      });

      // Close dialog safely
    } catch (error) {
      //  processPayment(orderId);

      // Close dialog safely
      // if (dialogContext != null) {
      //   Navigator.of(dialogContext).pop();
      // }

      // // Show error message
      // scaffoldMessenger.showSnackBar(
      //   SnackBar(content: Text('Payment failed: ${error.toString()}')),
      // );

      // onPaymentComplete(false, null);
    }
  }

  // Private method to process Card payment
  static void _processCardPayment({
    required BuildContext context,
    required double amount,
    required Function(bool success, String? transactionId) onPaymentComplete,
  }) {
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text('Processing card payment...'),
            ],
          ),
        );
      },
    );

    // Simulate card processing
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close processing dialog

      // Simulate success/failure (95% success rate)
      bool success = DateTime.now().millisecond % 20 != 0;
      String? transactionId =
          success ? 'CARD_${DateTime.now().millisecondsSinceEpoch}' : null;

      onPaymentComplete(success, transactionId);
    });
  }
}

// Helper class for formatting card number input
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Helper class for formatting expiry date input
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
