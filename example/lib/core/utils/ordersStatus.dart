import 'package:blankets_and_wines_example/features/Stockist/Stockist.dart';
import 'package:flutter/material.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';


class OrderStatusHelper {
  static Color getStatusColor(OrderStatus status) {
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

  static String getStatusText(OrderStatus status) {
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
}