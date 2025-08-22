import 'dart:async';
import 'dart:ui';

import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/core/utils/sdkinitializer.dart';
import 'package:blankets_and_wines_example/data/models/UserRoles.dart';
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
  final VoidCallback onPaymentConfirm;

  const CartPanel({
    Key? key,
    required this.cartTotal,
    required this.isLargeScreen,
    required this.onRemoveFromCart,
    required this.onUpdateQuantity,
    required this.onClearCart,
    required this.onShowPayment,
    required this.onCloseCart,
    required this.onPaymentConfirm,
  }) : super(key: key);

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  bool isLoading = false;
  bool isProcessingPayment = false;
  String orderNumber = "";
  Timer? _paymentCheckTimer;
  int _checkAttempts = 0;
  int _pinWaitTime = 10;
  String _paymentStage = '';
  static const int MAX_CHECK_ATTEMPTS = 15; // 15 seconds of checking after PIN entry

  double get _calculatedTotal => cartG.total;

  @override
  void dispose() {
    _paymentCheckTimer?.cancel();
    super.dispose();
  }

  // ============ STREAMLINED M-PESA PAYMENT ============
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
                  width: 400,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Order Summary
                        _buildOrderSummary(),
                        SizedBox(height: 20),
                        
                        // Phone Number Input
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '0712345678',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green, width: 2),
                            ),
                          ),
                          validator: _validatePhoneNumber,
                          onChanged: (value) => setDialogState(() {}),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Payment Status or Button
                        isProcessingPayment
                            ? _buildPaymentProgress()
                            : _buildPaymentButton(
                                context, 
                                phoneController, 
                                formKey, 
                                setDialogState
                              ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (!isProcessingPayment)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(orderNumber, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildPaymentProgress() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Calm progress indicator
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
              backgroundColor: Colors.blue.shade100,
            ),
          ),
          SizedBox(height: 20),
          
          // Payment stage description
          Text(
            _paymentStage,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 12),
          
          // Different progress info based on stage
          if (_paymentStage.contains('PIN'))
            Column(
              children: [
                Text(
                  'Time remaining: ${_pinWaitTime}s',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (10 - _pinWaitTime) / 10,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                ),
              ],
            )
          else if (_paymentStage.contains('Confirming'))
            Text(
              'Checking payment status... (${_checkAttempts}/$MAX_CHECK_ATTEMPTS)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          else
            Text(
              'Please wait...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(
    BuildContext context,
    TextEditingController phoneController,
    GlobalKey<FormState> formKey,
    StateSetter setDialogState,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: phoneController.text.length >= 9
            ? () => _processAutoMpesaPayment(
                context, phoneController.text, setDialogState)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('Pay with M-Pesa', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Please enter phone number';
    if (value.length != 10) return 'Phone number must be 10 digits';
    if (!value.startsWith('07') && !value.startsWith('01')) {
      return 'Phone number must start with 07 or 01';
    }
    return null;
  }

  // ============ AUTOMATED PAYMENT PROCESSING ============
  void _processAutoMpesaPayment(
    BuildContext context,
    String phoneNumber,
    StateSetter setDialogState,
  ) async {
    try {
      setDialogState(() {
        isProcessingPayment = true;
        _checkAttempts = 0;
        _paymentStage = 'Sending M-Pesa prompt...';
      });

      // Step 1: Send M-Pesa prompt
      final pushSuccess = await _sendMpesaPrompt(phoneNumber);
      
      if (!pushSuccess) {
        _handlePaymentError(setDialogState, 'Failed to send M-Pesa prompt');
        return;
      }

      // Step 2: Give user time to enter PIN (10 seconds)
      setDialogState(() {
        _paymentStage = 'Check your phone and enter PIN';
      });
      
      await _waitForPinEntry(setDialogState);

      // Step 3: Start checking payment status from database
      setDialogState(() {
        _paymentStage = 'Confirming payment...';
      });
      
      _startAutomaticPaymentCheck(context, setDialogState);

    } catch (e) {
      _handlePaymentError(setDialogState, 'Payment processing failed: ${e.toString()}');
    }
  }

  Future<bool> _sendMpesaPrompt(String phoneNumber) async {
    try {
      final success = await CashierFunctions.SendSdkPush({
        "orderNo": orderNumber,
        "mpesaNo": phoneNumber,
        "amount": _calculatedTotal.toString(),
      });

      return success;
    } catch (e) {
      print("Error sending M-Pesa prompt: ${e.toString()}");
      return false;
    }
  }

  Future<void> _waitForPinEntry(StateSetter setDialogState) async {
    // Give user 10 seconds to enter PIN
    for (int i = 10; i > 0; i--) {
      setDialogState(() {
        _pinWaitTime = i;
      });
      await Future.delayed(Duration(seconds: 1));
    }
  }

  void _startAutomaticPaymentCheck(BuildContext context, StateSetter setDialogState) {
    _checkAttempts = 0;
    
    _paymentCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      _checkAttempts++;
      
      if (_checkAttempts > MAX_CHECK_ATTEMPTS) {
        timer.cancel();
        _handlePaymentTimeout(setDialogState);
        return;
      }

      setDialogState(() {}); // Update UI with new attempt count

      try {
        final paymentConfirmed = await CashierFunctions.confirmPayment(orderNumber);
        
        if (paymentConfirmed) {
          timer.cancel();
          setDialogState(() {
            _paymentStage = 'Payment successful!';
          });
          
          // Small delay to show success message
          await Future.delayed(Duration(milliseconds: 800));
          _handlePaymentSuccess(context);
          return;
        }
      } catch (e) {
        // Continue checking even if individual check fails
        print('Payment check attempt $_checkAttempts failed: $e');
      }
    });
  }

  void _handlePaymentSuccess(BuildContext context) async {
    try {
      Navigator.of(context).pop(); // Close payment dialog
      
      // Process the sale
      await _processPayment(orderNumber);
      
      // Clear cart
      cartG.items.clear();
      widget.onClearCart();
      
      // Show success dialog
      _showPaymentSuccessDialog(context);
      
    } catch (e) {
      ToastService.showError('Error completing payment: ${e.toString()}');
    } finally {
      setState(() => isProcessingPayment = false);
    }
  }

  void _handlePaymentTimeout(StateSetter setDialogState) {
    setDialogState(() {
      isProcessingPayment = false;
      _paymentStage = 'Payment timeout';
    });
    
    // Show a gentle timeout message
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Payment Timeout'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The payment is taking longer than expected.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Please check your phone for the M-Pesa prompt or try again.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close timeout dialog
                Navigator.of(context).pop(); // Close payment dialog
              },
              child: Text('Try Again Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                
                // Close timeout dialog
                // Stay in payment dialog to retry
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Check Again'),
            ),
          ],
        );
      },
    );
  }

  void _handlePaymentError(StateSetter setDialogState, String message) {
    setDialogState(() => isProcessingPayment = false);
    ToastService.showError(message);
  }

  // ============ PAYMENT OPTIONS ============
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
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total: KSHS ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: BarPOSTheme.successColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Order: $orderNumber',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: TextStyle(color: BarPOSTheme.errorColor)),
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
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  // ============ SUCCESS DIALOG ============
  void _showPaymentSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: BarPOSTheme.successColor, size: 32),
              SizedBox(width: 12),
              Text('Payment Completed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                'Receipt printed successfully.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
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

  // ============ ORDER AND PAYMENT PROCESSING ============
  void createOrder() async {
    if (isLoading) return;

    try {
      setState(() => isLoading = true);

      final response = await comms.postRequest(
        endpoint: "orders",
        data: cartG.toOrderFormat(),
      );

      if (response["rsp"]["success"]) {
        setState(() {
          orderNumber = response["rsp"]["data"]["orderNo"];
        });
        _showPaymentOptions(context);
      } else {
        ToastService.showError(response["rsp"]["message"] ?? "Failed to create order");
      }
    } catch (e) {
      ToastService.showError('Error creating order: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _processPayment(String orderNumber) async {
    try {
      // Socket connection for real-time updates
      Socket emitEv = IO.io(
        'ws://167.99.15.36:8080',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(3)
            .setReconnectionDelay(1000)
            .build(),
      );

      emitEv.onConnect((_) {
        emitEv.emit('order_created', {"barId": appUser.barId});
      });

      // Print receipt
      sdkInitializer();
      await SmartposPlugin.printReceipt({
        "storeName": "Blankets Bar",
        "receiptType": userData.userRole == "cashier" ? "Sale Receipt" : "Stockist Receipt",
        "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "time": DateFormat('HH:mm:ss').format(DateTime.now()),
        "orderNumber": orderNumber,
        "items": cartG.items.map((item) => {
          "name": item.drink.name,
          "quantity": item.quantity,
          "price": item.totalPrice.toStringAsFixed(2),
        }).toList(),
        "subtotal": cartG.total.toStringAsFixed(2),
        "tax": "0.00",
        "total": cartG.total.toStringAsFixed(2),
        "paymentMethod": "Mpesa",
      });

      emitEv.dispose();
      widget.onPaymentConfirm();
    } catch (e) {
      print("Error processing payment: $e");
      throw e;
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
                Text('Current Order', style: Theme.of(context).textTheme.headlineSmall),
                Row(
                  children: [
                    if (cartG.items.isNotEmpty)
                      IconButton(
                        onPressed: widget.onClearCart,
                        icon: Icon(Icons.clear_all, color: BarPOSTheme.errorColor, size: 28),
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
            child: cartG.items.isEmpty ? _buildEmptyCart(context) : _buildCartItems(),
          ),

          // Checkout Section
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
          Icon(Icons.shopping_cart_outlined, color: BarPOSTheme.secondaryText, size: 64),
          SizedBox(height: BarPOSTheme.spacingM),
          Text(
            'No items in cart',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: BarPOSTheme.secondaryText,
            ),
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
          onUpdateQuantity: (quantity) => widget.onUpdateQuantity(item.drink.id, quantity),
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
              onPressed: isLoading ? null : createOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: BarPOSTheme.successColor,
                foregroundColor: BarPOSTheme.primaryText,
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: BarPOSTheme.primaryText)
                  : Text('Create Order'),
            ),
          ),
        ],
      ),
    );
  }
}