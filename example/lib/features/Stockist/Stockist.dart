import 'dart:async';

import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/core/utils/ordersStatus.dart';
import 'package:blankets_and_wines_example/core/utils/sdkinitializer.dart';
import 'package:blankets_and_wines_example/data/services/QrcodeService.dart';
import 'package:blankets_and_wines_example/widgets/OrderCard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Updated Order model for real API data
class StockistOrder {
  final int id;
  final String orderNumber;
  final DateTime timestamp;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final String cashierName;
  final String barName;
  final int paymentStatus;
  final int shopId;
  final int cashierId;

  StockistOrder({
    required this.id,
    required this.orderNumber,
    required this.timestamp,
    required this.items,
    required this.total,
    required this.status,
    required this.cashierName,
    required this.barName,
    required this.paymentStatus,
    required this.shopId,
    required this.cashierId,
  });

  // Factory constructor to create StockistOrder from API data
  factory StockistOrder.fromJson(Map<String, dynamic> json) {
    return StockistOrder(
      id: json['id'] ?? 0,
      orderNumber: json['order_no'] ?? '',
      timestamp: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      items: [], // Will be populated separately when order details are fetched
      total: double.parse(json['total']?.toString() ?? '0.0'),
      status: _parseOrderStatus(json['order_status']),
      cashierName: '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}',
      barName: json['bar'] ?? '',
      paymentStatus: json['payment_status'] ?? 0,
      shopId: json['shop_id'] ?? 0,
      cashierId: json['cashier_id'] ?? 0,
    );
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      default:
        return OrderStatus.pending;
    }
  }

  // Convert to JSON for API updates
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_no': orderNumber,
      'total': total,
      'shop_id': shopId,
      'payment_status': paymentStatus,
      'order_status': status.name,
      'cashier_id': cashierId,
      'created_at': timestamp.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'bar': barName,
      'first_name': cashierName.split(' ').first,
      'last_name':
          cashierName.split(' ').length > 1 ? cashierName.split(' ').last : '',
    };
  }
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

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: double.parse(json['price']?.toString() ?? '0.0'),
      category: json['category'] ?? '',
      emoji: json['emoji'] ?? '🍺',
    );
  }
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
  late IO.Socket socket;

  // QR Code Scanner related variables
  QRCodeVerificationService? _qrService;
  bool _isQRInitialized = false;
  String _qrStatusMessage = 'QR Scanner ready';
  bool _showQRScanner = false;

  // Updated orders list to handle real data
  List<StockistOrder> orders = [];
  List<Map<String, dynamic>> lastSocketData = [];

  void connectAndListen() {
    print("Connecting to socket server...");

    socket = IO.io(
      'ws://167.99.15.36:8080',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .build(),
    );

    socket.onConnect((_) {
      print('Connected to server');
      socket.emit('join_shop_room', {"barId": appUser.barId});
    });

    socket.on('shop_orders', (data) {
      print('Received order data: $data');
      if (data != null && data['data'] != null) {
        _handleSocketOrderData(data['data']);
      } else {
        print('No order data received');
      }
    });

    socket.onError((error) {
      print('Socket error: $error');
    });

    socket.onDisconnect((_) {
      print('Disconnected from server');
    });
  }

  void _handleSocketOrderData(List<dynamic> newOrderData) {
    try {
      List<Map<String, dynamic>> currentData = List<Map<String, dynamic>>.from(
        newOrderData,
      );

      // Check if payload is greater than previous
      bool shouldPrintReceipt = _shouldPrintReceipt(currentData);

      // Update orders list
      setState(() {
        orders =
            currentData
                .map((orderJson) => StockistOrder.fromJson(orderJson))
                .toList();
      });

      // Print receipt for new orders if needed
      if (shouldPrintReceipt) {
        _printReceiptsForNewOrders(currentData);
      }

      // Update last data reference
      lastSocketData = List.from(currentData);

      print('Orders updated: ${orders.length} orders loaded');
    } catch (e) {
      print('Error processing socket data: $e');
    }
  }

  bool _shouldPrintReceipt(List<Map<String, dynamic>> currentData) {
    // If this is the first data load, don't print
    if (lastSocketData.isEmpty) return false;

    // Check if current payload has more orders than last payload
    if (currentData.length > lastSocketData.length) return true;

    // Check if any order IDs are new
    Set<int> lastIds =
        lastSocketData.map((order) => order['id'] as int).toSet();
    Set<int> currentIds =
        currentData.map((order) => order['id'] as int).toSet();

    return currentIds.difference(lastIds).isNotEmpty;
  }

  Future<void> _printReceiptsForNewOrders(
    List<Map<String, dynamic>> currentData,
  ) async {
    try {
      // Get new order IDs
      Set<int> lastIds =
          lastSocketData.map((order) => order['id'] as int).toSet();
      List<Map<String, dynamic>> newOrders =
          currentData.where((order) => !lastIds.contains(order['id'])).toList();

      // Print receipt for each new order
      for (var orderData in newOrders) {
        await _printSingleReceipt(orderData);
      }

      if (newOrders.isNotEmpty) {
        _showReceiptAlert(
          '${newOrders.length} new order(s) printed successfully!',
        );
      }
    } catch (e) {
      print('Error printing receipts: $e');
      _showReceiptAlert('Error printing receipts: $e', isError: true);
    }
  }

  Future<void> _printSingleReceipt(Map<String, dynamic> orderData) async {
    try {
      sdkInitializer(); // Create items list - you may need to fetch detailed items from another API
      List<Map<String, dynamic>> items = [
        {
          "name": "Order Items", // Placeholder - replace with actual items
          "quantity": "1",
          "price": orderData['total'].toString(),
        },
      ];

      double total = double.parse(orderData['total'].toString());
      double subtotal = total * 0.87; // Assuming 13% tax
      double tax = total - subtotal;

      await SmartposPlugin.printReceipt({
        "receiptType":
            userData.userRole == "cashier"
                ? "Sale Receipt"
                : "Stockist Receipt",
        "storeName": orderData['bar'] ?? "Blankets Bar",
        "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "time": DateFormat('HH:mm:ss').format(DateTime.now()),
        "orderNumber": orderData['order_no'] ?? '',
        "items": items,
        "subtotal": subtotal.toStringAsFixed(2),
        "tax": tax.toStringAsFixed(2),
        "total": total.toStringAsFixed(2),
        "paymentMethod": "Mpesa",
      });

      print('Receipt printed for order: ${orderData['order_no']}');
    } catch (e) {
      print('Error printing receipt for order ${orderData['order_no']}: $e');
      rethrow;
    }
  }

  void _showReceiptAlert(String message, {bool isError = false}) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: BarPOSTheme.secondaryDark,
          title: Row(
            children: [
              Icon(
                isError ? Icons.error : Icons.print,
                color: isError ? Colors.red : Colors.green,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                isError ? 'Print Error' : 'Receipt Printed',
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
            style: TextStyle(color: BarPOSTheme.primaryText, fontSize: 16),
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

  void testEmitOrder() {
    print("Testing order emission...");
    socket.emit('order_created', {"barId": appUser.barId});
  }

  @override
  void initState() {
    super.initState();
    _initializeQRService();
    connectAndListen();

    // Test emit after 5 seconds
    Future.delayed(Duration(seconds: 5)).then((_) {
      testEmitOrder();
    });
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

    _processScannedOrder(item.code);
  }

  void _handleQRStatusChanged(ScannedItem item) {
    setState(() {
      _qrStatusMessage = 'Status changed: ${item.code} → ${item.status.name}';
    });
  }

  void _processScannedOrder(String scannedCode) {
    final orderIndex = orders.indexWhere(
      (order) => order.orderNumber == scannedCode,
    );

    if (orderIndex >= 0) {
      final currentOrder = orders[orderIndex];
      OrderStatus newStatus;

      switch (currentOrder.status) {
        case OrderStatus.pending:
          newStatus = OrderStatus.preparing;
          break;
        case OrderStatus.preparing:
          newStatus = OrderStatus.ready;
          break;
        case OrderStatus.ready:
          newStatus = OrderStatus.ready;
          break;
      }

      updateOrderStatus(scannedCode, newStatus);

      _showQRAlert(
        'Order Updated',
        'Order $scannedCode updated to ${OrderStatusHelper.getStatusText(newStatus)}',
        OrderStatusHelper.getStatusColor(newStatus),
      );

      setState(() {
        _showQRScanner = false;
      });
    } else {
      _showQRAlert(
        'Order Not Found',
        'No order found with code: $scannedCode',
        Colors.orange,
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
                title == 'Success'
                    ? Icons.check_circle
                    : title == 'Error'
                    ? Icons.error
                    : Icons.info,
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
            style: TextStyle(color: BarPOSTheme.primaryText, fontSize: 16),
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
        final oldOrder = orders[orderIndex];
        orders[orderIndex] = StockistOrder(
          id: oldOrder.id,
          orderNumber: oldOrder.orderNumber,
          timestamp: oldOrder.timestamp,
          items: oldOrder.items,
          total: oldOrder.total,
          status: newStatus,
          cashierName: oldOrder.cashierName,
          barName: oldOrder.barName,
          paymentStatus: oldOrder.paymentStatus,
          shopId: oldOrder.shopId,
          cashierId: oldOrder.cashierId,
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
                          _qrService!.isScanning
                              ? Icons.pause
                              : Icons.play_arrow,
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
    socket.disconnect();
    socket.dispose();
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
            'Stockist - ${orders.length} Orders',
            style: TextStyle(
              color: BarPOSTheme.primaryText,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton.filled(
              onPressed: () async {
                testEmitOrder();
              },
              icon: Icon(Icons.refresh),
              tooltip: 'Test Socket Connection',
            ),
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
                              margin: EdgeInsets.only(
                                right: BarPOSTheme.spacingM,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedFilter = status;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isSelected
                                          ? OrderStatusHelper.getStatusColor(
                                            status,
                                          )
                                          : BarPOSTheme.secondaryDark,
                                  foregroundColor:
                                      isSelected
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
                                          color:
                                              isSelected
                                                  ? Colors.white.withOpacity(
                                                    0.3,
                                                  )
                                                  : OrderStatusHelper.getStatusColor(
                                                    status,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                          backgroundColor:
                              _showQRScanner
                                  ? Colors.red
                                  : BarPOSTheme.buttonColor,
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
                            Icon(
                              _showQRScanner
                                  ? Icons.close
                                  : Icons.qr_code_scanner,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              _showQRScanner ? 'Close Scanner' : 'Scan Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
                  child:
                      filteredOrders.isEmpty
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
