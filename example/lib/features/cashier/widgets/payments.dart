import 'dart:async';
import 'dart:ui';
import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/OFFLINE/SaveTransaction.dart';
import 'package:blankets_and_wines_example/OFFLINE/TranctionsPrintService.dart';
import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/core/utils/sdkinitializer.dart';
import 'package:blankets_and_wines_example/data/models/Transaction.dart';
import 'package:blankets_and_wines_example/features/cashier/functions/fetchDrinks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class PaymentDialogWidget extends StatefulWidget {
  final String orderNumber;
  final double total;
  final bool isOffline;
  final Function() onPaymentComplete;
  final Function(String) onOrderNumberGenerated;

  const PaymentDialogWidget({
    Key? key,
    required this.orderNumber,
    required this.total,
    required this.isOffline,
    required this.onPaymentComplete,
    required this.onOrderNumberGenerated,
  }) : super(key: key);

  @override
  _PaymentDialogWidgetState createState() => _PaymentDialogWidgetState();
}

class _PaymentDialogWidgetState extends State<PaymentDialogWidget> {
  late TextEditingController phoneController;
  late TextEditingController transactionController;

  bool _isProcessing = false;
  Timer? _paymentTimer;
  int _checkAttempts = 0;
  static const int MAX_ATTEMPTS = 20;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController();
    transactionController = TextEditingController();
  }

  @override
  void dispose() {
    phoneController.dispose();
    transactionController.dispose();
    _paymentTimer?.cancel();
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _processOfflinePayment() async {
    try {
      // Process offline payment and print receipt
      await _printReceipt(widget.orderNumber, "Offline M-Pesa");

      Navigator.pop(context);
      _showSuccessDialog(widget.orderNumber);
      widget.onPaymentComplete();

      ToastService.showSuccess(
        'Offline payment completed with transaction: ${transactionController.text.trim()}',
      );
    } catch (e) {
      ToastService.showError(
        'Error processing offline payment: ${e.toString()}',
      );
    }
  }

  Future<void> _processOnlinePayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Send M-Pesa prompt
      final result = await CashierFunctions.SendSdkPush({
        "orderNo": widget.orderNumber,
        "mpesaNo": phoneController.text.trim(),
        "amount": cartG.total.toString(),
      });

      if (!result) {
        setState(() {
          _isProcessing = false;
        });
        ToastService.showError('Failed to send payment request');
        return;
      }

      // Start checking payment status
      _startPaymentCheck();
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ToastService.showError('Payment error: ${e.toString()}');
    }
  }

  void _startPaymentCheck() {
    _checkAttempts = 0;

    _paymentTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _checkAttempts++;
      });

      if (_checkAttempts > MAX_ATTEMPTS) {
        timer.cancel();
        setState(() {
          _isProcessing = false;
        });
        ToastService.showInfo('Payment timeout - please check manually');
        return;
      }

      try {
        final confirmed = await CashierFunctions.confirmPayment(
          widget.orderNumber,
        );
        if (confirmed) {
          timer.cancel();
          setState(() {
            _isProcessing = false;
          });

          await _printReceipt(widget.orderNumber, "M-Pesa");
          Navigator.pop(context);
          _showSuccessDialog(widget.orderNumber);
          widget.onPaymentComplete();
          return;
        }
      } catch (e) {
        print('Payment check failed: $e');
      }
    });
  }

