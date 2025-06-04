import 'package:blankets_and_wines_example/core/utils/ordersStatus.dart';
import 'package:blankets_and_wines_example/features/Stockist/Alerts/QRCodeAlerts.dart';
import 'package:blankets_and_wines_example/features/Stockist/Stockist.dart';
import 'package:flutter/material.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:intl/intl.dart';


class OrderCard extends StatelessWidget {
  final StockistOrder order;
  final Function(String, OrderStatus) onUpdateStatus;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onUpdateStatus,
  }) : super(key: key);

  void _completeOrder(String orderNumber) {
    onUpdateStatus(orderNumber, OrderStatus.completed);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: BarPOSTheme.spacingL),
      decoration: BoxDecoration(
        color: BarPOSTheme.secondaryDark,
        borderRadius: BorderRadius.circular(BarPOSTheme.radiusLarge),
        border: Border.all(
          color: OrderStatusHelper.getStatusColor(order.status).withOpacity(0.3),
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
              color: OrderStatusHelper.getStatusColor(order.status).withOpacity(0.1),
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
                    color: OrderStatusHelper.getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(
                      BarPOSTheme.radiusLarge,
                    ),
                  ),
                  child: Text(
                    OrderStatusHelper.getStatusText(order.status),
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
                ...order.items
                    .map(
                      (item) => Container(
                        margin: EdgeInsets.only(bottom: BarPOSTheme.spacingM),
                        padding: EdgeInsets.all(BarPOSTheme.spacingM),
                        decoration: BoxDecoration(
                          color: BarPOSTheme.accentDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(
                            BarPOSTheme.radiusMedium,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: BarPOSTheme.buttonColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  BarPOSTheme.radiusMedium,
                                ),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: BarPOSTheme.buttonColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  BarPOSTheme.radiusSmall,
                                ),
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
                      ),
                    )
                    .toList(),

                // Total and Actions
                Container(
                  padding: EdgeInsets.all(BarPOSTheme.spacingL),
                  decoration: BoxDecoration(
                    color: BarPOSTheme.buttonColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      BarPOSTheme.radiusMedium,
                    ),
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
                                onPressed: () => onUpdateStatus(
                                  order.orderNumber,
                                  OrderStatus.preparing,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  'Start Preparing',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ] else if (order.status == OrderStatus.preparing) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => onUpdateStatus(
                                  order.orderNumber,
                                  OrderStatus.ready,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: BarPOSTheme.successColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  'Mark Ready',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ] else if (order.status == OrderStatus.ready) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => QRScanDialog(orderNumber: order.orderNumber,
                                   onComplete:()=> _completeOrder(order.orderNumber)),
                                
                             
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
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
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