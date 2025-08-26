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
  bool _isCancelled = false;
  String orderNumber = "";
  Timer? _paymentCheckTimer;
  int _checkAttempts = 0;
  int _pinWaitTime = 15; // Increased to 15 seconds for customer PIN entry
  String _paymentStage = '';
  static const int MAX_CHECK_ATTEMPTS =
      20; // 20 seconds of checking after PIN entry

  double get _calculatedTotal => cartG.total;

  // EDIT 1: Modify _showMpesaPayment method to reset states when dialog opens
  void _showMpesaPayment(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    Navigator.of(context).pop(); // Close payment options dialog

    print("==========${userData.userRole}=========");
    // RESET ALL PAYMENT STATES WHEN DIALOG OPENS
    setState(() {
      _isCancelled = false;
      isProcessingPayment = false;
      _paymentStage = '';
      _checkAttempts = 0;
      _pinWaitTime = 15; // Reset to initial value
    });

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
                    Text('Customer M-Pesa Payment'),
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
                          validator: _validatePhoneNumber,
                          onChanged: (value) {
                            _lastUsedPhoneNumber = value; // Store for later use
                            setDialogState(() {});
                          },
                        ),

                        SizedBox(height: 20),

                        // Payment Status or Button
                        isProcessingPayment
                            ? _buildPaymentProgress(
                              setDialogState,
                            ) // Pass setDialogState
                            : _buildPaymentButton(
                              context,
                              phoneController,
                              formKey,
                              setDialogState,
                            ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (!isProcessingPayment)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
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

  // EDIT 2: Modify _buildPaymentProgress to accept and use setDialogState
  Widget _buildPaymentProgress([StateSetter? setDialogState]) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Subtle progress indicator
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade300),
              backgroundColor: Colors.blue.shade50,
            ),
          ),
          SizedBox(height: 16),

          // Payment stage description
          Text(
            _paymentStage,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.blue[600],
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 10),

          // Different progress info based on stage
          if (_paymentStage.contains('customer'))
            Column(
              children: [
                Text(
                  'Customer has ${_pinWaitTime}s to enter PIN',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (15 - _pinWaitTime) / 15,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade300,
                  ),
                  minHeight: 3,
                ),
              ],
            )
          else if (_paymentStage.contains('Verifying'))
            Text(
              'Checking payment... (${_checkAttempts}/${MAX_CHECK_ATTEMPTS}s)',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            )
          else
            Text(
              'Processing...',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),

          // Cancel button
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed:
                  () => _cancelPaymentProcess(
                    setDialogState,
                  ), // Pass setDialogState
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel Payment',
                style: TextStyle(color: Colors.red.shade600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EDIT 4: Modify _processAutoMpesaPayment to properly reset states at the beginning
  void _processAutoMpesaPayment(
    BuildContext context,
    String phoneNumber,
    StateSetter setDialogState,
  ) async {
    try {
      // COMPLETELY RESET ALL PAYMENT STATES
      setState(() {
        _isCancelled = false;
        isProcessingPayment = true;
        _checkAttempts = 0;
        _pinWaitTime = 15; // Reset PIN wait time
        _paymentStage = 'Sending payment request...';
      });

      setDialogState(() {
        isProcessingPayment = true;
        _checkAttempts = 0;
        _paymentStage = 'Sending payment request...';
      });

      // Cancel any existing timers
      _paymentCheckTimer?.cancel();

      // Step 1: Send M-Pesa prompt and verify it was successful
      final pushResult = await _sendMpesaPromptWithValidation(phoneNumber);

      if (_isCancelled) return; // Exit if cancelled during request

      if (!pushResult['success']) {
        _handlePaymentError(setDialogState, pushResult['message']);
        return;
      }

      // Step 2: Give customer time to enter PIN (15 seconds)
      setDialogState(() {
        _paymentStage = 'Waiting for customer to enter PIN';
        _pinWaitTime = 15; // Ensure PIN wait time is reset
      });

      await _waitForPinEntry(setDialogState);

      if (_isCancelled) return; // Exit if cancelled during PIN wait

      // Step 3: Start checking payment status from database
      setDialogState(() {
        _paymentStage = 'Verifying payment...';
      });

      _startAutomaticPaymentCheck(context, setDialogState);
    } catch (e) {
      if (!_isCancelled) {
        _handlePaymentError(
          setDialogState,
          'Payment processing error: ${e.toString()}',
        );
      }
    }
  }

  // EDIT 5: Add a method to completely reset payment states
  void _resetPaymentStates() {
    _paymentCheckTimer?.cancel();
    setState(() {
      _isCancelled = false;
      isProcessingPayment = false;
      _paymentStage = '';
      _checkAttempts = 0;
      _pinWaitTime = 15;
    });
  }

  // EDIT 6: Call reset when showing payment options (optional - extra safety)
  void _showPaymentOptions(BuildContext context) {
    // Reset payment states when showing payment options
    _resetPaymentStates();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: AlertDialog(
            title: Text(
              'Process Payment',
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
                    'Amount: KSH ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 20),
                  _buildPaymentOption(
                    context,
                    'M-Pesa Payment',
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
                child: Text(
                  'Cancel',
                  style: TextStyle(color: BarPOSTheme.errorColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ STREAMLINED M-PESA PAYMENT ============

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
              Text('Order ID:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(orderNumber, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'KSH ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
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

  // 3. ADD CANCEL FUNCTIONALITY METHOD

  Widget _buildPaymentButton(
    BuildContext context,
    TextEditingController phoneController,
    GlobalKey<FormState> formKey,
    StateSetter setDialogState,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed:
            phoneController.text.length >= 9
                ? () => _processAutoMpesaPayment(
                  context,
                  phoneController.text,
                  setDialogState,
                )
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text('Send Payment Request', style: TextStyle(fontSize: 15)),
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Enter customer phone number';
    if (value.length != 10) return 'Must be 10 digits (07XXXXXXXX)';
    if (!value.startsWith('07') && !value.startsWith('01')) {
      return 'Must start with 07 or 01';
    }
    return null;
  }

  Future<void> _waitForPinEntry(StateSetter setDialogState) async {
    // Give customer 15 seconds to enter PIN
    for (int i = 15; i > 0; i--) {
      if (_isCancelled) return; // Exit if cancelled

      setDialogState(() {
        _pinWaitTime = i;
      });
      await Future.delayed(Duration(seconds: 1));
    }
  }

  // void _startAutomaticPaymentCheck(
  //   BuildContext context,
  //   StateSetter setDialogState,
  // ) {
  //   _checkAttempts = 0;

  //   _paymentCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
  //     // Check for cancellation first
  //     if (_isCancelled) {
  //       timer.cancel();
  //       return;
  //     }

  //     _checkAttempts++;

  //     if (_checkAttempts > MAX_CHECK_ATTEMPTS) {
  //       timer.cancel();
  //       if (!_isCancelled) {
  //         // Only show timeout if not cancelled
  //         _handlePaymentTimeout(setDialogState);
  //       }
  //       return;
  //     }

  //     setDialogState(() {}); // Update UI with new attempt count

  //     try {
  //       final paymentConfirmed = await CashierFunctions.confirmPayment(
  //         orderNumber,
  //       );

  //       if (paymentConfirmed && !_isCancelled) {
  //         timer.cancel();
  //         setDialogState(() {
  //           _paymentStage = 'Payment received!';
  //         });

  //         // Small delay to show success message
  //         await Future.delayed(Duration(milliseconds: 600));
  //         _handlePaymentSuccess(context);
  //         return;
  //       }
  //     } catch (e) {
  //       // Continue checking even if individual check fails
  //       print('Payment check attempt $_checkAttempts failed: $e');
  //     }
  //   });
  // }

  // 7. HELPER WIDGET FOR ERROR DIALOG OPTIONS
  Widget _buildErrorOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. MODIFY dispose() METHOD TO RESET CANCELLATION STATE
  @override
  void dispose() {
    _paymentCheckTimer?.cancel();
    _isCancelled = false;
    super.dispose();
  }

  // ============ AUTOMATED PAYMENT PROCESSING ============

  Future<Map<String, dynamic>> _sendMpesaPromptWithValidation(
    String phoneNumber,
  ) async {
    try {
      final result = await CashierFunctions.SendSdkPush({
        "orderNo": orderNumber,
        "mpesaNo": phoneNumber,
        "amount": _calculatedTotal.toString(),
      });

      if (result) {
        return {
          'success': true,
          'message': 'Payment request sent successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to send payment request. Check customer phone number and try again.',
        };
      }
    } catch (e) {
      print("Error sending M-Pesa prompt: ${e.toString()}");
      return {
        'success': false,
        'message': 'Network error. Unable to send payment request.',
      };
    }
  }

  // EDIT 1: Fix _handlePaymentSuccess to use context properly and avoid navigation issues
  void _handlePaymentSuccess(BuildContext context) async {
    try {
      // Check if context is still valid before proceeding
      if (!mounted) return;

      // Close payment dialog first, but safely
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close payment dialog
      }

      // Process the sale
      await _processPayment(orderNumber);

      // Clear cart
      cartG.items.clear();
      widget.onClearCart();

      // Show success dialog only if context is still valid
      if (mounted) {
        _showPaymentSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError('Error completing payment: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isProcessingPayment = false);
      }
    }
  }

  // EDIT 2: Fix _startAutomaticPaymentCheck to handle context safely
  void _startAutomaticPaymentCheck(
    BuildContext context,
    StateSetter setDialogState,
  ) {
    _checkAttempts = 0;

    _paymentCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      // Check for cancellation first
      if (_isCancelled || !mounted) {
        timer.cancel();
        return;
      }

      _checkAttempts++;

      if (_checkAttempts > MAX_CHECK_ATTEMPTS) {
        timer.cancel();
        if (!_isCancelled && mounted) {
          // Check mounted state
          _handlePaymentTimeout(setDialogState);
        }
        return;
      }

      // Safely update dialog state
      if (mounted) {
        setDialogState(() {}); // Update UI with new attempt count
      }

      try {
        final paymentConfirmed = await CashierFunctions.confirmPayment(
          orderNumber,
        );

        if (paymentConfirmed && !_isCancelled && mounted) {
          timer.cancel();

          // Update dialog state to show success
          if (mounted) {
            setDialogState(() {
              _paymentStage = 'Payment received!';
            });
          }

          // Small delay to show success message, then handle success
          await Future.delayed(Duration(milliseconds: 800));

          // Check if still mounted before proceeding
          if (mounted && !_isCancelled) {
            _handlePaymentSuccess(context);
          }
          return;
        }
      } catch (e) {
        // Continue checking even if individual check fails
        print('Payment check attempt $_checkAttempts failed: $e');
      }
    });
  }

  // EDIT 3: Fix _handlePaymentError to handle navigation safely
  void _handlePaymentError(StateSetter setDialogState, String message) {
    if (!mounted) return;

    setDialogState(() => isProcessingPayment = false);

    // Show improved error dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Use different context variable
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Failed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Order #$orderNumber',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            content: Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'What would you like to do?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildErrorOption(
                    icon: Icons.refresh,
                    title: 'Try Again',
                    subtitle: 'Retry the payment process',
                    color: Colors.blue,
                  ),
                  SizedBox(height: 8),
                  _buildErrorOption(
                    icon: Icons.cancel_outlined,
                    title: 'Cancel Order',
                    subtitle: 'Cancel this transaction',
                    color: Colors.red,
                  ),
                ],
              ),
            ),
            actions: [
              // Cancel Order Button
              TextButton(
                onPressed: () {
                  // Safe navigation - check if can pop before popping
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop(); // Close error dialog
                  }
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(); // Close payment dialog
                  }
                  ToastService.showError(
                    'Order cancelled due to payment failure',
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                ),
                child: Text('Cancel Order'),
              ),

              // Try Again Button
              ElevatedButton(
                onPressed: () {
                  // Safe navigation
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop(); // Close error dialog
                  }
                  // Reset states and try again
                  if (mounted) {
                    setDialogState(() {
                      isProcessingPayment = false;
                      _paymentStage = '';
                      _isCancelled = false;
                      _pinWaitTime = 15;
                      _checkAttempts = 0;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Try Again'),
              ),
            ],
          ),
        );
      },
    );
  }

  // EDIT 4: Fix _cancelPaymentProcess to handle navigation safely
  void _cancelPaymentProcess([StateSetter? setDialogState]) {
    // Cancel any running timers first
    _paymentCheckTimer?.cancel();

    // Reset all states
    if (mounted) {
      setState(() {
        _isCancelled = true;
        isProcessingPayment = false;
        _paymentStage = '';
      });
    }

    // Also reset dialog state if available
    if (setDialogState != null && mounted) {
      setDialogState(() {
        isProcessingPayment = false;
        _paymentStage = '';
      });
    }

    // Show cancellation confirmation
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use different context variable
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Payment Cancelled'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('The payment process has been cancelled.'),
              SizedBox(height: 8),
              Text(
                'Order #$orderNumber has been created but not paid.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Safe navigation
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop(); // Close confirmation
                }
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(); // Close payment dialog
                }
                ToastService.showInfo('Payment cancelled');
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // EDIT 5: Fix _handlePaymentTimeout to handle navigation safely
  void _handlePaymentTimeout(StateSetter setDialogState) {
    if (!mounted) return;

    setDialogState(() {
      isProcessingPayment = false;
      _paymentStage = 'Payment taking longer than expected';
    });

    // Show improved timeout dialog with better options
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Use different context variable
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Payment Status'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The payment is taking longer than usual.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Options:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Confirm Payment: Check if customer already paid',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 4),
              Text(
                '• Prompt Again: Send new payment request',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 4),
              Text(
                '• Cancel: Cancel this order',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            // Cancel Order
            TextButton(
              onPressed: () {
                // Safe navigation
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop(); // Close timeout dialog
                }
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(); // Close payment dialog
                }
                ToastService.showInfo('Order cancelled');
              },
              child: Text('Cancel Order', style: TextStyle(color: Colors.red)),
            ),

            // Confirm Payment
            TextButton(
              onPressed: () async {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop(); // Close timeout dialog
                }
                if (mounted) {
                  await _checkPaymentOnly(setDialogState);
                }
              },
              child: Text(
                'Confirm Payment',
                style: TextStyle(color: Colors.blue),
              ),
            ),

            // Prompt Again
            ElevatedButton(
              onPressed: () async {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop(); // Close timeout dialog
                }
                if (mounted) {
                  await _promptAgainInSameDialog(setDialogState);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Prompt Again'),
            ),
          ],
        );
      },
    );
  }

  // EDIT 6: Add safety checks to _checkPaymentOnly
  Future<void> _checkPaymentOnly(StateSetter setDialogState) async {
    if (!mounted) return;

    try {
      // Show loading briefly
      setDialogState(() {
        isProcessingPayment = true;
        _paymentStage = 'Checking payment status...';
      });

      final paymentConfirmed = await CashierFunctions.confirmPayment(
        orderNumber,
      );

      if (!mounted) return;

      if (paymentConfirmed) {
        _handlePaymentSuccess(context);
        ToastService.showSuccess('Payment confirmed!');
      } else {
        setDialogState(() {
          isProcessingPayment = false;
          _paymentStage = 'No payment found yet';
        });
        ToastService.showInfo('No payment found. Customer may need more time.');
      }
    } catch (e) {
      if (!mounted) return;

      setDialogState(() {
        isProcessingPayment = false;
        _paymentStage = 'Error checking payment';
      });
      ToastService.showError('Error checking payment: ${e.toString()}');
    }
  }

  // EDIT 7: Add safety checks to _promptAgainInSameDialog
  Future<void> _promptAgainInSameDialog(StateSetter setDialogState) async {
    if (!mounted) return;

    try {
      // First, check if payment already exists
      setDialogState(() {
        isProcessingPayment = true;
        _paymentStage = 'Checking if customer already paid...';
      });

      final paymentConfirmed = await CashierFunctions.confirmPayment(
        orderNumber,
      );

      if (!mounted) return;

      if (paymentConfirmed) {
        _handlePaymentSuccess(context);
        ToastService.showSuccess('Payment was already completed!');
        return;
      }

      // If no payment found, send new prompt using the same dialog
      setDialogState(() {
        _paymentStage = 'Sending new payment request...';
      });

      // Get the phone number from the text field in the current dialog
      final phoneNumber = _getCurrentPhoneNumber();

      if (phoneNumber.isEmpty) {
        setDialogState(() {
          isProcessingPayment = false;
          _paymentStage = 'Phone number required';
        });
        ToastService.showError('Please enter customer phone number');
        return;
      }

      // Send new prompt with validation
      final pushResult = await _sendMpesaPromptWithValidation(phoneNumber);

      if (!mounted) return;

      if (!pushResult['success']) {
        setDialogState(() {
          isProcessingPayment = false;
          _paymentStage = 'Failed to send payment request';
        });
        ToastService.showError(pushResult['message']);
        return;
      }

      // If successful, continue with normal flow
      setDialogState(() {
        _paymentStage = 'Waiting for customer to enter PIN';
        _pinWaitTime = 15; // Reset PIN wait time
      });

      await _waitForPinEntry(setDialogState);

      if (!mounted || _isCancelled) return;

      setDialogState(() {
        _paymentStage = 'Verifying payment...';
      });

      _startAutomaticPaymentCheck(context, setDialogState);
    } catch (e) {
      if (!mounted) return;

      setDialogState(() {
        isProcessingPayment = false;
        _paymentStage = 'Error occurred';
      });
      ToastService.showError('Error: ${e.toString()}');
    }
  }

  // Helper to get current phone number from dialog (you'll need to store this)
  String _getCurrentPhoneNumber() {
    // This should return the phone number from the current dialog
    // You might need to store this as a class variable or pass it differently
    // For now, returning empty string - you'll need to modify this based on your implementation
    return _lastUsedPhoneNumber ?? '';
  }

  String? _lastUsedPhoneNumber; // Add this as a class variable

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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
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
              Icon(
                Icons.check_circle,
                color: BarPOSTheme.successColor,
                size: 32,
              ),
              SizedBox(width: 12),
              Text('Sale Completed'),
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
                'Amount: KSH ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BarPOSTheme.successColor,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Receipt printed. Ready for next customer.',
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
                child: Text('Next Customer', style: TextStyle(fontSize: 16)),
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
        ToastService.showError(
          response["rsp"]["message"] ?? "Failed to create order",
        );
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
        'ws://10.68.102.36:8002',
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
        "receiptType":
            userData.userRole == "Cashier"
                ? "Sale Receipt"
                : "Stockist Receipt",
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
          Icon(
            Icons.shopping_cart_outlined,
            color: BarPOSTheme.secondaryText,
            size: 64,
          ),
          SizedBox(height: BarPOSTheme.spacingM),
          Text(
            'No items in order',
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
                'KSH ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
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
              child:
                  isLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BarPOSTheme.primaryText,
                        ),
                      )
                      : Text('Process Payment', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
