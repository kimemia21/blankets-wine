import 'dart:async';
import 'dart:collection';

import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Enum for QR code status
enum QRCodeStatus { preparing, ready, processed }

// Class to track QR code state
class QRCodeState {
  final String code;
  QRCodeStatus status;
  DateTime firstScanTime;
  DateTime lastScanTime;
  int scanCount;

  QRCodeState({
    required this.code,
    required this.status,
    required this.firstScanTime,
    required this.lastScanTime,
    this.scanCount = 1,
  });

  // Check if enough time has passed for status change (5 seconds rule)
  bool canChangeStatus() {
    return DateTime.now().difference(lastScanTime).inSeconds >= 5;
  }

  // Check if this is a transition from preparing to ready
  bool isPreparingToReadyTransition() {
    return status == QRCodeStatus.preparing && scanCount == 1;
  }

  @override
  String toString() {
    return 'QRCodeState(code: $code, status: $status, scanCount: $scanCount, lastScan: $lastScanTime)';
  }
}

class QRCodeService {
  // Private constructor for singleton pattern
  static final QRCodeService _instance = QRCodeService._internal();
  factory QRCodeService() => _instance;
  QRCodeService._internal();

  // Core components
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounceTimer;
  Timer? _smartRefocusTimer;

  // State management
  bool _isInitialized = false;
  bool _isDisposed = false;
  String _lastScannedCode = '';
  DateTime _lastScanTime = DateTime.now();

  // NEW: Smart focus management
  bool _scannerEnabled = false;
  bool _lastUserInteractionWasManual = false;
  DateTime _lastUserInteraction = DateTime.now();

  // Track other focus nodes in the app
  final Set<FocusNode> _registeredFocusNodes = <FocusNode>{};

  // OPTIMIZATION 1: Use HashMap for O(1) lookups instead of Map
  final HashMap<String, QRCodeState> _qrCodeStates =
      HashMap<String, QRCodeState>();

  // OPTIMIZATION 2: Maintain separate collections for each status for O(1) status filtering
  final LinkedHashSet<QRCodeState> _preparingItems =
      LinkedHashSet<QRCodeState>();
  final LinkedHashSet<QRCodeState> _readyItems = LinkedHashSet<QRCodeState>();
  final LinkedHashSet<QRCodeState> _processedItems =
      LinkedHashSet<QRCodeState>();

  // OPTIMIZATION 3: Cache frequently accessed values
  int _totalCount = 0;
  int _preparingCount = 0;
  int _readyCount = 0;
  int _processedCount = 0;

  // OPTIMIZATION 4: Precompiled regex for validation
  static final RegExp _validationRegex = RegExp(r'^.{3,500}$');

  // Configuration
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  static const Duration _duplicatePreventionWindow = Duration(seconds: 2);
  static const Duration _smartRefocusDelay = Duration(
    seconds: 2,
  ); // Only refocus after user inactivity
  static const Duration _statusChangeDelay = Duration(seconds: 5);

  // Event streams
  final StreamController<String> _scanController =
      StreamController<String>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<bool> _readyController =
      StreamController<bool>.broadcast();
  final StreamController<QRCodeState> _statusChangeController =
      StreamController<QRCodeState>.broadcast();

  // Getters for streams
  Stream<String> get onScan => _scanController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<bool> get onReady => _readyController.stream;
  Stream<QRCodeState> get onStatusChange => _statusChangeController.stream;

  /// Initialize the QR scanner service
  Future<void> initialize() async {
    print("called");
    if (_isInitialized || _isDisposed) return;

    try {
      _controller = TextEditingController();
      _focusNode = FocusNode();

      // Setup intelligent focus handling
      _setupSmartFocusHandling();

      _isInitialized = true;
      _readyController.add(true);

      debugPrint('QRCodeService: Initialized successfully');
    } catch (e) {
      debugPrint('QRCodeService: Initialization failed - $e');
      _errorController.add('Failed to initialize QR scanner: $e');
    }
  }

  /// NEW: Enable scanner mode
  void enableScanner() {
    _scannerEnabled = true;
    debugPrint('QRCodeService: Scanner enabled');

    // Only auto-focus if no manual interaction recently
    if (!_lastUserInteractionWasManual) {
      _scheduleSmartRefocus();
    }
  }

  /// NEW: Disable scanner mode
  void disableScanner() {
    _scannerEnabled = false;
    _smartRefocusTimer?.cancel();

    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }

