// File: lib/streams_example.dart
import 'dart:async';

import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/core/utils/sdkinitializer.dart';
import 'package:blankets_and_wines_example/features/cashier/Auth/Login.dart';
import 'package:blankets_and_wines_example/onBoarding/OnBoarding.dart';
import 'package:blankets_and_wines_example/playground/BluetoothComms.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'database/database.dart';
import 'database/dao/categories_dao.dart';
import 'database/dao/products_dao.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<void> getDeviceSerialNumber() async {
  final deviceInfoPlugin = DeviceInfoPlugin();
  final androidInfo = await deviceInfoPlugin.androidInfo;

  // This is the unique Android ID (works reliably)
  String androidId = androidInfo.id; 

  // This is the serial number (may return "unknown" on Android 10+)
  String serialNumber = androidInfo.serialNumber;

  print("Android ID: $androidId");
  print("Serial Number: $serialNumber");
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await getDeviceSerialNumber();
  
  sdkInitializer();
  await preferences.init();


  runApp(
    //  App() 
     MyApp()
    );
}

Future<bool> isLoggedin() async {
  try {
    bool result = await preferences.isUserLoggedIn();
    if (result) {
      userData = (await preferences.getUserData())!;
      print(
        "##############################${userData.userRole}######################################",
      );
    }

    return result;
  } on Exception catch (e) {
    ToastService.showError(e.toString());
    throw Exception(e);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // comms.setAuthToken(
    //   "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Miwic2hvcCI6MSwicm9sZSI6MiwiaWF0IjoxNzQ5ODE1OTM3LCJleHAiOjE3NDk5MDIzMzd9.aYlEme5HJd5bZuReQGM3hSUyE4CAjc_Z5WXLNsKZZ_Q",
    // );
    return MaterialApp(
      home:
      // StreamsExample(),
      
       FutureBuilder<bool>(
        future: isLoggedin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.data == true) {
            // Check user type from userData instance
            switch (userData.userRole) {
              case 'cashier':
                return LoginPage();
              // Add other user type cases here
              default:
                return LoginPage(); // Default fallback
            }
          }

          return OnboardingPage(wasFromLogin: false,);
        },
      ),
      navigatorKey: ToastService.navigatorKey,
      // StockistMainScreen()
      // QRCodeScannerScreen(),

      // QRCodeScannerScreen()
    );
  }
}
