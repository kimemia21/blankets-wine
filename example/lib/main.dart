import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/sdkinitializer.dart';
import 'package:blankets_and_wines_example/features/Stockist/Stockist.dart';
import 'package:blankets_and_wines_example/features/Test.dart';
import 'package:blankets_and_wines_example/features/cashier/cashier.dart';
import 'package:blankets_and_wines_example/services/QrcodeService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // sdkInitializer();
  // runApp(
  //   //  MyApp()
  //   // MyApp(),
  //   // QRScannerPage()
  //   //  StockistMainScreen()
  // );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:  StockistMainScreen()
      // QRCodeScannerScreen(),

  // QRCodeScannerScreen()
    );
  }
}


class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRCodeScannerScreen> createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  QRCodeVerificationService? _service;
  bool _isInitialized = false;
  String _statusMessage = 'Initializing scanner...';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      _service = QRCodeVerificationService();

      await _service!.initialize(
        onSuccess: (message) {
          _handleSuccess(message);
        },
        onError: _handleError,
        onItemScanned: _handleItemScanned,
        onStatusChanged: _handleStatusChanged,
      );

      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready to scan';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to initialize: $e';
      });
    }
  }

  void _handleSuccess(String message) async {
    _showAlert('Success', message, Colors.green);

    setState(() {
      _statusMessage = message;
    });
    if (_service!.isScanning) {
      await _service!.pauseScanning();
    } else {
      await _service!.resumeScanning();
    }
  }

  void _handleError(String error) {
    _showAlert('Error', error, Colors.red);
    setState(() {
      _statusMessage = 'Error: $error';
    });
  }

  void _handleItemScanned(ScannedItem item) {
    setState(() {
      _statusMessage = 'Scanned: ${item.code} (${item.status.name})';
    });
  }

  void _handleStatusChanged(ScannedItem item) {
    setState(() {
      _statusMessage = 'Status changed: ${item.code} → ${item.status.name}';
    });
  }

 

  void _showAlert(String title, String message, Color color) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                title == 'Success' ? Icons.check_circle : Icons.error,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_service != null)
            IconButton(
              icon: Icon(_service!.isScanning ? Icons.pause : Icons.play_arrow),
              onPressed: () async {
                if (_service!.isScanning) {
                  await _service!.pauseScanning();
                } else {
                  await _service!.resumeScanning();
                }
                setState(() {});
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $_statusMessage',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_service != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusCard(
                        'Total',
                        _service!.itemsCount.toString(),
                        Colors.blue,
                      ),
                      _buildStatusCard(
                        'Preparing',
                        _service!.preparingItemsCount.toString(),
                        Colors.orange,
                      ),
                      _buildStatusCard(
                        'Ready',
                        _service!.readyItemsCount.toString(),
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Camera view
          Expanded(
            child:
                _isInitialized && _service != null
                    ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 2),
                      ),
                      child: MobileScanner(
                        controller: _service!.controller,
                        onDetect: (result) {
                          // Detection is handled by the service
                        },
                      ),
                    )
                    : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(_statusMessage),
                        ],
                      ),
                    ),
          ),

          // Scanning overlay
          if (_isInitialized && _service != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Point the camera at a QR code to scan',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),

      // Control buttons
      bottomNavigationBar:
          _service != null
              ? Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_service!.isScanning) {
                          await _service!.pauseScanning();
                        } else {
                          await _service!.resumeScanning();
                        }
                        setState(() {});
                      },
                      icon: Icon(
                        _service!.isScanning ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(_service!.isScanning ? 'Pause' : 'Resume'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _service!.clearAllItems();
                        setState(() {
                          _statusMessage = 'All items cleared';
                        });
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showItemsList();
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('View Items'),
                    ),
                  ],
                ),
              )
              : null,
    );
  }

  Widget _buildStatusCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  void _showItemsList() {
    if (_service == null) return;

    final items = _service!.scannedItems.values.toList();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scanned Items (${items.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    items.isEmpty
                        ? const Center(child: Text('No items scanned yet'))
                        : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              child: ListTile(
                                title: Text(item.code),
                                subtitle: Text(
                                  'Status: ${item.status.name}\n'
                                  'First scan: ${_formatDateTime(item.firstScannedAt)}\n'
                                  'Last scan: ${_formatDateTime(item.lastScannedAt)}',
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        item.status == ItemStatus.ready
                                            ? Colors.green
                                            : Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.status.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }
}
