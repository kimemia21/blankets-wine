import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final TextEditingController _qrDataController = TextEditingController();
  bool _isScanning = false;
  String _statusMessage = 'Ready to scan';
  String _scannedData = ''; // Final variable to store scanned data

  @override
  void dispose() {
    _qrDataController.dispose();
    super.dispose();
  }

  // Future<void> _scanQRCode() async {
  //   if (_isScanning) return;

  //   setState(() {
  //     _isScanning = true;
  //     _statusMessage = 'Scanning QR code...';
  //   });

  //   try {
  //     // Scan QR code with 5 second timeout
  //     String scannedData = await SmartposPlugin.scanQRCode(timeoutSeconds: 10);
      
  //     setState(() {
  //       _scannedData = scannedData; // Save to final variable
  //       _qrDataController.text = _scannedData; // Display in text field
        
  //      print('Scanned data: ${_qrDataController.text}');
  //       _statusMessage = 'QR code scanned successfully!';
  //     });

  //     // Show success message
      

  //     // You can now use _scannedData variable anywhere in your app
  //     print('Final scanned data: $_scannedData');

  //   } catch (e) {
  //     setState(() {
  //       _statusMessage = 'Scan failed: ${e.toString()}';
  //     });

    
  //   } finally {
  //     setState(() {
  //       _isScanning = false;
  //     });
  //   }
  // }

  // Future<void> _getLastScannedData() async {
  //   try {
  //     String lastData = await SmartposPlugin.getLastScannedData();
  //     setState(() {
  //       _scannedData = lastData; // Save to final variable
  //       _qrDataController.text = _scannedData; // Display in text field
  //       _statusMessage = lastData.isEmpty ? 'No previous scan data' : 'Last scan data retrieved';
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _statusMessage = 'Failed to get last scan data: ${e.toString()}';
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('QR Code Scanner'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status message
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Display final scanned data (read-only)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final Scanned Data:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _scannedData.isEmpty ? 'No data scanned yet' : _scannedData,
                      style: TextStyle(
                        fontSize: 14,
                        color: _scannedData.isEmpty ? Colors.grey : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Text field to display scanned data (editable for testing)
              TextField(
                controller: _qrDataController,
                decoration: InputDecoration(
                  labelText: 'Scanned QR Code Data (Editable)',
                  border: OutlineInputBorder(),
                  hintText: 'QR code data will appear here...',
                ),
                maxLines: 1,
                readOnly: false,
                onChanged: (value) {
                  setState(() {
                    // Update the scanned data variable when text changes
                    _scannedData = value;
                    _statusMessage = 'QR code data updated in text field';
                  });
                  // Note: This won't change _scannedData variable
                  // Only scanning will update _scannedData
                },
              ),
              
              SizedBox(height: 20),
              TextField(
                controller: TextEditingController(),
                decoration: InputDecoration(
                  labelText: 'Final Scanned Data (Read-Only)',
                  border: OutlineInputBorder(),
                  hintText: 'This is the final scanned data',
                ),
                readOnly: false,
              ),
              
              // Scan button
              ElevatedButton.icon(
                onPressed: _isScanning ? null :
                null,
                //  _scanQRCode,
                icon: _isScanning 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.qr_code_scanner),
                label: Text(_isScanning ? 'Scanning...' : 'Scan QR Code'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
              
              SizedBox(height: 12),
              
              // Get last scanned data button
              // OutlinedButton.icon(
              //   onPressed: _getLastScannedData,
              //   icon: Icon(Icons.history),
              //   label: Text('Get Last Scanned Data'),
              //   style: OutlinedButton.styleFrom(
              //     padding: EdgeInsets.symmetric(vertical: 16),
              //     textStyle: TextStyle(fontSize: 16),
              //   ),
              // ),
              
              SizedBox(height: 12),
              
              // Clear button (only clears display, not the final scanned data)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _qrDataController.clear();
                    _statusMessage = 'Ready to scan';
                    // Note: _scannedData remains unchanged
                  });
                },
                icon: Icon(Icons.clear),
                label: Text('Clear Display'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Getter method to access the final scanned data from outside this widget
  String get finalScannedData => _scannedData;
}

// Custom exception class for SmartPos errors
class SmartPosException implements Exception {
  final String message;
  SmartPosException(this.message);
  
  @override
  String toString() => message;
}