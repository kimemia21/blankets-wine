import 'dart:async';

import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/data/models/DrinkCategory.dart';
import 'package:blankets_and_wines_example/data/models/Product.dart';
import 'package:blankets_and_wines_example/data/services/FetchGlobals.dart';
import 'package:blankets_and_wines_example/OFFLINE/CacheService.dart';
import 'package:flutter/widgets.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class CashierFunctions {
  static const int REQUEST_TIMEOUT = 25; // Reduced from 30 for faster feedback
  static const int PAYMENT_CHECK_TIMEOUT =
      12; // Shorter timeout for payment checks

  static final List<String> categories = [
    'All',
    'Whiskey',
    'Premium Whiskey',
    'Vodka',
    'Premium Vodka',
    'Brandy',
    'Premium Brandy',
    'Champagne',
    'Premium Champagne',
    'Wine',
    'Tequila',
    'Premium Tequila',
    'Rum',
    'Local Premium',
    'Liqueur',
  ];

  // ============ DATA FETCHING METHODS ============

  static bool _isProductsSyncing = false;
  static bool _isCategoriesSyncing = false;
  
  // Remove this line, as 'await' cannot be used at the class level.
  // If you need to check connectivity, do it inside an async function like below:
  
  // Example usage inside an async function:
  // bool result = await InternetConnection().hasInternetAccess;
    
  
  static Future<List<Product>> fetchDrinks(String endpoint) async {
     bool result = await InternetConnection().hasInternetAccess;
    
 
    // Always try to get fresh data first if connected
    if (result) {
      mode = "online";

      try {
        final drinks = await fetchGlobal<Product>(
          getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
          fromJson: (json) => Product.fromJson(json),
          endpoint: endpoint,
        ).timeout(Duration(seconds: REQUEST_TIMEOUT));

        // Cache the fetched data (non-blocking)
        _cacheProductsAsync(drinks);
        print("Products fetched and being cached");
        
        return drinks;
      } on TimeoutException {
        print("Network timeout, returning cached data");
        return CacheService.getCachedProducts();
      } catch (e) {
        print("fetchDrinks error: $e, returning cached data");
        return CacheService.getCachedProducts();
      }
    } else {
      print("No internet connection, returning cached data");
      mode = "offline";
      return CacheService.getCachedProducts();
    }
  }

  static Future<List<DrinkCategory>> fetchCategories(String endpoint) async {
  bool result = await InternetConnection().hasInternetAccess;
    
    // Always try to get fresh data first if connected
    if (result) {
      mode = "online";
      try {
        final categories = await fetchGlobal<DrinkCategory>(
          getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
          fromJson: (json) => DrinkCategory.fromJson(json),
          endpoint: endpoint,
        ).timeout(Duration(seconds: REQUEST_TIMEOUT));

        // Cache the fetched data (non-blocking)
        _cacheCategoriesAsync(categories);
        print("Categories fetched and being cached");
        
        return categories;
      } on TimeoutException {
        print("Network timeout, returning cached categories");
        return CacheService.getCachedCategories();
      } catch (e) {
        print("fetchCategories error: $e, returning cached categories");
        return CacheService.getCachedCategories();
      }
    } else {
      print("No internet connection, returning cached categories");
      mode = "offline";
      return CacheService.getCachedCategories();
    }
  }

  // Async caching to avoid blocking UI
  static void _cacheProductsAsync(List<Product> products) {
    if (_isProductsSyncing) return;
    _isProductsSyncing = true;
    
    Future.microtask(() async {
      try {
        await CacheService.cacheProducts(products);
      } catch (e) {
        print("Error caching products: $e");
      } finally {
        _isProductsSyncing = false;
      }
    });
  }

  static void _cacheCategoriesAsync(List<DrinkCategory> categories) {
    if (_isCategoriesSyncing) return;
    _isCategoriesSyncing = true;
    
    Future.microtask(() async {
      try {
        await CacheService.cacheCategories(categories);
      } catch (e) {
        print("Error caching categories: $e");
      } finally {
        _isCategoriesSyncing = false;
      }
    });
  }







  // ============ M-PESA PAYMENT METHODS ============
  static Future<bool> SendSdkPush(Map<String, dynamic> data) async {
    try {
      // Validate input data
      if (!_validatePaymentData(data)) {
        _showErrorToast("Invalid payment details");
        return false;
      }

      debugPrint("Sending payment request to customer: ${data['mpesaNo']}");

      final resp = await comms
          .postRequest(endpoint: "orders/order/pay", data: data)
          .timeout(Duration(seconds: REQUEST_TIMEOUT));

      debugPrint("Payment request response: $resp");

      // Handle response safely and provide detailed feedback
      final success = resp["rsp"]?["success"] ?? false;
      final message = resp["rsp"]?["message"] ?? "Network error occurred";
      final errorCode = resp["rsp"]?["errorCode"];

      if (success) {
        // Show cashier-friendly success message
        _showSuccessToast("Payment request sent to customer");
        return true;
      } else {
        // Provide specific error messages based on response
        String errorMessage = _getSpecificErrorMessage(message, errorCode);
        _showErrorToast(errorMessage);
        return false;
      }
    } on TimeoutException {
      _showErrorToast("Network timeout - check connection and try again");
      return false;
    } catch (e) {
      debugPrint("SendSdkPush error: $e");
      _showErrorToast("Network error - unable to send payment request");
      return false;
    }
  }

  static Future<bool> confirmPayment(String orderNo) async {
    if (orderNo.isEmpty) {
      debugPrint("confirmPayment: Empty order number provided");
      return false;
    }

    try {
      final orderStatus = await comms
          .getRequests(endpoint: "orders/order/$orderNo")
          .timeout(
            Duration(seconds: PAYMENT_CHECK_TIMEOUT),
          ); // Shorter timeout for checks

      // Safely extract response data
      final success = orderStatus["rsp"]?["success"] ?? false;

      if (!success) {
        final message =
            orderStatus["rsp"]?["message"] ?? "Failed to check payment status";
        debugPrint("Payment status check failed: $message");
        return false;
      }

      final paymentStatus = orderStatus["rsp"]?["data"]?["paymentStatus"];

      if (paymentStatus == null) {
        debugPrint("Payment status not found in response");
        return false;
      }

      switch (paymentStatus) {
        case 1:
          debugPrint("✅ Payment confirmed for order: $orderNo");
          return true;
        case 0:
          // Payment still pending - don't log every check
          return false;
        case -1:
          debugPrint("❌ Payment failed for order: $orderNo");
          return false;
        default:
          debugPrint(
            "Unknown payment status: $paymentStatus for order: $orderNo",
          );
          return false;
      }
    } on TimeoutException {
      // Normal timeout during checking - don't show error
      debugPrint(
        "Payment check timeout for order: $orderNo (normal during checking)",
      );
      return false;
    } catch (e) {
      debugPrint("confirmPayment error for order $orderNo: $e");
      return false;
    }
  }

  // ============ ENHANCED PAYMENT METHODS FOR TERMINAL USE ============

  /// Quick payment confirmation for "Confirm Payment" button
  static Future<bool> quickConfirmPayment(String orderNo) async {
    try {
      _showInfoToast("Checking payment status...");

      final isConfirmed = await confirmPayment(orderNo);

      if (isConfirmed) {
        _showSuccessToast("Payment confirmed! Customer has paid.");
        return true;
      } else {
        _showInfoToast("No payment found yet. Customer may need more time.");
        return false;
      }
    } catch (e) {
      _showErrorToast("Unable to check payment status");
      return false;
    }
  }

  /// Enhanced retry mechanism for "Prompt Again" button
  static Future<bool> retryPaymentFlow({
    required String orderNo,
    required String phoneNumber,
    required String amount,
  }) async {
    try {
      // Step 1: First check if payment already exists (customer may have paid)
      _showInfoToast("Checking if customer already paid...");

      final alreadyPaid = await confirmPayment(orderNo);
      if (alreadyPaid) {
        _showSuccessToast("Customer already completed payment!");
        return true;
      }

      // Step 2: If no payment found, send new prompt
      _showInfoToast("Sending new payment request...");

      final promptSent = await SendSdkPush({
        "orderNo": orderNo,
        "mpesaNo": phoneNumber,
        "amount": amount,
      });

      if (!promptSent) {
        _showErrorToast("Failed to send new payment request");
        return false;
      }

      // Step 3: Brief check cycle (shorter than main flow)
      for (int i = 0; i < 10; i++) {
        await Future.delayed(Duration(seconds: 1));

        final confirmed = await confirmPayment(orderNo);
        if (confirmed) {
          _showSuccessToast("Payment completed!");
          return true;
        }
      }

      _showInfoToast(
        "Payment request sent. Continue checking manually if needed.",
      );
      return false;
    } catch (e) {
      _showErrorToast("Error during retry: ${e.toString()}");
      return false;
    }
  }

  // ============ HELPER METHODS ============
  static bool _validatePaymentData(Map<String, dynamic> data) {
    final orderNo = data["orderNo"];
    final mpesaNo = data["mpesaNo"];
    final amount = data["amount"];

    if (orderNo == null || orderNo.isEmpty) {
      debugPrint("Validation failed: Missing order number");
      return false;
    }

    if (mpesaNo == null || mpesaNo.isEmpty) {
      debugPrint("Validation failed: Missing customer phone number");
      return false;
    }

    if (amount == null || amount.isEmpty) {
      debugPrint("Validation failed: Missing payment amount");
      return false;
    }

    // Validate phone number format
    final phoneRegex = RegExp(r'^(07|01)\d{8}');
    if (!phoneRegex.hasMatch(mpesaNo)) {
      debugPrint("Validation failed: Invalid phone number format: $mpesaNo");
      return false;
    }

    // Validate amount is numeric and positive
    final numericAmount = double.tryParse(amount);
    if (numericAmount == null || numericAmount <= 0) {
      debugPrint("Validation failed: Invalid amount: $amount");
      return false;
    }

    return true;
  }

  /// Get specific error message for cashier based on API response
  static String _getSpecificErrorMessage(String message, dynamic errorCode) {
    // Convert message to lowercase for easier matching
    final lowerMessage = message.toLowerCase();

    // Check for common M-Pesa error patterns
    if (lowerMessage.contains('invalid phone') ||
        lowerMessage.contains('phone number')) {
      return 'Invalid phone number. Check customer phone and try again.';
    }

    if (lowerMessage.contains('insufficient') ||
        lowerMessage.contains('balance')) {
      return 'Customer has insufficient M-Pesa balance.';
    }

    if (lowerMessage.contains('timeout') || lowerMessage.contains('time out')) {
      return 'M-Pesa service timeout. Try again in a moment.';
    }

    if (lowerMessage.contains('duplicate') ||
        lowerMessage.contains('already processed')) {
      return 'Payment request already sent. Check payment status.';
    }

    if (lowerMessage.contains('network') ||
        lowerMessage.contains('connection')) {
      return 'Network error. Check internet connection.';
    }

    if (lowerMessage.contains('service unavailable') ||
        lowerMessage.contains('down')) {
      return 'M-Pesa service temporarily unavailable.';
    }

    if (lowerMessage.contains('invalid amount') ||
        lowerMessage.contains('amount')) {
      return 'Invalid payment amount. Check order total.';
    }

    // Error code specific messages
    if (errorCode != null) {
      switch (errorCode.toString()) {
        case '1001':
          return 'Invalid phone number format.';
        case '1002':
          return 'Customer account not found.';
        case '1003':
          return 'Transaction limit exceeded.';
        case '2001':
          return 'M-Pesa service temporarily down.';
        case '2002':
          return 'Payment processing failed. Try again.';
        default:
          break;
      }
    }

    // Default fallback message
    return 'Payment request failed: $message';
  }

  static String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }

  // ============ CASHIER-FRIENDLY TOAST MESSAGES ============
  static void _showSuccessToast(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastService.showSuccess(message);
    });
  }

  static void _showErrorToast(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastService.showError(message);
    });
  }

  static void _showInfoToast(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastService.showInfo(message);
    });
  }

  // ============ TERMINAL OPTIMIZED UTILITIES ============

  /// Quick validation for phone numbers with user-friendly messages
  static String? validateCustomerPhone(String phone) {
    if (phone.isEmpty) return 'Enter customer phone number';
    if (phone.length != 10) return 'Phone must be 10 digits';
    if (!phone.startsWith('07') && !phone.startsWith('01')) {
      return 'Phone must start with 07 or 01';
    }
    return null; // Valid
  }

  /// Quick validation for amounts
  static String? validateAmount(String amount) {
    final numericAmount = double.tryParse(amount);
    if (numericAmount == null) return 'Invalid amount';
    if (numericAmount <= 0) return 'Amount must be greater than 0';
    return null; // Valid
  }

  /// Format phone number for display in terminal
  static String formatPhoneForDisplay(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  /// Get payment status with terminal-friendly descriptions
  static String getPaymentStatusForCashier(int status) {
    switch (status) {
      case 0:
        return 'Customer needs to complete payment';
      case 1:
        return 'Payment received successfully';
      case -1:
        return 'Payment failed - try again';
      default:
        return 'Payment status unknown';
    }
  }

  /// Check network connectivity before operations
  static Future<bool> checkNetworkConnectivity() async {
    try {
      final response = await comms
          .getRequests(endpoint: "health-check")
          .timeout(Duration(seconds: 5));
      return response != null;
    } catch (e) {
      debugPrint("Network check failed: $e");
      _showErrorToast("Network connection issue - check internet");
      return false;
    }
  }

  /// Simplified payment flow for busy terminals
  static Future<Map<String, dynamic>> quickPaymentAttempt({
    required String orderNo,
    required String phoneNumber,
    required String amount,
  }) async {
    final result = {'success': false, 'message': '', 'requiresWaiting': false};

    try {
      // Quick connectivity check
      final hasNetwork = await checkNetworkConnectivity();
      if (!hasNetwork) {
        result['message'] = 'No network connection';
        return result;
      }

      // Send payment prompt
      final promptSent = await SendSdkPush({
        "orderNo": orderNo,
        "mpesaNo": phoneNumber,
        "amount": amount,
      });

      if (!promptSent) {
        result['message'] = 'Could not send payment request';
        return result;
      }

      result['success'] = true;
      result['requiresWaiting'] = true;
      result['message'] = 'Payment request sent to customer';
      return result;
    } catch (e) {
      result['message'] = 'Payment system error';
      return result;
    }
  }

  /// Get current system status for terminal display
  static Future<String> getSystemStatus() async {
    try {
      final response = await comms
          .getRequests(endpoint: "system/status")
          .timeout(Duration(seconds: 5));

      if (response['rsp']?['success'] == true) {
        return "System operational";
      } else {
        return "System issues detected";
      }
    } catch (e) {
      return "Unable to check system status";
    }
  }

  // ============ BATCH OPERATIONS FOR EFFICIENCY ============

  /// Pre-validate multiple orders (useful for batch processing)
  static List<String> validateMultipleOrders(
    List<Map<String, dynamic>> orders,
  ) {
    final errors = <String>[];

    for (int i = 0; i < orders.length; i++) {
      final order = orders[i];
      if (!_validatePaymentData(order)) {
        errors.add("Order ${i + 1}: Invalid payment data");
      }
    }

    return errors;
  }

  /// Clean up old payment timers and resources
  static void cleanupResources() {
    // This would be called when switching between customers
    // or at end of shift to clean up any hanging resources
    debugPrint("Cleaning up payment resources...");
    // Add any cleanup logic here
  }
}
