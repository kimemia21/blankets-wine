import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:blankets_and_wines_example/data/services/QRCODEBCK.dart';

// Import your QRCodeService here
// import 'package:your_app/path/to/qr_code_service.dart';

// Mock classes for testing
@GenerateMocks([TextEditingController, FocusNode])

 import 'qrctest.mocks.dart';

void main() {
  group('QRCodeService Tests', () {
    late QRCodeService qrCodeService;
    
    setUp(() {
      // Reset the singleton instance for each test
      qrCodeService = QRCodeService();
    });
    
    tearDown(() {
      qrCodeService.dispose();
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        expect(qrCodeService.isReady, isFalse);
        
        await qrCodeService.initialize();
        
        expect(qrCodeService.isReady, isTrue);
        expect(qrCodeService.currentCode, isEmpty);
        expect(qrCodeService.isScannerEnabled, isFalse);
      });

      test('should not initialize twice', () async {
        await qrCodeService.initialize();
        expect(qrCodeService.isReady, isTrue);
        
        // Second initialization should not change state
        await qrCodeService.initialize();
        expect(qrCodeService.isReady, isTrue);
      });

      test('should emit ready event on initialization', () async {
        bool readyEmitted = false;
        qrCodeService.onReady.listen((ready) {
          readyEmitted = ready;
        });
        
        await qrCodeService.initialize();
        
        // Wait for stream event
        await Future.delayed(Duration(milliseconds: 10));
        expect(readyEmitted, isTrue);
      });
    });

    group('Scanner Enable/Disable Tests', () {
      setUp(() async {
        await qrCodeService.initialize();
      });

      test('should enable scanner', () {
        expect(qrCodeService.isScannerEnabled, isFalse);
        
        qrCodeService.enableScanner();
        
        expect(qrCodeService.isScannerEnabled, isTrue);
      });

      test('should disable scanner', () {
        qrCodeService.enableScanner();
        expect(qrCodeService.isScannerEnabled, isTrue);
        
        qrCodeService.disableScanner();
        
        expect(qrCodeService.isScannerEnabled, isFalse);
      });
    });

    group('QR Code Scanning Tests', () {
      setUp(() async {
        await qrCodeService.initialize();
        qrCodeService.enableScanner();
      });

      test('should handle valid QR code scan', () async {
        String? scannedCode;
        qrCodeService.onScan.listen((code) {
          scannedCode = code;
        });

        qrCodeService.simulateScan('TEST_QR_CODE_123');
        
        // Wait for debounce
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(scannedCode, equals('TEST_QR_CODE_123'));
        expect(qrCodeService.currentCode, equals('TEST_QR_CODE_123'));
      });

      test('should reject invalid QR codes', () async {
        String? errorMessage;
        qrCodeService.onError.listen((error) {
          errorMessage = error;
        });

        // Test with too short code
        qrCodeService.simulateScan('AB');
        
        // Wait for debounce
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(errorMessage, contains('Invalid QR code format'));
      });

      test('should reject empty QR codes', () {
        String? scannedCode;
        qrCodeService.onScan.listen((code) {
          scannedCode = code;
        });

        qrCodeService.simulateScan('');
        
        // Should not emit any scan event
        expect(scannedCode, isNull);
      });

      test('should handle very long QR codes', () async {
        String? errorMessage;
        qrCodeService.onError.listen((error) {
          errorMessage = error;
        });

        // Create a string longer than 500 characters
        final longCode = 'A' * 501;
        qrCodeService.simulateScan(longCode);
        
        // Wait for debounce
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(errorMessage, contains('Invalid QR code format'));
      });
    });

    group('QR Code Status Management Tests', () {
      setUp(() async {
        await qrCodeService.initialize();
        qrCodeService.enableScanner();
      });

      test('should set new QR code to preparing status', () async {
        QRCodeState? statusChange;
        qrCodeService.onStatusChange.listen((state) {
          statusChange = state;
        });

        qrCodeService.simulateScan('NEW_CODE');
        
        // Wait for debounce
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(statusChange?.code, equals('NEW_CODE'));
        expect(statusChange?.status, equals(QRCodeStatus.preparing));
        expect(statusChange?.scanCount, equals(1));
        expect(qrCodeService.getQRCodeStatus('NEW_CODE'), equals(QRCodeStatus.preparing));
      });

      test('should transition from preparing to ready on second scan', () async {
        // First scan - should be preparing
        qrCodeService.simulateScan('TRANSITION_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(qrCodeService.getQRCodeStatus('TRANSITION_CODE'), equals(QRCodeStatus.preparing));
        
        // Second scan - should transition to ready
        QRCodeState? statusChange;
        qrCodeService.onStatusChange.listen((state) {
          if (state.status == QRCodeStatus.ready) {
            statusChange = state;
          }
        });

        qrCodeService.simulateScan('TRANSITION_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(statusChange?.status, equals(QRCodeStatus.ready));
        expect(statusChange?.scanCount, equals(2));
        expect(qrCodeService.getQRCodeStatus('TRANSITION_CODE'), equals(QRCodeStatus.ready));
      });

      test('should prevent scanning ready/processed QR codes', () async {
        String? errorMessage;
        qrCodeService.onError.listen((error) {
          errorMessage = error;
        });

        // Create a QR code and transition it to ready
        qrCodeService.simulateScan('READY_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        qrCodeService.simulateScan('READY_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(qrCodeService.getQRCodeStatus('READY_CODE'), equals(QRCodeStatus.ready));
        
        // Try to scan again - should error
        qrCodeService.simulateScan('READY_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(errorMessage, contains('already processed'));
      });

      test('should enforce 5-second delay for status changes', () async {
        String? errorMessage;
        qrCodeService.onError.listen((error) {
          errorMessage = error;
        });

        // Scan once to set to preparing
        qrCodeService.simulateScan('DELAY_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        
        // Manually update the state to simulate a scan that requires delay
        final state = qrCodeService.getQRCodeState('DELAY_CODE');
        state!.scanCount = 2; // Make it not a preparing-to-ready transition
        
        // Try to scan again immediately - should error
        qrCodeService.simulateScan('DELAY_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(errorMessage, contains('Please wait'));
      });

      test('should mark QR code as processed', () {
        // Create and transition to ready
        qrCodeService.simulateScan('PROCESS_CODE');
        qrCodeService.simulateScan('PROCESS_CODE');
        
        expect(qrCodeService.markAsProcessed('PROCESS_CODE'), isTrue);
        expect(qrCodeService.getQRCodeStatus('PROCESS_CODE'), equals(QRCodeStatus.processed));
        
        // Should not mark non-ready codes as processed
        expect(qrCodeService.markAsProcessed('NON_EXISTENT'), isFalse);
      });
    });

    group('QR Code State Collections Tests', () {
      setUp(() async {
        await qrCodeService.initialize();
        qrCodeService.enableScanner();
      });

      test('should maintain separate collections for each status', () async {
        // Create codes in different states
        qrCodeService.simulateScan('PREPARING_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        
        qrCodeService.simulateScan('READY_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        qrCodeService.simulateScan('READY_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        
        // Mark one as processed
        qrCodeService.markAsProcessed('READY_CODE');
        
        expect(qrCodeService.preparingItems.length, equals(1));
        expect(qrCodeService.readyItems.length, equals(0));
        expect(qrCodeService.processedItems.length, equals(1));
        
        expect(qrCodeService.preparingItems.first.code, equals('PREPARING_CODE'));
        expect(qrCodeService.processedItems.first.code, equals('READY_CODE'));
      });

      test('should filter QR codes by status', () async {
        // Create multiple codes
        for (int i = 0; i < 3; i++) {
          qrCodeService.simulateScan('CODE_$i');
          await Future.delayed(Duration(milliseconds: 400));
        }
        
        final preparingCodes = qrCodeService.getQRCodesWithStatus(QRCodeStatus.preparing);
        expect(preparingCodes.length, equals(3));
        
        // Transition one to ready
        qrCodeService.simulateScan('CODE_0');
        await Future.delayed(Duration(milliseconds: 400));
        
        final readyCodes = qrCodeService.getQRCodesWithStatus(QRCodeStatus.ready);
        expect(readyCodes.length, equals(1));
        expect(readyCodes.first.code, equals('CODE_0'));
      });
    });

    group('Focus Node Management Tests', () {
      setUp(() async {
        await qrCodeService.initialize();
      });

      test('should register and unregister focus nodes', () {
        final focusNode = FocusNode();
        final stats = qrCodeService.getStats();
        final initialCount = stats['registeredFocusNodes'] as int;
        
        qrCodeService.registerFocusNode(focusNode);
        
        final afterRegister = qrCodeService.getStats();
        expect(afterRegister['registeredFocusNodes'], equals(initialCount + 1));
        
        qrCodeService.unregisterFocusNode(focusNode);
        
        final afterUnregister = qrCodeService.getStats();
        expect(afterUnregister['registeredFocusNodes'], equals(initialCount));
        
        focusNode.dispose();
      });

      test('should wrap manual text field correctly', () {
        final focusNode = FocusNode();
        final textField = TextField(focusNode: focusNode);
        
        final wrappedWidget = qrCodeService.wrapManualTextField(textField, focusNode);
        
        expect(wrappedWidget, isA<TextField>());
        
        // Verify focus node was registered
        final stats = qrCodeService.getStats();
        expect(stats['registeredFocusNodes'], greaterThan(0));
        
        focusNode.dispose();
      });
    });

    group('State Management Tests', () {
      setUp(() async {
        await qrCodeService.initialize();
        qrCodeService.enableScanner();
      });

      test('should reset QR code state', () async {
        qrCodeService.simulateScan('RESET_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(qrCodeService.getQRCodeStatus('RESET_CODE'), equals(QRCodeStatus.preparing));
        
        qrCodeService.resetQRCodeState('RESET_CODE');
        
        expect(qrCodeService.getQRCodeStatus('RESET_CODE'), isNull);
        expect(qrCodeService.preparingItems.length, equals(0));
      });

      test('should clear all states', () async {
        // Create multiple QR codes
        for (int i = 0; i < 5; i++) {
          qrCodeService.simulateScan('CLEAR_CODE_$i');
          await Future.delayed(Duration(milliseconds: 400));
        }
        
        expect(qrCodeService.preparingItems.length, equals(5));
        
        qrCodeService.clearAllStates();
        
        expect(qrCodeService.preparingItems.length, equals(0));
        expect(qrCodeService.readyItems.length, equals(0));
        expect(qrCodeService.processedItems.length, equals(0));
        
        final stats = qrCodeService.getStats();
        expect(stats['totalQRCodes'], equals(0));
      });

      test('should clear current code', () async {
        qrCodeService.simulateScan('CURRENT_CODE');
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(qrCodeService.currentCode, equals('CURRENT_CODE'));
        
        qrCodeService.clearCurrentCode();
        
        expect(qrCodeService.currentCode, isEmpty);
      });
    });

    group('Statistics Tests', () {
      setUp(() async {
        await qrCodeService.initialize();
        qrCodeService.enableScanner();
      });

      test('should provide accurate statistics', () async {
        final initialStats = qrCodeService.getStats();
        expect(initialStats['isReady'], isTrue);
        expect(initialStats['isScannerEnabled'], isTrue);
        expect(initialStats['totalQRCodes'], equals(0));
        
        // Add some QR codes
        qrCodeService.simulateScan('STATS_CODE_1');
        await Future.delayed(Duration(milliseconds: 400));
        qrCodeService.simulateScan('STATS_CODE_2');
        await Future.delayed(Duration(milliseconds: 400));
        
        final afterScans = qrCodeService.getStats();
        expect(afterScans['totalQRCodes'], equals(2));
        expect(afterScans['preparingCount'], equals(2));
        expect(afterScans['readyCount'], equals(0));
        expect(afterScans['processedCount'], equals(0));
      });
    });

    group('Widget Builder Tests', () {
      setUp(() async {
        await qrCodeService.initialize();
      });

      testWidgets('should build scanner input widget', (WidgetTester tester) async {
        final widget = qrCodeService.buildScannerInput();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [widget],
              ),
            ),
          ),
        );
        
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(Positioned), findsOneWidget);
      });

      testWidgets('should return empty widget when not initialized', (WidgetTester tester) async {
        final uninitializedService = QRCodeService();
        final widget = uninitializedService.buildScannerInput();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: widget,
            ),
          ),
        );
        
        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        
        uninitializedService.dispose();
      });
    });

    group('Error Handling Tests', () {
      setUp() async {
        await qrCodeService.initialize();
        qrCodeService.enableScanner();
      }

      test('should handle multiple rapid scans with debouncing', () async {
        final scannedCodes = <String>[];
        qrCodeService.onScan.listen((code) {
          scannedCodes.add(code);
        });

        // Simulate rapid scanning
        qrCodeService.simulateScan('RAPID_1');
        qrCodeService.simulateScan('RAPID_2');
        qrCodeService.simulateScan('RAPID_3');
        
        // Wait for debounce
        await Future.delayed(Duration(milliseconds: 400));
        
        // Only the last scan should be processed due to debouncing
        expect(scannedCodes.length, equals(1));
        expect(scannedCodes.first, equals('RAPID_3'));
      });

      test('should handle disposal during processing', () {
        qrCodeService.simulateScan('DISPOSE_TEST');
        
        // Dispose immediately
        qrCodeService.dispose();
        
        // Should not crash or throw exceptions
        expect(qrCodeService.isReady, isFalse);
      });
    });

    group('Stream Management Tests', () {
      setUp() async {
        await qrCodeService.initialize();
        qrCodeService.enableScanner();
      }

      test('should emit scan events', () async {
        final scannedCodes = <String>[];
        final subscription = qrCodeService.onScan.listen((code) {
          scannedCodes.add(code);
        });

        qrCodeService.simulateScan('STREAM_TEST');
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(scannedCodes, contains('STREAM_TEST'));
        
        await subscription.cancel();
      });

      test('should emit error events', () async {
        final errors = <String>[];
        final subscription = qrCodeService.onError.listen((error) {
          errors.add(error);
        });

        qrCodeService.simulateScan('AB'); // Too short
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(errors.length, greaterThan(0));
        expect(errors.first, contains('Invalid QR code format'));
        
        await subscription.cancel();
      });

      test('should emit status change events', () async {
        final statusChanges = <QRCodeState>[];
        final subscription = qrCodeService.onStatusChange.listen((state) {
          statusChanges.add(state);
        });

        qrCodeService.simulateScan('STATUS_STREAM_TEST');
        await Future.delayed(Duration(milliseconds: 400));
        
        expect(statusChanges.length, greaterThan(0));
        expect(statusChanges.first.code, equals('STATUS_STREAM_TEST'));
        expect(statusChanges.first.status, equals(QRCodeStatus.preparing));
        
        await subscription.cancel();
      });
    });

    group('QRCodeState Tests', () {
      test('should create QRCodeState correctly', () {
        final now = DateTime.now();
        final state = QRCodeState(
          code: 'TEST_CODE',
          status: QRCodeStatus.preparing,
          firstScanTime: now,
          lastScanTime: now,
          scanCount: 1,
        );

        expect(state.code, equals('TEST_CODE'));
        expect(state.status, equals(QRCodeStatus.preparing));
        expect(state.scanCount, equals(1));
        expect(state.firstScanTime, equals(now));
        expect(state.lastScanTime, equals(now));
      });

      test('should check status change timing correctly', () {
        final now = DateTime.now();
        final oldTime = now.subtract(Duration(seconds: 10));
        
        final state = QRCodeState(
          code: 'TIMING_TEST',
          status: QRCodeStatus.preparing,
          firstScanTime: oldTime,
          lastScanTime: oldTime,
        );

        expect(state.canChangeStatus(), isTrue);
        
        // Update to recent time
        state.lastScanTime = now;
        expect(state.canChangeStatus(), isFalse);
      });

      test('should identify preparing to ready transition', () {
        final now = DateTime.now();
        final state = QRCodeState(
          code: 'TRANSITION_TEST',
          status: QRCodeStatus.preparing,
          firstScanTime: now,
          lastScanTime: now,
          scanCount: 1,
        );

        expect(state.isPreparingToReadyTransition(), isTrue);
        
        state.scanCount = 2;
        expect(state.isPreparingToReadyTransition(), isFalse);
        
        state.status = QRCodeStatus.ready;
        expect(state.isPreparingToReadyTransition(), isFalse);
      });

      test('should have proper toString representation', () {
        final now = DateTime.now();
        final state = QRCodeState(
          code: 'STRING_TEST',
          status: QRCodeStatus.ready,
          firstScanTime: now,
          lastScanTime: now,
          scanCount: 2,
        );

        final stringRep = state.toString();
        expect(stringRep, contains('STRING_TEST'));
        expect(stringRep, contains('ready'));
        expect(stringRep, contains('scanCount: 2'));
      });
    });

    group('Performance Tests', () {
      setUp() async {
        await qrCodeService.initialize();
        qrCodeService.enableScanner();
      }

   test('should handle large number of QR codes efficiently', () async {
  await qrCodeService.initialize();
  // qrCodeService.setImmediateMode(true); // Enable immediate processing
  
  final stopwatch = Stopwatch()..start();
  
  // Generate 1000 UNIQUE QR codes
  for (int i = 0; i < 1000; i++) {
    final uniqueCode = 'PERF_TEST_CODE_$i'; // Make sure each is unique
    qrCodeService.simulateScan(uniqueCode);
  }
  
  stopwatch.stop();
  
  // Debug info
  print('Total QR codes: ${qrCodeService.getStats()['totalQRCodes']}');
  print('Preparing items: ${qrCodeService.preparingItems.length}');
  print('Ready items: ${qrCodeService.readyItems.length}');
  
  expect(qrCodeService.preparingItems.length, equals(1000));
  expect(stopwatch.elapsedMilliseconds, lessThan(5000));
});
    });
  });
}