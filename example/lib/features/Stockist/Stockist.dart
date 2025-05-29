import 'package:blankets_and_wines_example/core/theme/theme.dart';
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

enum OrderStatus { pending, preparing, ready, completed }

class StockistMainScreen extends StatefulWidget {
  @override
  _StockistMainScreenState createState() => _StockistMainScreenState();
}

class _StockistMainScreenState extends State<StockistMainScreen> {
  OrderStatus selectedFilter = OrderStatus.pending;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  // Mock orders data - in real app, this would come from your backend
  List<StockistOrder> orders = [
    StockistOrder(
      orderNumber: "ORD-001234",
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      cashierName: "Sarah M.",
      total: 23.50,
      status: OrderStatus.pending,
      items: [
        OrderItem(name: "Corona Extra", quantity: 2, price: 11.00, category: "Beer", emoji: "🍺"),
        OrderItem(name: "Mojito", quantity: 1, price: 9.00, category: "Cocktails", emoji: "🍹"),
        OrderItem(name: "Coca Cola", quantity: 1, price: 3.50, category: "Non-Alcoholic", emoji: "🥤"),
      ],
    ),
    StockistOrder(
      orderNumber: "ORD-001235",
      timestamp: DateTime.now().subtract(Duration(minutes: 8)),
      cashierName: "Mike R.",
      total: 45.00,
      status: OrderStatus.preparing,
      items: [
        OrderItem(name: "Whiskey", quantity: 2, price: 16.00, category: "Spirits", emoji: "🥃"),
        OrderItem(name: "Cabernet Sauvignon", quantity: 1, price: 12.00, category: "Wine", emoji: "🍷"),
        OrderItem(name: "Old Fashioned", quantity: 1, price: 11.00, category: "Cocktails", emoji: "🥃"),
        OrderItem(name: "Water", quantity: 3, price: 6.00, category: "Non-Alcoholic", emoji: "💧"),
      ],
    ),
    StockistOrder(
      orderNumber: "ORD-001236",
      timestamp: DateTime.now().subtract(Duration(minutes: 12)),
      cashierName: "Lisa K.",
      total: 18.50,
      status: OrderStatus.ready,
      items: [
        OrderItem(name: "Margarita", quantity: 1, price: 9.50, category: "Cocktails", emoji: "🍹"),
        OrderItem(name: "Orange Juice", quantity: 2, price: 7.00, category: "Non-Alcoholic", emoji: "🧃"),
        OrderItem(name: "Heineken", quantity: 1, price: 6.00, category: "Beer", emoji: "🍺"),
      ],
    ),
  ];

  List<StockistOrder> get filteredOrders {
    return orders.where((order) {
      bool statusMatch = selectedFilter == order.status;
      bool searchMatch = order.orderNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        order.cashierName.toLowerCase().contains(searchQuery.toLowerCase());
      return statusMatch && searchMatch;
    }).toList();
  }

