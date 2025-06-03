import 'dart:async';
import 'package:flutter/services.dart';

/// Main class for SmartPos Plugin
/// 
/// This class provides a Flutter interface to the ZCS SmartPos SDK
/// allowing Flutter apps to interact with POS hardware features.
class SmartposPlugin {
  // Private constructor to prevent instantiation
  SmartposPlugin._();
  
  // Method channel for communication with native Android code
  static const MethodChannel _channel = MethodChannel('smartpos_plugin');
  

  // ==================== BASIC DEVICE OPERATIONS ====================
  
  /// Get the platform version
  static Future<String?> get platformVersion async {
    try {
      final String? version = await _channel.invokeMethod('getPlatformVersion');
      return version;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to get platform version: ${e.message}');
    }
  }
  
  /// Initialize the SmartPos device
  /// 
  /// This must be called before any other operations
  /// Returns a map with initialization details
  static Future<Map<String, dynamic>> initializeDevice() async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('initializeDevice')
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Device initialization failed: ${e.message}');
    }
  }
  
  /// Open connection to the device
  /// 
  /// Device must be initialized first
  static Future<Map<String, dynamic>> openDevice() async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('openDevice')
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to open device: ${e.message}');
    }
  }
  
  /// Close connection to the device
  static Future<Map<String, dynamic>> closeDevice() async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('closeDevice')
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to close device: ${e.message}');
    }
  }
  
  /// Get detailed device information
  static Future<DeviceInfo> getDeviceInfo() async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('getDeviceInfo')
      );
      return DeviceInfo.fromMap(result);
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to get device info: ${e.message}');
    }
  }
  
  /// Get current device status
  static Future<DeviceStatus> getDeviceStatus() async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('getDeviceStatus')
      );
      return DeviceStatus.fromMap(result);
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to get device status: ${e.message}');
    }
  }
  
  // ==================== CARD READING OPERATIONS ====================
  
  /// Start card reading with specified options
  /// 
  /// [timeout] - Maximum time to wait for card (in seconds, default: 30)
  /// [magneticEnabled] - Enable magnetic stripe reading (default: true)
  /// [icEnabled] - Enable IC card reading (default: true)
  /// [contactlessEnabled] - Enable contactless reading (default: true)
  static Future<Map<String, dynamic>> startCardReading({
    int timeout = 30,
    bool magneticEnabled = true,
    bool icEnabled = true,
    bool contactlessEnabled = true,
  }) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('startCardReading', {
          'timeout': timeout,
          'magneticEnabled': magneticEnabled,
          'icEnabled': icEnabled,
          'contactlessEnabled': contactlessEnabled,
        })
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to start card reading: ${e.message}');
    }
  }
  
  /// Stop card reading operation
  static Future<Map<String, dynamic>> stopCardReading() async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('stopCardReading')
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to stop card reading: ${e.message}');
    }
  }
  
  /// Read magnetic stripe card
  static Future<CardData> readMagneticCard() async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('readMagneticCard')
      );
      return CardData.fromMap(result);
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to read magnetic card: ${e.message}');
    }
  }
  
  /// Read IC card (chip card)
  static Future<CardData> readICCard() async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('readICCard')
      );
      return CardData.fromMap(result);
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to read IC card: ${e.message}');
    }
  }
  
  /// Read contactless card (NFC/RFID)
  static Future<CardData> readContactlessCard() async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('readContactlessCard')
      );
      return CardData.fromMap(result);
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to read contactless card: ${e.message}');
    }
  }
  
  // ==================== EMV OPERATIONS ====================
  
  /// Start EMV transaction
  /// 
  /// [amount] - Transaction amount (required)
  /// [currency] - Currency code (default: "USD")
  /// [transactionType] - Type of transaction (default: "SALE")
  static Future<Map<String, dynamic>> startEmvTransaction({
    required double amount,
    String currency = "USD",
    String transactionType = "SALE",
  }) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('startEmvTransaction', {
          'amount': amount,
          'currency': currency,
          'transactionType': transactionType,
        })
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to start EMV transaction: ${e.message}');
    }
  }
  
  /// Process EMV transaction (handles application selection, authentication, etc.)
  static Future<Map<String, dynamic>> processEmvTransaction(
    Map<String, dynamic> transactionData
  ) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('processEmvTransaction', transactionData)
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to process EMV transaction: ${e.message}');
    }
  }
  
  /// Complete EMV transaction
  static Future<Map<String, dynamic>> completeEmvTransaction(
    Map<String, dynamic> transactionData
  ) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('completeEmvTransaction', transactionData)
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to complete EMV transaction: ${e.message}');
    }
  }
  
  // ==================== PRINTING OPERATIONS ====================
  
  /// Print simple text
  /// 
  /// [text] - Text to print (required)
  /// [fontSize] - Font size (default: 24)
  /// [isBold] - Make text bold (default: false)
  /// [isUnderline] - Underline text (default: false)
  /// [alignment] - Text alignment: "LEFT", "CENTER", "RIGHT" (default: "LEFT")
  /// 
  static Future<Map<String, dynamic>> printText(
    String text, {
    int fontSize = 50,
    bool isBold = false,
    bool isUnderline = false,
    String alignment = "LEFT",
  }) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('printText', {
          'text': text,
          'fontSize': fontSize,
          'isBold': isBold,
          'isUnderline': isUnderline,
          'alignment': alignment,
        })
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to print text: ${e.message}');
    }
  }
  
  /// Print a formatted receipt
  /// 
  /// [receiptData] - Receipt data containing header, items, totals, etc.
  static Future<Map<String, dynamic>> printReceipt(
    Map<String, dynamic> receiptData
  ) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('printReceipt', {
          'receiptData': receiptData,
        })
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to print receipt: ${e.message}');
    }
  }
  
  static Future<Map<String, dynamic>> printQrCode(
    String data, {
    int size = 200,
    String errorCorrectionLevel = "L", // "L", "M", "Q", "H"
  }) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('printQRCode', {
          'data': data,
          'size': size,
          'errorCorrectionLevel': errorCorrectionLevel,
        })
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to print QR code: ${e.message}');
    }
  }


  /// Print an image (logo, signature, etc.)
  /// 
  /// [imageData] - Image data (base64 encoded or file path)
  static Future<Map<String, dynamic>> printImage(
    String imageData
  ) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('printImage', {
          'imageData': imageData,
        })
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to print image: ${e.message}');
    }
  }

  
  /// Get printer status
  static Future<PrinterStatus> getPrinterStatus() async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('getPrinterStatus')
      );
      return PrinterStatus.fromMap(result);
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to get printer status: ${e.message}');
    }
  }
  // ===================SCANN QRCODE ====================
  /// Scan a QR code
 

  static Future<String> scanQRCode({int timeoutSeconds = 10}) async {
    try {
      // Start a timer to stop scanning after 5 seconds
      Timer(Duration(seconds: 3), () {
        stopQRScan(); // Call method to power off scanner
      });

      // Call the native method with timeout
      Map<String, dynamic> response = await _channel
          .invokeMethod('scanQRCode')
          .timeout(Duration(seconds: timeoutSeconds));

      bool success = response['success'] ?? false;
      String message = response['message'] ?? 'Scan completed';
      String data = response['data'] ?? '';

      if (success && data.isNotEmpty) {
        return data; // Return the scanned QR code data
      } else if (success && data.isEmpty) {
        throw SmartPosException('No QR code detected: $message');
      } else {
        throw SmartPosException('QR code scan failed: $message');
      }
    } on TimeoutException {
      await stopQRScan(); // Ensure scanner is stopped on timeout
      throw SmartPosException('QR code scan timeout');
    } on PlatformException catch (e) {
      await stopQRScan(); // Ensure scanner is stopped on error
      throw SmartPosException('Failed to scan QR code: ${e.message}');
    }
  }

  // Method to get the last scanned data
  static Future<String> getLastScannedData() async {
    try {
      Map<String, dynamic> response = await _channel.invokeMethod('getLastScannedData');
      return response['data'] ?? '';
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to get last scanned data: ${e.message}');
    }
  }

  // Method to start continuous scanning (power on scanner)
  static Future<bool> startQRScan() async {
    try {
      Map<String, dynamic> response = await _channel.invokeMethod('startQRScan');
      return response['success'] ?? false;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to start QR scanner: ${e.message}');
    }
  }

  // Method to stop scanning (power off scanner)
  static Future<bool> stopQRScan() async {
    try {
      Map<String, dynamic> response = await _channel.invokeMethod('stopQRScan');
      return response['success'] ?? false;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to stop QR scanner: ${e.message}');
    }
  }



  
  // ==================== PIN PAD OPERATIONS ====================
  
  /// Get encrypted PIN block
  /// 
  /// [pan] - Primary Account Number (required)
  /// [pinLength] - Expected PIN length (default: 4)
  static Future<PinBlockResult> getPinBlock(
    String pan, {
    int pinLength = 4,
  }) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('getPinBlock', {
          'pan': pan,
          'pinLength': pinLength,
        })
      );
      return PinBlockResult.fromMap(result);
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to get PIN block: ${e.message}');
    }
  }
  
  /// Start PIN input process
  /// 
  /// [timeout] - Maximum time to wait for PIN input (default: 30 seconds)
  /// [minLength] - Minimum PIN length (default: 4)
  /// [maxLength] - Maximum PIN length (default: 12)
  static Future<Map<String, dynamic>> inputPin({
    int timeout = 30,
    int minLength = 4,
    int maxLength = 12,
  }) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('inputPin', {
          'timeout': timeout,
          'minLength': minLength,
          'maxLength': maxLength,
        })
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to input PIN: ${e.message}');
    }
  }
  
  // ==================== UTILITY OPERATIONS ====================
  
  /// Play a beep sound
  static Future<String> playBeep() async {
    try {
      final String result = await _channel.invokeMethod('playBeep');
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to play beep: ${e.message}');
    }
  }
  
  /// Control LED status
  /// 
  /// [color] - LED color: "RED", "GREEN", "BLUE", "YELLOW"
  /// [isOn] - Turn LED on/off
  static Future<Map<String, dynamic>> setLedStatus(
    String color,
    bool isOn,
  ) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('setLedStatus', {
          'color': color,
          'isOn': isOn,
        })
      );
      return result;
    } on PlatformException catch (e) {
      throw SmartPosException('Failed to set LED status: ${e.message}');
    }
  }





}

