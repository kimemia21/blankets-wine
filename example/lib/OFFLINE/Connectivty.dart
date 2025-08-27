// // 1. Connectivity Service
// import 'dart:async';
// import 'dart:io';
// import 'package:blankets_and_wines_example/core/utils/initializers.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:http/http.dart' as http;

// class ConnectivityService {
//   static final ConnectivityService _instance = ConnectivityService._internal();
//   factory ConnectivityService() => _instance;
//   ConnectivityService._internal();

//   final Connectivity _connectivity = Connectivity();
//   StreamController<bool> _connectionController =
//       StreamController<bool>.broadcast();
//   bool _isConnected = false;

//   Stream<bool> get connectionStream => _connectionController.stream;
//   bool get isConnected => _isConnected;

//   Future<void> initialize() async {
//     _isConnected = await _checkConnection();
//     _connectionController.add(_isConnected);

//     _connectivity.onConnectivityChanged.listen((result) async {
//       _isConnected = await _checkConnection();
//       _connectionController.add(_isConnected);
//     });
//   }

// Future<bool> _checkConnection() async {
//   try {
//     // Add timestamp to prevent caching using queryParameters
//     final response = await comms.getRequests(
//       endpoint: "users/roles",  // Remove the baseUrl prefix since it's added in getRequests
//       queryParameters: {
//         '_t': DateTime.now().millisecondsSinceEpoch.toString(),
//         '_nocache': DateTime.now().microsecondsSinceEpoch.toString(),
//       },
//     );
    
//     if (response["rsp"]["success"] == true) {  // Check the success field directly
//       return true;                
//     } else {
//       return false;
//     }            
//   } catch (e) {
//     print('Connectivity check error: $e');
//     return false;
//   }
// }

//   void dispose() {
//     _connectionController.close();
//   }
// }
