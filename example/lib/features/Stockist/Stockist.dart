import 'dart:async';

import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/ordersStatus.dart';
import 'package:blankets_and_wines_example/data/MockData.dart';
import 'package:blankets_and_wines_example/services/QrcodeService.dart';
import 'package:blankets_and_wines_example/widgets/OrderCard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Order model for stockist view
class StockistOrder {
  final String orderNumber;
  final DateTime timestamp;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final String cashierName;

  StockistOrder({
    required this.orderNumber,
    required this.timestamp,
    required this.items,
    required this.total,
    required this.status,
    required this.cashierName,
  });
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String category;
  final String emoji;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
    required this.emoji,
  });
}

enum OrderStatus { pending, preparing, ready }

class StockistMainScreen extends StatefulWidget {
  @override
  _StockistMainScreenState createState() => _StockistMainScreenState();
}

class _StockistMainScreenState extends State<StockistMainScreen> {
  OrderStatus selectedFilter = OrderStatus.pending;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  // QR Code Scanner related variables
  QRCodeVerificationService? _qrService;
  bool _isQRInitialized = false;
  String _qrStatusMessage = 'QR Scanner ready';
  bool _showQRScanner = false;

  // Initialize orders from mock data
  late List<StockistOrder> orders;

  @override
  void initState() {
    super.initState();
    orders = MockOrdersData.getOrders();
    _initializeQRService();
  }

  // Initialize QR Service
  Future<void> _initializeQRService() async {
    try {
      _qrService = QRCodeVerificationService();

      await _qrService!.initialize(
        onSuccess: (message) {
          _handleQRSuccess(message);
        },
        onError: _handleQRError,
        onItemScanned: _handleQRItemScanned,
        onStatusChanged: _handleQRStatusChanged,
      );

      setState(() {
        _isQRInitialized = true;
        _qrStatusMessage = 'QR Scanner ready';
      });
    } catch (e) {
      setState(() {
        _qrStatusMessage = 'Failed to initialize QR scanner: $e';
      });
    }
  }

  void _handleQRSuccess(String message) async {
    _showQRAlert('Success', message, Colors.green);
    
    setState(() {
      _qrStatusMessage = message;
    });
    
    if (_qrService!.isScanning) {
      await _qrService!.pauseScanning();
    } else {
      await _qrService!.resumeScanning();
    }
  }

  void _handleQRError(String error) {
    _showQRAlert('Error', error, Colors.red);
    setState(() {
      _qrStatusMessage = 'Error: $error';
    });
  }

  void _handleQRItemScanned(ScannedItem item) {
    setState(() {
      _qrStatusMessage = 'Scanned: ${item.code} (${item.status.name})';
    });
    
    // Try to find and update order based on scanned code
    _processScannedOrder(item.code);
  }

  void _handleQRStatusChanged(ScannedItem item) {
    setState(() {
      _qrStatusMessage = 'Status changed: ${item.code} → ${item.status.name}';
    });
  }

  void _processScannedOrder(String scannedCode) {
    // Find order by order number or any other identifier
    final orderIndex = orders.indexWhere(
      (order) => order.orderNumber == scannedCode,
    );
    
    if (orderIndex >= 0) {
      final currentOrder = orders[orderIndex];
      OrderStatus newStatus;
      
      // Progress the order to next status
      switch (currentOrder.status) {
        case OrderStatus.pending:
          newStatus = OrderStatus.preparing;
          break;
        case OrderStatus.preparing:
          newStatus = OrderStatus.ready;
          break;
        case OrderStatus.ready:
          newStatus = OrderStatus.ready; // Already at final status
          break;
      }
      
      updateOrderStatus(scannedCode, newStatus);
      
      _showQRAlert(
        'Order Updated', 
        'Order $scannedCode updated to ${OrderStatusHelper.getStatusText(newStatus)}',
        OrderStatusHelper.getStatusColor(newStatus)
      );
      
      // Close QR scanner after successful scan
      setState(() {
        _showQRScanner = false;
      });
    } else {
      _showQRAlert(
        'Order Not Found', 
        'No order found with code: $scannedCode',
        Colors.orange
      );
    }
  }

