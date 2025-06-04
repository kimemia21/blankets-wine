
import 'dart:async';

import 'package:blankets_and_wines_example/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QRCodeService {
  // Private constructor for singleton pattern
  static final QRCodeService _instance = QRCodeService._internal();
  factory QRCodeService() => _instance;
  QRCodeService._internal();

  // Core components
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounceTimer;
  Timer? _refocusTimer;
  Timer? _periodicRefocusTimer;
  
  // State management
  bool _isInitialized = false;
  bool _isDisposed = false;
  String _lastScannedCode = '';
  DateTime _lastScanTime = DateTime.now();
  
  // Configuration
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  static const Duration _duplicatePreventionWindow = Duration(seconds: 2);
  static const Duration _refocusInterval = Duration(seconds: 3);
  
  // Event streams for reactive programming
  final StreamController<String> _scanController = StreamController<String>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  final StreamController<bool> _readyController = StreamController<bool>.broadcast();

  // Getters for streams - use these to listen for events anywhere in your app
  Stream<String> get onScan => _scanController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<bool> get onReady => _readyController.stream;

  /// Initialize the QR scanner service
  /// Call this once in your main.dart or app startup
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;
    
    try {
      _controller = TextEditingController();
      _focusNode = FocusNode();
      
      // Setup focus management
      _setupFocusHandling();
      
      // Auto-focus after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestFocus();
        _startPeriodicRefocus();
      });
      
      _isInitialized = true;
      _readyController.add(true);
      
      debugPrint('QRCodeService: Initialized successfully');
    } catch (e) {
      debugPrint('QRCodeService: Initialization failed - $e');
      _errorController.add('Failed to initialize QR scanner: $e');
    }
  }

  /// Setup focus handling and listeners
  void _setupFocusHandling() {
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && !_isDisposed) {
        debugPrint('QRCodeService: Lost focus, attempting to regain...');
        _scheduleRefocus();
      }
    });
  }

  /// Handle QR code scan input from barcode scanner
  void _handleScan(String rawInput) {
    if (_isDisposed || rawInput.isEmpty) return;
    
    debugPrint('QRCodeService: Raw input received - $rawInput');
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // Debounce rapid scans
    _debounceTimer = Timer(_debounceDuration, () {
      _processScan(rawInput.trim()); 
    });
  }

  /// Process the scanned QR code
  void _processScan(String qrCode) {
    try {
      // Prevent duplicate scans within time window
      final now = DateTime.now();
      if (_lastScannedCode == qrCode && 
          now.difference(_lastScanTime) < _duplicatePreventionWindow) {
        debugPrint('QRCodeService: Duplicate scan ignored - $qrCode');
        return;
      }
      
      // Validate QR code
      if (!_isValidQRCode(qrCode)) {
        final error = 'Invalid QR code format: $qrCode';
        debugPrint('QRCodeService: $error');
        _errorController.add(error);
        return;
      }
      
      // Update global state
      _lastScannedCode = qrCode;
      _lastScanTime = now;
      qrcode = qrCode; // Update global variable
      
      debugPrint('QRCodeService: Valid QR code processed - $qrCode');
      
      // Clear input and maintain focus
      _controller.clear();
      _requestFocus();
      
      // Notify all listeners through stream
      _scanController.add(qrCode);
      
    } catch (e) {
      final error = 'Error processing QR code: $e';
      debugPrint('QRCodeService: $error');
      _errorController.add(error);
    }
  }

  /// Validate QR code format
  bool _isValidQRCode(String code) {
    // Basic validation - customize based on your POS requirements
    if (code.isEmpty) return false;
    if (code.length < 3 || code.length > 500) return false;
    
    // Add your specific POS validation here:
    // - Product codes format
    // - Customer IDs format
    // - Transaction IDs format
    // Example: return code.startsWith('PROD-') || code.startsWith('CUST-');
    
    return true; // Accept all valid-length codes for now
  }

  /// Request focus safely
  void _requestFocus() {
    if (!_isDisposed && _focusNode.canRequestFocus) {
      Future.microtask(() {
        if (!_isDisposed && _focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  /// Schedule refocus after a delay
  void _scheduleRefocus() {
    _refocusTimer?.cancel();
    _refocusTimer = Timer(const Duration(milliseconds: 100), _requestFocus);
  }

  /// Start periodic refocus to maintain scanner readiness
  void _startPeriodicRefocus() {
    _periodicRefocusTimer?.cancel();
    _periodicRefocusTimer = Timer.periodic(_refocusInterval, (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      if (!_focusNode.hasFocus) {
        _requestFocus();
      }
    });
  }

  /// Get the hidden text field widget - add this to your main app widget
  Widget buildScannerInput() {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: -1000, // Hidden off-screen
      top: -1000,
      child: SizedBox(
        width: 1,
        height: 1,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          enableSuggestions: false,
          autocorrect: false,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          // inputFormatters: [
          //   FilteringTextInputFormatter.deny(RegExp(r'[\n\r\t]')),
          // ],
          style: const TextStyle(
            color: Colors.transparent,
            fontSize: 1,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
          onSubmitted: _handleScan,
          onTapOutside: (_) => _requestFocus(),
          onTap: () => _requestFocus(),
        ),
      ),
    );
  }

  /// Clear current QR code
  void clearCurrentCode() {
    qrcode = '';
    _lastScannedCode = '';
    _controller.clear();
    _requestFocus();
    debugPrint('QRCodeService: QR code cleared');
  }

  /// Force trigger a scan (for testing)
  void simulateScan(String qrCode) {
    _handleScan(qrCode);
  }

  String get currentCode => qrcode;


  DateTime get lastScanTime => _lastScanTime;

  /// Check if service is ready
  bool get isReady => _isInitialized && !_isDisposed;

  /// Get service statistics
  Map<String, dynamic> getStats() {
    return {
      'isReady': isReady,
      'currentCode': currentCode,
      'lastScanTime': lastScanTime.toIso8601String(),
      'hasFocus': _focusNode.hasFocus,
      'isInitialized': _isInitialized,
      'isDisposed': _isDisposed,
    };
  }

  /// Dispose of resources
  void dispose() {
    if (_isDisposed) return;
    
    debugPrint('QRCodeService: Disposing...');
    
    _isDisposed = true;
    _debounceTimer?.cancel();
    _refocusTimer?.cancel();
    _periodicRefocusTimer?.cancel();
    
    _controller.dispose();
    _focusNode.dispose();
    
    _scanController.close();
    _errorController.close();
    _readyController.close();
    
    qrcode = '';
  }
}