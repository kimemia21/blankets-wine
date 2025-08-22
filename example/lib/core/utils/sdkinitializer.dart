import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:flutter/foundation.dart';

Future<Map<String, dynamic>> sdkInitializer() async {
  void log(String message) {
    debugPrint('[SmartPOS] $message');
  }

  try {
    log('App starting...');

    final initResult = await SmartposPlugin.initializeDevice();
    log('Device initialization result: ${initResult['message']}');

    final openResult = await SmartposPlugin.openDevice();
    log('Device open result: ${openResult['message']}');

    deviceInfo = await SmartposPlugin.getDeviceInfo();
    log('Device Info: ${deviceInfo.toString()}');

    return {
      "success": true,
      "msg": "Initialization successful",
    };
  } catch (e, stacktrace) {
    log('Initialization error: $e');
    log('Stacktrace: $stacktrace');

    return {
      "success": false,
      "msg": "Initialization failed: $e",
    };
  }
}