  int getOrderCountByStatus(OrderStatus status) {
    return orders.where((order) => order.status == status).length;
  }

  Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return BarPOSTheme.errorColor;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
        return BarPOSTheme.successColor;
      case OrderStatus.completed:
        return BarPOSTheme.secondaryText;
    }
  }

  String getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return "NEW";
      case OrderStatus.preparing:
        return "PREPARING";
      case OrderStatus.ready:
        return "READY";
      case OrderStatus.completed:
        return "COMPLETED";
    }
  }

  void updateOrderStatus(String orderNumber, OrderStatus newStatus) {
    setState(() {
      final orderIndex = orders.indexWhere((order) => order.orderNumber == orderNumber);
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

  void _showQRScanDialog(String orderNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: BarPOSTheme.secondaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BarPOSTheme.radiusLarge),
          ),
          title: Text(
            'Scan QR Code',
            style: TextStyle(
              color: BarPOSTheme.primaryText,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
                ),
                child: Center(
                  child: Icon(
                    Icons.qr_code_scanner,
                    size: 120,
                    color: BarPOSTheme.accentDark,
                  ),
                ),
              ),
              SizedBox(height: BarPOSTheme.spacingL),
              Text(
                'Order: $orderNumber',
                style: TextStyle(
                  color: BarPOSTheme.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: BarPOSTheme.spacingS),
              Text(
                'Scan the QR code to mark this order as complete',
                style: TextStyle(
                  color: BarPOSTheme.secondaryText,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: BarPOSTheme.secondaryText,
                  fontSize: 18,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeOrder(orderNumber);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BarPOSTheme.successColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Mark Complete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _completeOrder(String orderNumber) {
    updateOrderStatus(orderNumber, OrderStatus.completed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order $orderNumber marked as complete!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: BarPOSTheme.successColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarPOSTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BarPOSTheme.accentDark,
        elevation: 0,
        title: Text(
          'Stockist Dashboard',
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
                Icon(Icons.access_time, color: BarPOSTheme.primaryText, size: 24),
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
                        borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
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
                            backgroundColor: isSelected 
                                ? getStatusColor(status)
                                : BarPOSTheme.secondaryDark,
                            foregroundColor: isSelected 
                                ? Colors.white
                                : BarPOSTheme.primaryText,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(BarPOSTheme.radiusLarge),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                getStatusText(status),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (count > 0) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? Colors.white.withOpacity(0.3)
                                        : getStatusColor(status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.white,
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
                          'No ${getStatusText(selectedFilter).toLowerCase()} orders',
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
                      return _buildOrderCard(order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(StockistOrder order) {
    return Container(
      margin: EdgeInsets.only(bottom: BarPOSTheme.spacingL),
      decoration: BoxDecoration(
        color: BarPOSTheme.secondaryDark,
        borderRadius: BorderRadius.circular(BarPOSTheme.radiusLarge),
        border: Border.all(
          color: getStatusColor(order.status).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order Header
          Container(
            padding: EdgeInsets.all(BarPOSTheme.spacingL),
            decoration: BoxDecoration(
              color: getStatusColor(order.status).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(BarPOSTheme.radiusLarge),
                topRight: Radius.circular(BarPOSTheme.radiusLarge),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: TextStyle(
                        color: BarPOSTheme.primaryText,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: BarPOSTheme.secondaryText,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          order.cashierName,
                          style: TextStyle(
                            color: BarPOSTheme.secondaryText,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          color: BarPOSTheme.secondaryText,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(order.timestamp),
                          style: TextStyle(
                            color: BarPOSTheme.secondaryText,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(BarPOSTheme.radiusLarge),
                  ),
                  child: Text(
                    getStatusText(order.status),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Order Items
          Padding(
            padding: EdgeInsets.all(BarPOSTheme.spacingL),
            child: Column(
              children: [
                ...order.items.map((item) => Container(
                  margin: EdgeInsets.only(bottom: BarPOSTheme.spacingM),
                  padding: EdgeInsets.all(BarPOSTheme.spacingM),
                  decoration: BoxDecoration(
                    color: BarPOSTheme.accentDark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: BarPOSTheme.buttonColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
                        ),
                        child: Center(
                          child: Text(
                            item.emoji,
                            style: TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      SizedBox(width: BarPOSTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                color: BarPOSTheme.primaryText,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              item.category,
                              style: TextStyle(
                                color: BarPOSTheme.secondaryText,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: BarPOSTheme.buttonColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(BarPOSTheme.radiusSmall),
                        ),
                        child: Text(
                          'x${item.quantity}',
                          style: TextStyle(
                            color: BarPOSTheme.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: BarPOSTheme.spacingM),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: BarPOSTheme.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )).toList(),

                // Total and Actions
                Container(
                  padding: EdgeInsets.all(BarPOSTheme.spacingL),
                  decoration: BoxDecoration(
                    color: BarPOSTheme.buttonColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(
                              color: BarPOSTheme.primaryText,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '\$${order.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: BarPOSTheme.primaryText,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: BarPOSTheme.spacingL),
                      Row(
                        children: [
                          if (order.status == OrderStatus.pending) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => updateOrderStatus(order.orderNumber, OrderStatus.preparing),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  'Start Preparing',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ] else if (order.status == OrderStatus.preparing) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => updateOrderStatus(order.orderNumber, OrderStatus.ready),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: BarPOSTheme.successColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  'Mark Ready',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ] else if (order.status == OrderStatus.ready) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showQRScanDialog(order.orderNumber),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: BarPOSTheme.buttonColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code_scanner, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Scan QR to Complete',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