// ==================== DATA CLASSES ====================

/// Device information data class
class DeviceInfo {
  final String model;
  final String serialNumber;
  final String firmwareVersion;
  final String sdkVersion;
  final int batteryLevel;
  final bool isCharging;
  final double temperature;
  
  DeviceInfo({
    required this.model,
    required this.serialNumber,
    required this.firmwareVersion,
    required this.sdkVersion,
    required this.batteryLevel,
    required this.isCharging,
    required this.temperature,
  });
  
  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      model: map['model'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      firmwareVersion: map['firmwareVersion'] ?? '',
      sdkVersion: map['sdkVersion'] ?? '',
      batteryLevel: map['batteryLevel'] ?? 0,
      isCharging: map['isCharging'] ?? false,
      temperature: (map['temperature'] ?? 0.0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'serialNumber': serialNumber,
      'firmwareVersion': firmwareVersion,
      'sdkVersion': sdkVersion,
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'temperature': temperature,
    };
  }
  
  @override
  String toString() {
    return 'DeviceInfo{model: $model, serialNumber: $serialNumber, firmwareVersion: $firmwareVersion, batteryLevel: $batteryLevel%}';
  }
}

/// Device status data class
class DeviceStatus {
  final bool initialized;
  final bool opened;
  final bool ready;
  