Future<void> _printReceipt(String orderNumber, String paymentMethod) async {
  try {
    setState(() {
      _isProcessing = true;
    });

    // Make sure sdkInitializer is awaited if it's async
    await sdkInitializer();

    // Build the transaction object
    final transaction = Transaction.fromReceiptData(
      {
        "storeName": "Blankets Bar",
        "receiptType": userData.userRole == "Cashier"
            ? "Sale Receipt"
            : "Stockist Receipt",
        "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "time": DateFormat('HH:mm:ss').format(DateTime.now()),
        "orderNumber": orderNumber,
        "items": cartG.items
            .map(
              (item) => {
                "name": item.drink.name,
                "quantity": item.quantity,
                "price": item.totalPrice.toStringAsFixed(2),
              },
            )
            .toList(),
        "subtotal": cartG.total.toStringAsFixed(2),
        "tax": "0.00",
        "total": cartG.total.toStringAsFixed(2),
        "paymentMethod": paymentMethod,
      },
      userData.username, // Seller name
      lastDigits: paymentMethod == "Card" ? "1234" : null, // Optional last digits
    );

    // Save the transaction
    await TransactionService.saveTransaction(transaction);

    // Get all transactions (await if it's async)
    final allTransactions = await TransactionService.getAllTransactions();

    // Print the transaction report
    await TransactionReportPrinterService.printSellerReport(
      allTransactions,
      userData.username,
      storeName: "Blankets Bar",
      generatedBy: userData.username,
    );

    setState(() {
      _isProcessing = false;
    });

    // Emit order created event for online orders only
    if (paymentMethod != "Offline M-Pesa") {
      final socket = IO.io('ws://10.68.102.36:8002');
      socket.onConnect(
        (_) => socket.emit('order_created', {"barId": appUser.barId}),
      );
      socket.dispose();
    }
  } catch (e, s) {
    print("Print error: $e");
    print("Stack trace: $s");
  }
}

  void _showSuccessDialog(String orderNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 32,
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: BarPOSTheme.successColor,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Payment Complete',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Order: $orderNumber',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'KSH ${formatWithCommas(widget.total.toStringAsFixed(0))}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BarPOSTheme.successColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Receipt printed. Ready for next customer.',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BarPOSTheme.successColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Next Customer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone_android, color: Colors.green, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isOffline
                            ? 'Offline M-Pesa Payment'
                            : 'M-Pesa Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child:
                      widget.isOffline
                          ? _buildOfflinePaymentForm()
                          : _buildOnlinePaymentForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflinePaymentForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOrderSummary(),
        SizedBox(height: 20),

        // Customer Phone (optional for offline)
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Customer Phone (Optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),

        SizedBox(height: 16),

        // Transaction ID Input
        TextField(
          controller: transactionController,
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'M-Pesa Transaction ID *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),

        SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child:
              _isProcessing
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed:
                        transactionController.text.trim().isNotEmpty
                            ? _processOfflinePayment
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          transactionController.text.trim().isNotEmpty
                              ? Colors.green
                              : Colors.grey[300],
                      foregroundColor:
                          transactionController.text.trim().isNotEmpty
                              ? Colors.white
                              : Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation:
                          transactionController.text.trim().isNotEmpty ? 2 : 0,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                    ),
                    child: Text(
                      'Complete Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildOnlinePaymentForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOrderSummary(),
        SizedBox(height: 20),

        if (!_isProcessing) ...[
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Customer Phone Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  phoneController.text.trim().length >= 9
                      ? _processOnlinePayment
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    phoneController.text.trim().length >= 9
                        ? Colors.green
                        : Colors.grey[300],
                foregroundColor:
                    phoneController.text.trim().length >= 9
                        ? Colors.white
                        : Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: phoneController.text.trim().length >= 9 ? 2 : 0,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
              ),
              child: Text(
                'Send Payment Request',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ] else ...[
          _buildProcessingWidget(),
        ],
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      width: double.infinity,
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
              Text(
                'Order ID:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Flexible(
                child: Text(
                  widget.orderNumber,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                'KSH ${formatWithCommas(widget.total.toStringAsFixed(0))}',
                style: TextStyle(
                  fontSize: 20,
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

  Widget _buildProcessingWidget() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Processing payment...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Attempt $_checkAttempts/$MAX_ATTEMPTS',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Helper function to show the payment dialog
void showPaymentDialog(
  BuildContext context,
  String orderNumber,
  double total,
  bool isOffline, {
  required Function() onPaymentComplete,
  required Function(String) onOrderNumberGenerated,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => PaymentDialogWidget(
          orderNumber: orderNumber,
          total: total,
          isOffline: isOffline,
          onPaymentComplete: onPaymentComplete,
          onOrderNumberGenerated: onOrderNumberGenerated,
        ),
  );
}
