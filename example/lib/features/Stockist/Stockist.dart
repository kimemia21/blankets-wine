import 'dart:async';

import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/ordersStatus.dart';
import 'package:blankets_and_wines_example/data/MockData.dart';
import 'package:blankets_and_wines_example/data/services/QRCODEBCK.dart';
import 'package:blankets_and_wines_example/widgets/OrderCard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

enum OrderStatus { pending, preparing, ready  }

class StockistMainScreen extends StatefulWidget {
  @override
  _StockistMainScreenState createState() => _StockistMainScreenState();
}

class _StockistMainScreenState extends State<StockistMainScreen> {
  OrderStatus selectedFilter = OrderStatus.pending;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  // Initialize orders from mock data
  late List<StockistOrder> orders;

  final qrCodeService = QRCodeService();

  final _manualFocusNode = FocusNode();


void initState() {
  super.initState();
  orders = MockOrdersData.getOrders();

  qrCodeService.initialize();
  qrCodeService.onScan.listen((code) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAutoDismissingError(code);
      }
    });
    print('Scanned code: $code');
  });

  qrCodeService.onError.listen((error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAutoDismissingError(error);
      }
    });
  });

  qrCodeService.onReady.listen((ready) {
    if (ready) {
      print('QR Scanner ready');
    }
  });
  qrCodeService.simulateScan('TEST-CODE-123');
  qrCodeService.registerFocusNode(_manualFocusNode);
}

// Auto-dismissing success display with large, readable text
void _showAutoDismissingScanResult(String code) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(40),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.green, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Large success icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      SizedBox(height: 30),
                      
                      // Large title
                      Text(
                        'ORDER Number SCANNED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 40),
                      
                      // Extra large code display with high contrast
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: Text(
                          code,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'monospace',
                            letterSpacing: 4,
                            height: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      
                      // Status with countdown
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          '✓ SUCCESS - AUTO CLOSING',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  // Auto dismiss after 3 seconds
  Timer(Duration(seconds: 3), () {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      // _processScannedCode(code);
    }
  });
}

// Auto-dismissing error display
void _showAutoDismissingError(String error) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(40),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.red, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Large error icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      SizedBox(height: 30),
                      
                      // Large title
                      Text(
                        'ORDER ALREADY PROCESSED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 40),
                      
                      // Error message display
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[300]!, width: 2),
                        ),
                        child: Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      
                      // Status with countdown
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'ORDER IS ALREADY PROCESSED AND MARKED READY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  // Auto dismiss after 4 seconds (longer for error to be read)
  Timer(Duration(seconds: 4), () {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  });
}

// Alternative: Enhanced SnackBar for less intrusive display
void _showEnhancedSnackBar(String code) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR CODE SCANNED',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.green[700],
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
    ),
  );
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

    // // Show success message for completed orders
    // if (newStatus == OrderStatus.completed) {
      
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(
    //         'Order $orderNumber marked as complete!',
    //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    //       ),
    //       backgroundColor: BarPOSTheme.successColor,
    //       duration: Duration(seconds: 3),
    //     ),
    //   );
    // }
  }

  @override
  void dispose() {
    qrCodeService.dispose();

    _manualFocusNode.dispose();
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
        body: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: EdgeInsets.all(BarPOSTheme.spacingL),
              color: BarPOSTheme.accentDark,
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    margin: EdgeInsets.only(bottom: BarPOSTheme.spacingL),
                    child: TextField(
                      controller: searchController,
                         focusNode: _manualFocusNode,
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

                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 20,
                    child: Stack(children: 
                    [qrCodeService.buildScannerInput()]),
                  ),

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
                              backgroundColor:
                                  isSelected
                                      ? OrderStatusHelper.getStatusColor(status)
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
                                              ? Colors.white.withOpacity(0.3)
                                              : OrderStatusHelper.getStatusColor(
                                                status,
                                              ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.white,
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
      ),
    );
  }
}