  DeviceStatus({
    required this.initialized,
    required this.opened,
    required this.ready,
  });
  
  factory DeviceStatus.fromMap(Map<String, dynamic> map) {
    return DeviceStatus(
      initialized: map['initialized'] ?? false,
      opened: map['opened'] ?? false,
      ready: map['ready'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'initialized': initialized,
      'opened': opened,
      'ready': ready,
    };
  }
  
  @override
  String toString() {
    return 'DeviceStatus{initialized: $initialized, opened: $opened, ready: $ready}';
  }
}

/// Card data class for all card types
class CardData {
  final String cardType; // "MAGNETIC", "IC", "CONTACTLESS"
  final String? track1;
  final String? track2;
  final String? track3;
  final String? atr; // Answer to Reset (for IC cards)
  final String? uid; // Unique ID (for contactless cards)
  final String? maskedPan;
  final String? expiryDate;
  final String? cardholderName;
  final String? applicationLabel;
  
  CardData({
    required this.cardType,
    this.track1,
    this.track2,
    this.track3,
    this.atr,
    this.uid,
    this.maskedPan,
    this.expiryDate,
    this.cardholderName,
    this.applicationLabel,
  });
  
  factory CardData.fromMap(Map<String, dynamic> map) {
    return CardData(
      cardType: map['cardType'] ?? '',
      track1: map['track1'],
      track2: map['track2'],
      track3: map['track3'],
      atr: map['atr'],
      uid: map['uid'],
      maskedPan: map['maskedPan'],
      expiryDate: map['expiryDate'],
      cardholderName: map['cardholderName'],
      applicationLabel: map['applicationLabel'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'cardType': cardType,
      'track1': track1,
      'track2': track2,
      'track3': track3,
      'atr': atr,
      'uid': uid,
      'maskedPan': maskedPan,
      'expiryDate': expiryDate,
      'cardholderName': cardholderName,
      'applicationLabel': applicationLabel,
    };
  }
  
  @override
  String toString() {
    return 'CardData{cardType: $cardType, maskedPan: $maskedPan, cardholderName: $cardholderName}';
  }
}

/// Printer status data class
class PrinterStatus {
  final bool isReady;
  final String paperStatus; // "OK", "LOW", "OUT"
  final String temperature; // "NORMAL", "HIGH"
  final String? lastError;
  
