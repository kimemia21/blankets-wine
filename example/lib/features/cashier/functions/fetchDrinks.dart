import 'dart:async';

import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/data/models/Category.dart';
import 'package:blankets_and_wines_example/data/models/DrinkItem.dart';
import 'package:blankets_and_wines_example/data/models/ProductCategory.dart';
import 'package:blankets_and_wines_example/data/services/FetchGlobals.dart';
import 'package:flutter/widgets.dart';

class CashierFunctions {
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

  static Future<List<ProductCategory>> fetchDrinks(String endpoint) async {
  
    try {
      final drinks = await fetchGlobal<ProductCategory>(
        getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
        fromJson: (json) => ProductCategory.fromJson(json),
        endpoint: endpoint,
      );
      print(drinks);
      return drinks;
    } on Exception catch (e) {
      throw Exception("fetch Drinks error $e");
    }
  }

  static Future<List<DrinnksCategory>> fetchCategories(String endpoint) async {
    try {
      final categories = await fetchGlobal<DrinnksCategory>(
        getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
        fromJson: (json) => DrinnksCategory.fromJson(json),
        endpoint: endpoint,
      );
      print(categories);
      return categories;
    } on Exception catch (e) {
      throw Exception("fetch Categories error $e");
    }
  }

  static Future<bool> SendSdkPush(Map<String, dynamic> data) async {
    try {
      // Step 1: Initialize payment
      final resp = await comms.postRequest(
        endpoint: "orders/order/pay",
        data: data,
      );

      print("Payment initialization response: $resp");

      if (!resp["rsp"]["success"]) {
        // Use WidgetsBinding to ensure UI is ready before showing toast
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ToastService.showError(
            resp["rsp"]["message"] ?? "Payment initialization failed",
          );
        });
        return false;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ToastService.showSuccess(resp["rsp"]["message"]);
         
        });
         return true;
      }
    } catch (e) {
      print("Error in payAndCheckOrder: $e");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ToastService.showError("Payment failed. Please try again.");
        debugPrint("$e");
      });
      return false;
    }
  }






  static Future<bool> confirmPayment(String orderNo) async {
    try {
      print("Checking payment status");

      final orderStatus = await comms.getRequests(
        endpoint: "orders/order/$orderNo",
      );

      // Check if request was successful
      if (orderStatus["rsp"]["success"]) {
        final paymentStatus = orderStatus["rsp"]["data"]["paymentStatus"];

        if (paymentStatus == 1) {
          // Payment successful
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ToastService.showSuccess("Payment completed successfully!");
          });
          return true;
        } else if (paymentStatus == 0) {
          // Payment failed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ToastService.showError("Payment failed. Please try again.");
          });
          return false;
        }
      } else {
        print("Status check failed: ${orderStatus["rsp"]["message"]}");
      }

      return false;
    } catch (e) {
      print("Error checking payment status: $e");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ToastService.showError("Error checking payment status");
      });
      return false;
    }
  }
}