    debugPrint('QRCodeService: Scanner disabled');
  }

  /// NEW: Register other focus nodes in your app
  void registerFocusNode(FocusNode focusNode) {
    _registeredFocusNodes.add(focusNode);

    // Listen to this focus node to detect manual interactions
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        _lastUserInteractionWasManual = true;
        _lastUserInteraction = DateTime.now();
        _smartRefocusTimer?.cancel(); // Stop trying to focus scanner
        debugPrint('QRCodeService: Manual text field interaction detected');
      }
    });
  }

  /// NEW: Unregister focus nodes when they're disposed
  void unregisterFocusNode(FocusNode focusNode) {
    _registeredFocusNodes.remove(focusNode);
  }

  /// Setup intelligent focus handling
  void _setupSmartFocusHandling() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _lastUserInteractionWasManual = false; // Scanner got focus, not manual
      }
    });
  }

  /// NEW: Smart refocus that respects user interactions
  void _scheduleSmartRefocus() {
    if (!_scannerEnabled) return;

    _smartRefocusTimer?.cancel();
    _smartRefocusTimer = Timer(_smartRefocusDelay, () {
      if (!_scannerEnabled || _isDisposed) return;

      // Check if any registered focus nodes have focus
      final bool anyManualFieldFocused = _registeredFocusNodes.any(
        (node) => node.hasFocus,
      );

      // Check if user had recent manual interaction
      final bool recentManualInteraction =
          DateTime.now().difference(_lastUserInteraction).inSeconds < 5;

      // Only refocus scanner if:
      // 1. Scanner is enabled
      // 2. No manual text fields are focused
      // 3. No recent manual interaction
      // 4. Scanner doesn't already have focus
      if (!anyManualFieldFocused &&
          !recentManualInteraction &&
          !_focusNode.hasFocus &&
          _scannerEnabled) {
        _requestFocus();
        debugPrint('QRCodeService: Smart refocus executed');
      } else {
        debugPrint(
          'QRCodeService: Smart refocus skipped (user interaction detected)',
        );
      }
    });
  }

  /// Handle QR code scan input
  void _handleScan(String rawInput) {
    if (_isDisposed || rawInput.isEmpty) return;

    debugPrint('QRCodeService: Raw input received - $rawInput');

    // Mark as scanner interaction (not manual)
    _lastUserInteractionWasManual = false;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _processScan(rawInput.trim());
    });
  }

  /// Process the scanned QR code with status management
  void _processScan(String qrCode) {
    try {
      if (qrCode.isEmpty) return;

      if (!_isValidQRCodeFast(qrCode)) {
        final error = 'Invalid QR code format: $qrCode';
        debugPrint('QRCodeService: $error');
        _errorController.add(error);
        return;
      }

      final now = DateTime.now();

      final existingState = _qrCodeStates[qrCode];
      if (existingState != null) {
        _handleExistingQRCode(qrCode, now, existingState);
      } else {
        _handleNewQRCode(qrCode, now);
      }

      _lastScannedCode = qrCode;
      _lastScanTime = now;
      qrcode = qrCode;

      _controller.clear();

      // Only refocus if scanner is enabled and no manual interaction
      if (_scannerEnabled && !_lastUserInteractionWasManual) {
        _scheduleSmartRefocus();
      }

      _scanController.add(qrCode);
    } catch (e) {
      final error = 'Error processing QR code: $e';
      debugPrint('QRCodeService: $error');
      _errorController.add(error);
    }
  }

  /// Handle scanning of a new QR code
  void _handleNewQRCode(String qrCode, DateTime now) {
    final qrState = QRCodeState(
      code: qrCode,
      status: QRCodeStatus.preparing,
      firstScanTime: now,
      lastScanTime: now,
      scanCount: 1,
    );

    _qrCodeStates[qrCode] = qrState;
    _preparingItems.add(qrState);

    _totalCount++;
    _preparingCount++;

    debugPrint('QRCodeService: New QR code - $qrCode set to PREPARING');
    _statusChangeController.add(qrState);
  }

  /// Handle scanning of an existing QR code
  void _handleExistingQRCode(String qrCode, DateTime now, QRCodeState qrState) {
    if (qrState.status == QRCodeStatus.ready ||
        qrState.status == QRCodeStatus.processed) {
      final error =
          'QR code $qrCode is already processed and cannot be scanned again';
      debugPrint('QRCodeService: $error');
      _errorController.add(error);
      return;
    }

    if (!qrState.isPreparingToReadyTransition() && !qrState.canChangeStatus()) {
      final timeLeft = 5 - now.difference(qrState.lastScanTime).inSeconds;
      final error =
          'Please wait ${timeLeft} more seconds before scanning $qrCode again';
      debugPrint('QRCodeService: $error');
      _errorController.add(error);
      return;
    }

    if (qrState.status == QRCodeStatus.preparing) {
      _preparingItems.remove(qrState);
      qrState.status = QRCodeStatus.ready;
      qrState.scanCount++;
      qrState.lastScanTime = now;
      _readyItems.add(qrState);

      _preparingCount--;
      _readyCount++;

      debugPrint('QRCodeService: QR code $qrCode updated to READY');
      _statusChangeController.add(qrState);
    }
  }

  /// Fast validation using precompiled regex
  bool _isValidQRCodeFast(String code) {
    final length = code.length;
    if (length < 3 || length > 500) return false;
    return _validationRegex.hasMatch(code);
  }

  /// Request focus safely and intelligently
  void _requestFocus() {
    if (!_isDisposed && _scannerEnabled && _focusNode.canRequestFocus) {
      // Check if any manual field is focused before requesting focus
      final bool anyManualFieldFocused = _registeredFocusNodes.any(
        (node) => node.hasFocus,
      );

      if (!anyManualFieldFocused) {
        Future.microtask(() {
          if (!_isDisposed && _scannerEnabled && _focusNode.canRequestFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    }
  }

  /// Get the hidden text field widget
  Widget buildScannerInput() {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: -1000,
      top: -1000,
      child: SizedBox(
        width: 1,
        height: 1,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: false, // Don't auto-focus, let smart logic handle it
          enableSuggestions: false,
          autocorrect: false,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          style: const TextStyle(color: Colors.transparent, fontSize: 1),
          decoration: const InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
          onSubmitted: _handleScan,
          onTapOutside: (_) {
            // Don't automatically refocus on tap outside
            // Let smart logic decide when to refocus
          },
          onTap: () {
            // User manually tapped, so this is intentional
            _lastUserInteractionWasManual = false;
          },
        ),
      ),
    );
  }

  /// NEW: Helper widget to wrap your manual text fields
  Widget wrapManualTextField(Widget textField, FocusNode focusNode) {
    // Auto-register the focus node
    registerFocusNode(focusNode);

    return textField;
  }

  /// Clear current QR code
  void clearCurrentCode() {
    qrcode = '';
    _lastScannedCode = '';
    _controller.clear();
    debugPrint('QRCodeService: QR code cleared');
  }

  /// Force trigger a scan (for testing)
  void simulateScan(String qrCode) {
    _handleScan(qrCode);
  }

  // All the existing methods remain the same...
  QRCodeStatus? getQRCodeStatus(String qrCode) {
    return _qrCodeStates[qrCode]?.status;
  }

  QRCodeState? getQRCodeState(String qrCode) {
    return _qrCodeStates[qrCode];
  }

  List<QRCodeState> getQRCodesWithStatus(QRCodeStatus status) {
    switch (status) {
      case QRCodeStatus.preparing:
        return _preparingItems.toList();
      case QRCodeStatus.ready:
        return _readyItems.toList();
      case QRCodeStatus.processed:
        return _processedItems.toList();
    }
  }

  List<QRCodeState> get preparingItems => _preparingItems.toList();
  List<QRCodeState> get readyItems => _readyItems.toList();
  List<QRCodeState> get processedItems => _processedItems.toList();

  bool markAsProcessed(String qrCode) {
    final qrState = _qrCodeStates[qrCode];
    if (qrState != null && qrState.status == QRCodeStatus.ready) {
      _readyItems.remove(qrState);
      qrState.status = QRCodeStatus.processed;
      qrState.lastScanTime = DateTime.now();
      _processedItems.add(qrState);

      _readyCount--;
      _processedCount++;

      debugPrint('QRCodeService: QR code $qrCode marked as PROCESSED');
      _statusChangeController.add(qrState);
      return true;
    }
    return false;
  }

  void resetQRCodeState(String qrCode) {
    final qrState = _qrCodeStates.remove(qrCode);
    if (qrState != null) {
      switch (qrState.status) {
        case QRCodeStatus.preparing:
          _preparingItems.remove(qrState);
          _preparingCount--;
          break;
        case QRCodeStatus.ready:
          _readyItems.remove(qrState);
          _readyCount--;
          break;
        case QRCodeStatus.processed:
          _processedItems.remove(qrState);
          _processedCount--;
          break;
      }
      _totalCount--;
    }
    debugPrint('QRCodeService: QR code $qrCode state reset');
  }

  void clearAllStates() {
    _qrCodeStates.clear();
    _preparingItems.clear();
    _readyItems.clear();
    _processedItems.clear();

    _totalCount = 0;
    _preparingCount = 0;
    _readyCount = 0;
    _processedCount = 0;

    debugPrint('QRCodeService: All QR code states cleared');
  }

  // Getters
  String get currentCode => qrcode;
  DateTime get lastScanTime => _lastScanTime;
  bool get isReady => _isInitialized && !_isDisposed;
  bool get isScannerEnabled => _scannerEnabled;

  Map<String, dynamic> getStats() {
    return {
      'isReady': isReady,
      'isScannerEnabled': isScannerEnabled,
      'currentCode': currentCode,
      'lastScanTime': lastScanTime.toIso8601String(),
      'hasFocus': _focusNode.hasFocus,
      'isInitialized': _isInitialized,
      'isDisposed': _isDisposed,
      'lastUserInteractionWasManual': _lastUserInteractionWasManual,
      'registeredFocusNodes': _registeredFocusNodes.length,
      'totalQRCodes': _totalCount,
      'preparingCount': _preparingCount,
      'readyCount': _readyCount,
      'processedCount': _processedCount,
    };
  }

  /// Dispose of resources
  void dispose() {
    if (_isDisposed) return;

    debugPrint('QRCodeService: Disposing...');

    _isDisposed = true;
    _scannerEnabled = false;
    _debounceTimer?.cancel();
    _smartRefocusTimer?.cancel();

    _controller.dispose();
    _focusNode.dispose();

    _scanController.close();
    _errorController.close();
    _readyController.close();
    _statusChangeController.close();

    _registeredFocusNodes.clear();
    clearAllStates();
    qrcode = '';
  }
}