  PrinterStatus({
    required this.isReady,
    required this.paperStatus,
    required this.temperature,
    this.lastError,
  });
  
  factory PrinterStatus.fromMap(Map<String, dynamic> map) {
    return PrinterStatus(
      isReady: map['isReady'] ?? false,
      paperStatus: map['paperStatus'] ?? 'UNKNOWN',
      temperature: map['temperature'] ?? 'UNKNOWN',
      lastError: map['lastError'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'isReady': isReady,
      'paperStatus': paperStatus,
      'temperature': temperature,
      'lastError': lastError,
    };
  }
  
  @override
  String toString() {
    return 'PrinterStatus{isReady: $isReady, paperStatus: $paperStatus, temperature: $temperature}';
  }
}

/// PIN block result data class
class PinBlockResult {
  final bool success;
  final String pinBlock;
  final String ksn; // Key Serial Number
  
  PinBlockResult({
    required this.success,
    required this.pinBlock,
    required this.ksn,
  });
  
  factory PinBlockResult.fromMap(Map<String, dynamic> map) {
    return PinBlockResult(
      success: map['success'] ?? false,
      pinBlock: map['pinBlock'] ?? '',
      ksn: map['ksn'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'pinBlock': pinBlock,
      'ksn': ksn,
    };
  }
  
  @override
  String toString() {
    return 'PinBlockResult{success: $success, ksn: $ksn}';
  }
}

/// Custom exception class for SmartPos operations
class SmartPosException implements Exception {
  final String message;
  
  SmartPosException(this.message);
  
  @override
  String toString() {
    return 'SmartPosException: $message';
  }
}