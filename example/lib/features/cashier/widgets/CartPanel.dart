import 'dart:async';
import 'dart:ui';

import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/core/utils/sdkinitializer.dart';
import 'package:blankets_and_wines_example/features/cashier/functions/fetchDrinks.dart';
import 'package:blankets_and_wines_example/features/cashier/widgets/Cartitem.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

class CartPanel extends StatefulWidget {
  final double cartTotal;
  final bool isLargeScreen;
  final Function(int) onRemoveFromCart;
  final Function(int, int) onUpdateQuantity;
  final VoidCallback onClearCart;
  final VoidCallback onShowPayment;
  final VoidCallback onCloseCart;


  const CartPanel({
    Key? key,
    required this.cartTotal,
    required this.isLargeScreen,
    required this.onRemoveFromCart,
    required this.onUpdateQuantity,
    required this.onClearCart,
    required this.onShowPayment,
    required this.onCloseCart,

  }) : super(key: key);

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  bool isLoading = false;
  String orderNumber = "";

  double get _calculatedTotal {
    return cartG.total;
  }

  // ============ PAYMENT METHODS ============

  void _showPaymentOptions(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: AlertDialog(
            title: Text(
              'Select Payment Method',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: BarPOSTheme.primaryText,
              ),
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.55,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Total Amount: KSHS ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: BarPOSTheme.successColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'ORDER NUMBER: $orderNumber',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: BarPOSTheme.successColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildPaymentOption(
                    context,
                    'M-Pesa',
                    Icons.phone_android,
                    Colors.green,
                    () => _showMpesaPayment(context),
                  ),
                  SizedBox(height: 12),
                  // _buildPaymentOption(
                  //   context,
                  //   'Cash',
                  //   Icons.money,
                  //   Colors.orange,
                  //   () => _showCashPayment(context),
                  // ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: BarPOSTheme.errorColor, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: BarPOSTheme.primaryText,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  // ============ M-PESA PAYMENT ============

  // ============ CASH PAYMENT ============

  void _showCashPayment(BuildContext context) {
    final TextEditingController receivedController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    Navigator.of(context).pop(); // Close payment options dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double receivedAmount =
                double.tryParse(receivedController.text) ?? 0;
            double change = receivedAmount - _calculatedTotal;

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
                      'Amount to Pay: KSHS ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
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
                        if (received == null || received < _calculatedTotal) {
                          return 'Amount must be at least KSHS ${_calculatedTotal.toStringAsFixed(0)}';
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
                    _onPaymentComplete(false, null);
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
                      _onPaymentComplete(
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

  // ============ PAYMENT PROCESSING ============
  // Helper method for instruction steps
  Widget _buildInstructionStep(String number, String instruction) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue[600],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            instruction,
            style: TextStyle(
              fontSize: 15,
              color: Colors.blue[600],
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // Replace the _showMpesaPayment method and add these new methods to your CartPanel class
  void _showMpesaPayment(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    Navigator.of(context).pop(); // Close payment options dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                content: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  constraints: BoxConstraints(
                    maxWidth: 600,
                    minWidth: 400,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order Details Section
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Order Number:'),
                                    Text(
                                      orderNumber,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Amount:'),
                                    Text(
                                      'KSHS ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Phone Number Section
                          Text(
                            'Enter Phone Number:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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
                              hintText: '0712345678',
                              // prefixText: '+254 ',
                              prefixStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.green,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter phone number';
                              }
                              if (value.length != 10 && value.length < 10) {
                                return 'Phone number must be 10 digits';
                              }
                              if (!value.startsWith('07') &&
                                  !value.startsWith('01')) {
                                return 'Phone number must start with 07 or 01';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setDialogState(() {}); // Refresh dialog state
                            },
                          ),

                          SizedBox(height: 20),

                          // Action Buttons Section
                          Column(
                            children: [
                              // Send Prompt Button
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      phoneController.text.length >= 9
                                          ? () => _sendMpesaPrompt(
                                            context,
                                            phoneController.text,
                                            setDialogState,
                                          )
                                          : null,
                                  icon: Icon(Icons.send),
                                  label: Text('Send M-Pesa Prompt'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 12),

                              // Confirm Payment Button
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      phoneController.text.length >= 9
                                          ? () => _confirmMpesaPayment(
                                            context,
                                            phoneController.text,
                                            setDialogState,
                                          )
                                          : null,
                                  icon: Icon(Icons.check_circle),
                                  label: Text('Confirm Payment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16),

                          // Instructions
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Instructions:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '1. Click "Send M-Pesa Prompt" to initiate payment',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[600],
                                  ),
                                ),
                                Text(
                                  '2. Check your phone for M-Pesa notification',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[600],
                                  ),
                                ),
                                Text(
                                  '3. Enter your M-Pesa PIN on your phone',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[600],
                                  ),
                                ),
                                Text(
                                  '4. Click "Confirm Payment" to complete transaction',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Don't clear cart or process payment on cancel
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: BarPOSTheme.errorColor.withOpacity(
                            0.1,
                          ),
                          foregroundColor: BarPOSTheme.errorColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Method to send M-Pesa prompt
  void _sendMpesaPrompt(
    BuildContext context,
    String phoneNumber,
    StateSetter setDialogState,
  ) async {
    try {
      setDialogState(() {
        isLoading = true;
      });

      // Show loading state
      ToastService.showInfo("Sending M-Pesa prompt to $phoneNumber...");

      // Here you would typically call an API to initiate the M-Pesa prompt
      // For now, we'll simulate the API call
      CashierFunctions.SendSdkPush({
        "orderNo": orderNumber,
        "mpesaNo": phoneNumber,
        "amount": _calculatedTotal.toString(),
      }).then((p0) {
        setDialogState(() {
          isLoading = false;
        });
      });

      // ToastService.showSuccess("M-Pesa prompt sent! Check your phone.");
    } catch (e) {
      setDialogState(() {
        isLoading = false;
      });
      ToastService.showError("Failed to send M-Pesa prompt: ${e.toString()}");
    }
  }

  // Method to confirm M-Pesa payment
  void _confirmMpesaPayment(
    BuildContext context,
    String phoneNumber,
    StateSetter setDialogState,
  ) async {
    try {
      setDialogState(() {
        isLoading = true;
      });

      // Show loading state
      ToastService.showInfo("Confirming payment...");


  
      await CashierFunctions.confirmPayment(orderNumber).then((p0)async{

        setDialogState(() {
        isLoading = false;
      });

      if (p0) {
       Navigator.of(context).pop(); // Close the payment dialog
       await _processPayment(orderNumber);
       

        // Clear cart and update UI
        cartG.items.clear();
        widget.onClearCart();

        // Show final success dialog
        _showPaymentSuccessDialog(context);
      }
      });


  
    } catch (e) {
      setDialogState(() {
        isLoading = false;
      });
      ToastService.showError("Payment confirmation failed: ${e.toString()}");
    }
  }

  // Final success dialog
  void _showPaymentSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: BarPOSTheme.successColor,
                size: 32,
              ),
              SizedBox(width: 12),
              Text('Payment Completed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Order: $orderNumber',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Amount: KSHS ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BarPOSTheme.successColor,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Receipt has been printed successfully.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close success dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BarPOSTheme.successColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPayment(String orderNumber) async {
    print("Processing sale with order number: $orderNumber");

    try {
      double subtotal = cartG.total;
      double tax = 0; // Tax calculation fixed

      print("Connecting to socket server...");

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
  }

  // ============ PAYMENT COMPLETION ============

  void _onPaymentComplete(bool success, String? transactionId) {
    if (success) {
      _showPaymentSuccess(context, transactionId);
    } else {
      _showPaymentError(context, 'Payment failed. Please try again.');
    }
  }

  void _showPaymentSuccess(BuildContext context, String? transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: BarPOSTheme.successColor,
                size: 28,
              ),
              SizedBox(width: 12),
              Text('Payment Successful!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: KSHS ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
              ),
              if (transactionId != null) Text('Transaction ID: $transactionId'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close success dialog
                cartG.items.clear(); // Clear the cart
                widget.onClearCart(); // Call parent clear cart function
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BarPOSTheme.successColor,
              ),
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: BarPOSTheme.errorColor, size: 28),
              SizedBox(width: 12),
              Text('Payment Failed'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============ ORDER CREATION ============

  void createOrder() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await comms.postRequest(
        endpoint: "orders",
        data: cartG.toOrderFormat(),
      );

      if (response["rsp"]["success"]) {
        setState(() {
          isLoading = false;
          orderNumber = response["rsp"]["data"]["orderNo"];
        });

        _showPaymentOptions(context);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error creating order: $e');
    }
  }

  // ============ UI BUILD METHODS ============

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: BarPOSTheme.accentDark),
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: BarPOSTheme.cardPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Order',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  children: [
                    if (cartG.items.isNotEmpty)
                      IconButton(
                        onPressed: widget.onClearCart,
                        icon: Icon(
                          Icons.clear_all,
                          color: BarPOSTheme.errorColor,
                          size: 28,
                        ),
                      ),
                    if (!widget.isLargeScreen)
                      IconButton(
                        onPressed: widget.onCloseCart,
                        icon: Icon(Icons.close, size: 28),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Cart Items
          Expanded(
            child:
                cartG.items.isEmpty
                    ? _buildEmptyCart(context)
                    : _buildCartItems(),
          ),

          // Total and Checkout
          if (cartG.items.isNotEmpty) _buildCheckoutSection(context),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: BarPOSTheme.secondaryText,
            size: 64,
          ),
          SizedBox(height: BarPOSTheme.spacingM),
          Text(
            'No items in cart',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: BarPOSTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: BarPOSTheme.spacingL),
      itemCount: cartG.items.length,
      itemBuilder: (context, index) {
        final item = cartG.items[index];
        return CartItemTile(
          cartItem: item,
          onRemove: () => widget.onRemoveFromCart(item.drink.id),
          onUpdateQuantity:
              (quantity) => widget.onUpdateQuantity(item.drink.id, quantity),
        );
      },
    );
  }

  Widget _buildCheckoutSection(BuildContext context) {
    return Container(
      padding: BarPOSTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: BarPOSTheme.buttonColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(BarPOSTheme.radiusLarge),
          topRight: Radius.circular(BarPOSTheme.radiusLarge),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: Theme.of(context).textTheme.headlineSmall),
              Text(
                'KSHS ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
                style: BarPOSTheme.totalPriceTextStyle,
              ),
            ],
          ),
          SizedBox(height: BarPOSTheme.spacingL),
          SizedBox(
            width: double.infinity,
            height: BarPOSTheme.buttonHeight,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => createOrder(),
              style: ElevatedButton.styleFrom(
                backgroundColor: BarPOSTheme.successColor,
                foregroundColor: BarPOSTheme.primaryText,
              ),
              child:
                  isLoading
                      ? CircularProgressIndicator(
                        color: BarPOSTheme.primaryText,
                      )
                      : Text('Create Order'),
            ),
          ),
        ],
      ),
    );
  }
}
