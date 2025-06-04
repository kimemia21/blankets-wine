



import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/features/Stockist/Stockist.dart';
import 'package:blankets_and_wines_example/features/Test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: set up custom logger or use print
  void log(String message) {
    // Could also use logger package or FirebaseCrashlytics here
    debugPrint('[SmartPOS] $message');
  }

  try {
    log('App starting...');
    final initResult = await SmartposPlugin.initializeDevice();
    log('Device initialization result: ${initResult['message']}');

    // final platformVersion = await SmartposPlugin.platformVersion ?? 'Unknown platform version';
    // log('Platform version: $platformVersion');

    final openResult = await SmartposPlugin.openDevice();
    log('Device open result: ${openResult['message']}');

    final info = await SmartposPlugin.getDeviceInfo();
    log('Device Info: $info');

    // Optional: close device at the end of init for testing
    // final closeResult = await SmartposPlugin.closeDevice();
    // log('Device closed: ${closeResult['message']}');
  } catch (e, stacktrace) {
    log('Initialization error: $e');
    log('Stacktrace: $stacktrace');
  }
  runApp(
   MyApp()
  // QRScannerPage()
//  StockistMainScreen()
    );
// runApp(BarPOSApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: StockistMainScreen());
  }
}

