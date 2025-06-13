
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum ItemStatus { preparing, ready }

class ScannedItem {
  final String code;
  ItemStatus status;
  final DateTime firstScannedAt;
  DateTime lastScannedAt;

  ScannedItem({
    required this.code,
    this.status = ItemStatus.preparing,
    DateTime? firstScannedAt,
    DateTime? lastScannedAt,
  }) : firstScannedAt = firstScannedAt ?? DateTime.now(),
       lastScannedAt = lastScannedAt ?? DateTime.now();

  ScannedItem copyWith({
    String? code,
    ItemStatus? status,
    DateTime? firstScannedAt,
    DateTime? lastScannedAt,
  }) {
    return ScannedItem(
      code: code ?? this.code,
      status: status ?? this.status,
      firstScannedAt: firstScannedAt ?? this.firstScannedAt,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
    );
  }
}

class QRCodeVerificationService with WidgetsBindingObserver {
  static final QRCodeVerificationService _instance = QRCodeVerificationService._internal();
  factory QRCodeVerificationService() => _instance;
  QRCodeVerificationService._internal();

  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  StreamSubscription<Object?>? _subscription;
  final Map<String, ScannedItem> _scannedItems = {};
  
  // Callbacks
  Function(String message)? _onSuccessCallback;
  Function(String error)? _onErrorCallback;
  Function(ScannedItem item)? _onItemScannedCallback;
  Function(ScannedItem item)? _onStatusChangedCallback;

  // Getters
  MobileScannerController get controller => _controller;
  Map<String, ScannedItem> get scannedItems => Map.unmodifiable(_scannedItems);
  bool get isScanning => _controller.value.isRunning;

  /// Initialize the service
  Future<void> initialize({
    Function(String message)? onSuccess,
    Function(String error)? onError,
    Function(ScannedItem item)? onItemScanned,
    Function(ScannedItem item)? onStatusChanged,
  }) async {
    _onSuccessCallback = onSuccess;
    _onErrorCallback = onError;
    _onItemScannedCallback = onItemScanned;
    _onStatusChangedCallback = onStatusChanged;

    // Start listening to lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Start listening to barcode events
    _subscription = _controller.barcodes.listen(_handleBarcode);

    // Start the scanner
    try {

     await _controller.start();

    }
     catch (e) {

      _onErrorCallback?.call('Failed to start scanner: $e');
    }
  }

  /// Handle barcode detection
  void _handleBarcode(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;

    final String code = capture.barcodes.first.rawValue ?? '';
    if (code.isEmpty) return;

    _processScannedCode(code);
  }

  /// Process the scanned QR code
  void _processScannedCode(String code) {
    try {
      if (_scannedItems.containsKey(code)) {
        // Item already exists
        final existingItem = _scannedItems[code]!;
        
        if (existingItem.status == ItemStatus.preparing) {
          // Change status from preparing to ready
          final updatedItem = existingItem.copyWith(
            status: ItemStatus.ready,
            lastScannedAt: DateTime.now(),
          );
          _scannedItems[code] = updatedItem;
          
          _onStatusChangedCallback?.call(updatedItem);
          _onSuccessCallback?.call('Item status changed to Ready!');
        } else if (existingItem.status == ItemStatus.ready) {
          // Item is ready, can be scanned again
          final updatedItem = existingItem.copyWith(
            lastScannedAt: DateTime.now(),
          );
          _scannedItems[code] = updatedItem;
          
          _onItemScannedCallback?.call(updatedItem);
          _onSuccessCallback?.call('Item scanned successfully!');
        }
      } else {
        // New item - save with preparing status
        final newItem = ScannedItem(code: code);
        _scannedItems[code] = newItem;
        
        _onItemScannedCallback?.call(newItem);
        _onSuccessCallback?.call('New item scanned successfully!');
      }
    } catch (e) {
      _onErrorCallback?.call('Error processing scanned code: $e');
    }
  }

  /// Start scanning
  Future<void> startScanning() async {
    try {
      if (!_controller.value.isRunning) {
        await _controller.start();
      }
    } catch (e) {
      _onErrorCallback?.call('Failed to start scanning: $e');
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    try {
      if (_controller.value.isRunning) {
        await _controller.stop();
      }
    } catch (e) {
      _onErrorCallback?.call('Failed to stop scanning: $e');
    }
  }

  /// Pause scanning
  Future<void> pauseScanning() async {
    await _subscription?.cancel();
    _subscription = null;
    await stopScanning();
  }

  /// Resume scanning
  Future<void> resumeScanning() async {
    _subscription = _controller.barcodes.listen(_handleBarcode);
    await startScanning();
  }

  /// Get item by code
  ScannedItem? getItem(String code) {
    return _scannedItems[code];
  }

  /// Get all items with specific status
  List<ScannedItem> getItemsByStatus(ItemStatus status) {
    return _scannedItems.values.where((item) => item.status == status).toList();
  }

  /// Get items count
  int get itemsCount => _scannedItems.length;

  /// Get preparing items count
  int get preparingItemsCount => getItemsByStatus(ItemStatus.preparing).length;

  /// Get ready items count
  int get readyItemsCount => getItemsByStatus(ItemStatus.ready).length;

  /// Clear all scanned items
  void clearAllItems() {
    _scannedItems.clear();
  }

  /// Remove specific item
  bool removeItem(String code) {
    return _scannedItems.remove(code) != null;
  }

  /// Manually add item (for testing or manual entry)
  void addItem(String code, {ItemStatus status = ItemStatus.preparing}) {
    _scannedItems[code] = ScannedItem(code: code, status: status);
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it
    if (!_controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed
        _subscription = _controller.barcodes.listen(_handleBarcode);
        _controller.start();
        break;
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused
        _subscription?.cancel();
        _subscription = null;
        _controller.stop();
        break;
    }
  }

  /// Dispose the service
  Future<void> dispose() async {

    WidgetsBinding.instance.removeObserver(this);

    await _subscription?.cancel();
    _subscription = null;
    
    await _controller.dispose();
    

    _scannedItems.clear();
  }
}