  void _showQRAlert(String title, String message, Color color) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: BarPOSTheme.secondaryDark,
          title: Row(
            children: [
              Icon(
                title == 'Success' ? Icons.check_circle : 
                title == 'Error' ? Icons.error : Icons.info,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: BarPOSTheme.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: BarPOSTheme.primaryText,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(
                  color: BarPOSTheme.buttonColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleQRScanner() {
    setState(() {
      _showQRScanner = !_showQRScanner;
    });
  }

  List<StockistOrder> get filteredOrders {
    return orders.where((order) {
      bool statusMatch = selectedFilter == order.status;
      bool searchMatch =
          order.orderNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.cashierName.toLowerCase().contains(searchQuery.toLowerCase());
      return statusMatch && searchMatch;
    }).toList();
  }

  int getOrderCountByStatus(OrderStatus status) {
    return orders.where((order) => order.status == status).length;
  }

  void updateOrderStatus(String orderNumber, OrderStatus newStatus) {
    setState(() {
      final orderIndex = orders.indexWhere(
        (order) => order.orderNumber == orderNumber,
      );
      if (orderIndex >= 0) {
        orders[orderIndex] = StockistOrder(
          orderNumber: orders[orderIndex].orderNumber,
          timestamp: orders[orderIndex].timestamp,
          items: orders[orderIndex].items,
          total: orders[orderIndex].total,
          status: newStatus,
          cashierName: orders[orderIndex].cashierName,
        );
      }
    });
  }

  Widget _buildQRScannerOverlay() {
    if (!_showQRScanner || !_isQRInitialized || _qrService == null) {
      return SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Column(
        children: [
          // QR Scanner Header
          Container(
            padding: EdgeInsets.all(BarPOSTheme.spacingL),
            color: BarPOSTheme.accentDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scan Order QR Code',
                  style: TextStyle(
                    color: BarPOSTheme.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_qrService != null)
                      IconButton(
                        icon: Icon(
                          _qrService!.isScanning ? Icons.pause : Icons.play_arrow,
                          color: BarPOSTheme.primaryText,
                          size: 32,
                        ),
                        onPressed: () async {
                          if (_qrService!.isScanning) {
                            await _qrService!.pauseScanning();
                          } else {
                            await _qrService!.resumeScanning();
                          }
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: BarPOSTheme.primaryText,
                        size: 32,
                      ),
                      onPressed: _toggleQRScanner,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Display
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(BarPOSTheme.spacingM),
            color: BarPOSTheme.secondaryDark,
            child: Text(
              'Status: $_qrStatusMessage',
              style: TextStyle(
                color: BarPOSTheme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Camera View
          Expanded(
            child: Container(
              margin: EdgeInsets.all(BarPOSTheme.spacingL),
              decoration: BoxDecoration(
                border: Border.all(color: BarPOSTheme.buttonColor, width: 3),
                borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
                child: MobileScanner(
                  controller: _qrService!.controller,
                  onDetect: (result) {
                    // Detection is handled by the service
                  },
                ),
              ),
            ),
          ),

          // Instructions
          Container(
            padding: EdgeInsets.all(BarPOSTheme.spacingL),
            child: Text(
              'Point the camera at an order QR code to scan and update status',
              style: TextStyle(
                color: BarPOSTheme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _qrService?.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: BarPOSTheme.primaryDark,
        appBar: AppBar(
          backgroundColor: BarPOSTheme.accentDark,
          elevation: 0,
          title: Text(
            'Stockist',
            style: TextStyle(
              color: BarPOSTheme.primaryText,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: BarPOSTheme.buttonColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(BarPOSTheme.radiusLarge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    color: BarPOSTheme.primaryText,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    DateFormat('HH:mm').format(DateTime.now()),
                    style: TextStyle(
                      color: BarPOSTheme.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Search and Filter Section
                Container(
                  padding: EdgeInsets.all(BarPOSTheme.spacingL),
                  color: BarPOSTheme.accentDark,
                  child: Column(
                    children: [
                      // Status Filter Tabs
                      Container(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: OrderStatus.values.length,
                          itemBuilder: (context, index) {
                            final status = OrderStatus.values[index];
                            final isSelected = selectedFilter == status;
                            final count = getOrderCountByStatus(status);

                            return Container(
                              margin: EdgeInsets.only(right: BarPOSTheme.spacingM),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedFilter = status;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? OrderStatusHelper.getStatusColor(status)
                                      : BarPOSTheme.secondaryDark,
                                  foregroundColor: isSelected
                                      ? Colors.white
                                      : BarPOSTheme.primaryText,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      BarPOSTheme.radiusLarge,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      OrderStatusHelper.getStatusText(status),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (count > 0) ...[
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white.withOpacity(0.3)
                                              : OrderStatusHelper.getStatusColor(status),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Search Bar
                      Container(
                        margin: EdgeInsets.only(bottom: BarPOSTheme.spacingL),
                        child: TextField(
                          controller: searchController,
                          style: TextStyle(
                            color: BarPOSTheme.primaryText,
                            fontSize: 20,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search orders...',
                            hintStyle: TextStyle(
                              color: BarPOSTheme.secondaryText,
                              fontSize: 20,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: BarPOSTheme.secondaryText,
                              size: 32,
                            ),
                            filled: true,
                            fillColor: BarPOSTheme.secondaryDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                BarPOSTheme.radiusMedium,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),

                      // QR Scanner Button
                      ElevatedButton(
                        onPressed: _isQRInitialized ? _toggleQRScanner : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showQRScanner 
                              ? Colors.red 
                              : BarPOSTheme.buttonColor,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(BarPOSTheme.radiusLarge),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showQRScanner ? Icons.close : Icons.qr_code_scanner, 
                              size: 24
                            ),
                            SizedBox(width: 8),
                            Text(
                              _showQRScanner ? 'Close Scanner' : 'Scan Order',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Orders List
                Expanded(
                  child: filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: BarPOSTheme.secondaryText,
                                size: 80,
                              ),
                              SizedBox(height: BarPOSTheme.spacingL),
                              Text(
                                'No ${OrderStatusHelper.getStatusText(selectedFilter).toLowerCase()} orders',
                                style: TextStyle(
                                  color: BarPOSTheme.secondaryText,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(BarPOSTheme.spacingL),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return OrderCard(
                              order: order,
                              onUpdateStatus: updateOrderStatus,
                            );
                          },
                        ),
                ),
              ],
            ),

            // QR Scanner Overlay
            if (_showQRScanner) _buildQRScannerOverlay(),
          ],
        ),
      ),
    );
  }
}