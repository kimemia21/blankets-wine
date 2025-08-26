import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/data/models/DrinkOrder.dart';
import 'package:blankets_and_wines_example/data/models/DrinkItem.dart';
import 'package:blankets_and_wines_example/data/models/OtpResponse.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

class BartenderService {
  static const String baseUrl = 'YOUR_API_BASE_URL';

  // Mock data for testing new DrinkOrder structure
  static Map<String, DrinkOrder> _mockOrders = {
    'ORD001': DrinkOrder(
      orderNo: 'ORD001',
      paymentStatus: 0,
      orderDate: DateTime.now().subtract(Duration(minutes: 15)),
      orderTotal: 2500.0,
      customerFirstName: 'Sarah',
      customerLastName: 'Johnson',
      customerEmail: 'sarah.johnson@example.com',
      customerPhone: '+254712345678',
      orderItems: [
        DrinkItem(productName: 'Whiskey Sour', quantity: 2, price: 850.0),
        DrinkItem(productName: 'Tusker', quantity: 4, price: 200.0),
      ],
    ),
    'ORD002': DrinkOrder(
      orderNo: 'ORD002',
      paymentStatus: 0,
      orderDate: DateTime.now().subtract(Duration(minutes: 30)),
      orderTotal: 3300.0,
      customerFirstName: 'Michael',
      customerLastName: 'Ochieng',
      customerEmail: 'michael.ochieng@example.com',
      customerPhone: '+254798765432',
      orderItems: [
        DrinkItem(productName: 'Red Wine', quantity: 1, price: 1800.0),
        DrinkItem(productName: 'Mojito', quantity: 2, price: 750.0),
      ],
    ),
    'ORD003': DrinkOrder(
      orderNo: 'ORD003',
      paymentStatus: 1,
      orderDate: DateTime.now().subtract(Duration(hours: 1)),
      orderTotal: 950.0,
      customerFirstName: 'Grace',
      customerLastName: 'Wanjiku',
      customerEmail: 'grace.wanjiku@example.com',
      customerPhone: '+254723456789',
      orderItems: [
        DrinkItem(productName: 'Vodka Tonic', quantity: 1, price: 650.0),
        DrinkItem(productName: 'Coca Cola', quantity: 3, price: 100.0),
      ],
    ),
  };

  static String? _lastSentOtpOrderId;
  static const String _correctOtp = '1234';

  static Future<DrinkOrder?> searchOrder(String orderId) async {
    final order = await comms.postRequest(
      endpoint: "orders/search",
      data: {"orderNo": orderId},
    );

    try {
      if (order["rsp"]["success"]) {
        return DrinkOrder.fromJson(order["rsp"]["data"]);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error searching order: $e');
    }
  }

  static Future<OtpResponse?> sendOtp({
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(Duration(seconds: 1));

    try {
      final otp = await comms.postRequest(endpoint: "orders/otp", data: data);

      // The API now responds with {status, message, data}
      if (otp["rsp"]["success"] == true) {
        return OtpResponse.fromJson({...otp["rsp"], "status": true});
      } else {
        return OtpResponse(
          status: false,
          message: otp["rsp"]["message"] ?? "Failed to send OTP",
          orderNo: '',
        );
      }
    } catch (e) {
      return OtpResponse(
        status: false,
        message: 'Error sending OTP: $e',
        orderNo: '',
      );
    }
  }

// Separate method for socket emission
static Future<void> _emitOrderCreated(int barId) async {
  print('Preparing to emit order_created for barId: $barId');
  try {
    Socket socket = IO.io(
      'ws://10.68.102.36:8002',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setTimeout(5000)
          .build(),
    );

    Completer<void> completer = Completer<void>();
    
    socket.onConnect((_) {
      print('Connected - emitting order_created');
      socket.emit('order_created', {"barId": barId});
      
      // Wait then cleanup
      Timer(Duration(seconds: 2), () {
        socket.dispose();
        if (!completer.isCompleted) completer.complete();
      });
    });

    socket.onError((error) {
      print('Socket error: $error');
      socket.dispose();
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future.timeout(Duration(seconds: 8));
  } catch (e) {
    print('Emission failed: $e');
  }
}

// Main method - simplified
static Future<Map<String, dynamic>> verifyOtpAndMarkReceived({
  required Map<String, dynamic> data,
}) async {
  await Future.delayed(Duration(seconds: 1));

  try {
    final verify = await comms.postRequest(
      endpoint: "orders/otp-verify",
      data: data,
    );

    if (verify["rsp"]["success"]) {
      // Emit in background - don't wait for it
      _emitOrderCreated(appUser.barId);
      
      return {
        "status": true,
        "message": verify["rsp"]["message"] ?? "OTP verified and order marked as received",
      };
    } else {
      return {
        "status": false,
        "message": verify["rsp"]["message"] ?? "Failed to verify OTP",
      };
    }
  } catch (e) {
    throw Exception('Error verifying OTP: $e');
  }
}  static Future<bool> markAsCollected(String orderId) async {
    await Future.delayed(Duration(seconds: 1));

    try {
      // Mock implementation
      if (_mockOrders.containsKey(orderId.toUpperCase())) {
        final order = _mockOrders[orderId.toUpperCase()]!;
        if (order.orderNo == 'received') {
          // _mockOrders[orderId.toUpperCase()] = order.copyWith(status: 'completed');
          return true;
        }
      }
      return false;

      /* Real API implementation
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/collected'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN',
        },
        body: json.encode({'status': 'completed'}),
      );

      return response.statusCode == 200;
      */
    } catch (e) {
      throw Exception('Error marking order as collected: $e');
    }
  }
}
