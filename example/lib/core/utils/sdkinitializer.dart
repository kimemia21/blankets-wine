import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:flutter/foundation.dart';

void sdkInitializer()async{
  
  void log(String message) {
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

  } catch (e, stacktrace) {
    log('Initialization error: $e');
    log('Stacktrace: $stacktrace');
  }
}