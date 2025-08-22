import 'dart:async';

import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/data/models/Category.dart';
import 'package:blankets_and_wines_example/data/models/DrinkItem.dart';
import 'package:blankets_and_wines_example/data/models/Product.dart';
import 'package:blankets_and_wines_example/data/models/ProductCategory.dart';
import 'package:blankets_and_wines_example/data/services/FetchGlobals.dart';
import 'package:flutter/widgets.dart';

class CashierFunctions {
  static const int REQUEST_TIMEOUT = 30; // seconds
  
  static final List<String> categories = [
    'All', 'Whiskey', 'Premium Whiskey', 'Vodka', 'Premium Vodka', 
    'Brandy', 'Premium Brandy', 'Champagne', 'Premium Champagne',
    'Wine', 'Tequila', 'Premium Tequila', 'Rum', 'Local Premium', 'Liqueur',
  ];

  // ============ DATA FETCHING METHODS ============
  static Future<List<Product>> fetchDrinks(String endpoint) async {
    try {
      final drinks = await fetchGlobal<Product>(
        getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
        fromJson: (json) => Product.fromJson(json),
        endpoint: endpoint,
      ).timeout(Duration(seconds: REQUEST_TIMEOUT));
      
      return drinks;
    } on TimeoutException {
      throw Exception("Request timeout while fetching drinks");
    } catch (e) {
      debugPrint("fetchDrinks error: $e");
      throw Exception("Failed to fetch drinks: ${e.toString()}");
    }
  }

  static Future<List<DrinnksCategory>> fetchCategories(String endpoint) async {
    try {
      final categories = await fetchGlobal<DrinnksCategory>(
        getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
        fromJson: (json) => DrinnksCategory.fromJson(json),
        endpoint: endpoint,
      ).timeout(Duration(seconds: REQUEST_TIMEOUT));
      
      return categories;
    } on TimeoutException {
      throw Exception("Request timeout while fetching categories");
    } catch (e) {
      debugPrint("fetchCategories error: $e");
      throw Exception("Failed to fetch categories: ${e.toString()}");
    }
  }

  // ============ M-PESA PAYMENT METHODS ============
  static Future<bool> SendSdkPush(Map<String, dynamic> data) async {
    try {
      // Validate input data
      if (!_validatePaymentData(data)) {
        _showErrorToast("Invalid payment data provided");
        return false;
      }

      debugPrint("Initiating M-Pesa payment: ${data['orderNo']}");

      final resp = await comms.postRequest(
        endpoint: "orders/order/pay",
        data: data,
      ).timeout(Duration(seconds: REQUEST_TIMEOUT));

      debugPrint("Payment response: $resp");

      // Handle response safely
      final success = resp["rsp"]?["success"] ?? false;
      final message = resp["rsp"]?["message"] ?? "Unknown error occurred";

      if (success) {
        // Show a calm success message
        _showSuccessToast("M-Pesa prompt sent to your phone");
        return true;
      } else {
        _showErrorToast("Failed to send payment prompt: $message");
        return false;
      }

    } on TimeoutException {
      _showErrorToast("Request timed out. Please check your connection.");
      return false;
    } catch (e) {
      debugPrint("SendSdkPush error: $e");
      _showErrorToast("Could not send payment prompt. Please try again.");
      return false;
    }
  }

  static Future<bool> confirmPayment(String orderNo) async {
    if (orderNo.isEmpty) {
      debugPrint("confirmPayment: Empty order number provided");
      return false;
    }

    try {
      final orderStatus = await comms.getRequests(
        endpoint: "orders/order/$orderNo",
      ).timeout(Duration(seconds: 15)); // Shorter timeout for checking

      // Safely extract response data
      final success = orderStatus["rsp"]?["success"] ?? false;
      
      if (!success) {
        final message = orderStatus["rsp"]?["message"] ?? "Failed to check payment status";
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
          // Don't log every pending check to reduce noise
          return false;
        default:
          debugPrint("Unknown payment status: $paymentStatus");
          return false;
      }

    } on TimeoutException {
      // Don't show error for timeout during checking - it's normal
      debugPrint("Payment check timeout for order: $orderNo (this is normal)");
      return false;
    } catch (e) {
      debugPrint("confirmPayment error for order $orderNo: $e");
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
      debugPrint("Validation failed: Missing M-Pesa number");
      return false;
    }

    if (amount == null || amount.isEmpty) {
      debugPrint("Validation failed: Missing amount");
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

  static String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }

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

  // ============ PAYMENT FLOW UTILITIES ============
  
  /// Performs a complete payment flow with automatic retries
  static Future<bool> processAutoPayment({
    required String orderNo,
    required String phoneNumber,
    required String amount,
    int maxRetries = 2,
  }) async {
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint("Payment attempt $attempt for order: $orderNo");
        
        // Step 1: Send payment prompt
        final pushSuccess = await SendSdkPush({
          "orderNo": orderNo,
          "mpesaNo": phoneNumber,
          "amount": amount,
        });

        if (!pushSuccess) {
          if (attempt == maxRetries) {
            _showErrorToast("Failed to send payment prompt after $maxRetries attempts");
            return false;
          }
          continue;
        }

        // Step 2: Wait briefly before checking
        await Future.delayed(Duration(seconds: 2));

        // Step 3: Start checking payment status
        const int maxChecks = 10; // 10 seconds
        for (int check = 1; check <= maxChecks; check++) {
          final confirmed = await confirmPayment(orderNo);
          
          if (confirmed) {
            _showSuccessToast("Payment completed successfully!");
            return true;
          }

          if (check < maxChecks) {
            await Future.delayed(Duration(seconds: 1));
          }
        }

        // If we reach here, payment timed out for this attempt
        if (attempt < maxRetries) {
          _showInfoToast("Payment timeout, retrying...");
          await Future.delayed(Duration(seconds: 2));
        }

      } catch (e) {
        debugPrint("Payment attempt $attempt failed: $e");
        if (attempt == maxRetries) {
          _showErrorToast("Payment failed after $maxRetries attempts");
          return false;
        }
      }
    }

    _showErrorToast("Payment failed after all attempts");
    return false;
  }

  /// Quick validation for phone numbers
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^(07|01)\d{8}');
    return phoneRegex.hasMatch(phone);
  }

  /// Quick validation for amounts
  static bool isValidAmount(String amount) {
    final numericAmount = double.tryParse(amount);
    return numericAmount != null && numericAmount > 0;
  }

  /// Format phone number for display
  static String formatPhoneNumber(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }

  /// Get payment status description
  static String getPaymentStatusDescription(int status) {
    switch (status) {
      case 0:
        return 'Payment Pending';
      case 1:
        return 'Payment Completed';
      case -1:
        return 'Payment Failed';
      default:
        return 'Unknown Status';
    }
  }
}