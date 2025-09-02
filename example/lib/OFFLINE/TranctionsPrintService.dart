import 'package:blankets_and_wines_example/data/models/Transaction.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TransactionReportPrinterService {
  static const MethodChannel _channel = MethodChannel('blankets_and_wines');

  /// Print a daily transaction report
  static Future<Map<String, dynamic>> printDailyReport(
    List<Transaction> transactions, {
    String? storeName,
    String? generatedBy,
  }) async {
    final reportData = _prepareDailyReportData(
      transactions,
      storeName: storeName,
      generatedBy: generatedBy,
    );

    try {
      final result = await _channel.invokeMethod(
        'printTransactionReport',
        reportData,
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'success': false, 'message': 'Failed to print report: $e'};
    }
  }

  /// Print a date range transaction report
  static Future<Map<String, dynamic>> printDateRangeReport(
    List<Transaction> transactions,
    DateTime startDate,
    DateTime endDate, {
    String? storeName,
    String? generatedBy,
  }) async {
    final reportData = _prepareDateRangeReportData(
      transactions,
      startDate,
      endDate,
      storeName: storeName,
      generatedBy: generatedBy,
    );

    try {
      final result = await _channel.invokeMethod(
        'printTransactionReport',
        reportData,
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'success': false, 'message': 'Failed to print report: $e'};
    }
  }

  /// Print a seller-specific transaction report
  static Future<Map<String, dynamic>> printSellerReport(
    List<Transaction> transactions,
    String sellerName, {
    String? storeName,
    String? generatedBy,
  }) async {
    final reportData = _prepareSellerReportData(
      transactions,
      sellerName,
      storeName: storeName,
      generatedBy: generatedBy,
    );

    try {
      final result = await _channel.invokeMethod(
        'printTransactionReport',
        reportData,
      );
      print("===============$reportData=============");
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'success': false, 'message': 'Failed to print report: $e'};
    }
  }

  /// Prepare daily report data
  static Map<String, dynamic> _prepareDailyReportData(
    List<Transaction> transactions, {
    String? storeName,
    String? generatedBy,
  }) {
    final today = DateTime.now();
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final dateTimeFormatter = DateFormat('dd/MM HH:mm');

    double totalSales = transactions.fold(0.0, (sum, t) => sum + t.total);
    double avgTransaction =
        transactions.isEmpty ? 0.0 : totalSales / transactions.length;

    // Group by seller
    Map<String, Map<String, dynamic>> sellerBreakdown = {};
    for (Transaction transaction in transactions) {
      if (!sellerBreakdown.containsKey(transaction.sellerName)) {
        sellerBreakdown[transaction.sellerName] = {
          'totalSales': 0.0,
          'transactionCount': 0,
        };
      }
      sellerBreakdown[transaction.sellerName]!['totalSales'] +=
          transaction.total;
      sellerBreakdown[transaction.sellerName]!['transactionCount']++;
    }

    // Convert seller breakdown to string values for printing
    Map<String, Map<String, String>> formattedSellerBreakdown = {};
    sellerBreakdown.forEach((seller, data) {
      formattedSellerBreakdown[seller] = {
        'totalSales': data['totalSales'].toStringAsFixed(2),
        'transactionCount': data['transactionCount'].toString(),
      };
    });

    return {
      'storeName': storeName ?? 'Blankets And Wine',
      'reportTitle': 'DAILY TRANSACTION REPORT',
      'dateRange': 'Today: ${dateFormatter.format(today)}',
      'generatedAt':
          '${dateFormatter.format(today)} ${timeFormatter.format(today)}',
      'totalTransactions': transactions.length.toString(),
      'totalSales': totalSales.toStringAsFixed(2),
      'averageTransaction': avgTransaction.toStringAsFixed(2),
      'generatedBy': generatedBy ?? 'Admin',
      'transactions':
          transactions
              .map(
                (t) => {
                  'id': t.id,
                  'dateTime': dateTimeFormatter.format(t.dateTime),
                  'seller': t.sellerName,
                  'amount': t.total.toStringAsFixed(2),
                },
              )
              .toList(),
      'sellerBreakdown': formattedSellerBreakdown,
    };
  }

  /// Prepare date range report data
  static Map<String, dynamic> _prepareDateRangeReportData(
    List<Transaction> transactions,
    DateTime startDate,
    DateTime endDate, {
    String? storeName,
    String? generatedBy,
  }) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final dateTimeFormatter = DateFormat('dd/MM HH:mm');
    final now = DateTime.now();

    double totalSales = transactions.fold(0.0, (sum, t) => sum + t.total);
    double avgTransaction =
        transactions.isEmpty ? 0.0 : totalSales / transactions.length;

    // Group by seller
    Map<String, Map<String, dynamic>> sellerBreakdown = {};
    for (Transaction transaction in transactions) {
      if (!sellerBreakdown.containsKey(transaction.sellerName)) {
        sellerBreakdown[transaction.sellerName] = {
          'totalSales': 0.0,
          'transactionCount': 0,
        };
      }
      sellerBreakdown[transaction.sellerName]!['totalSales'] +=
          transaction.total;
      sellerBreakdown[transaction.sellerName]!['transactionCount']++;
    }

    // Convert seller breakdown to string values
    Map<String, Map<String, String>> formattedSellerBreakdown = {};
    sellerBreakdown.forEach((seller, data) {
      formattedSellerBreakdown[seller] = {
        'totalSales': data['totalSales'].toStringAsFixed(2),
        'transactionCount': data['transactionCount'].toString(),
      };
    });

    return {
      'storeName': storeName ?? 'Blankets And Wine',
      'reportTitle': 'TRANSACTION REPORT',
      'dateRange':
          '${dateFormatter.format(startDate)} - ${dateFormatter.format(endDate)}',
      'generatedAt':
          '${dateFormatter.format(now)} ${timeFormatter.format(now)}',
      'totalTransactions': transactions.length.toString(),
      'totalSales': totalSales.toStringAsFixed(2),
      'averageTransaction': avgTransaction.toStringAsFixed(2),
      'generatedBy': generatedBy ?? 'Admin',
      'transactions':
          transactions
              .map(
                (t) => {
                  'id': t.id,
                  'dateTime': dateTimeFormatter.format(t.dateTime),
                  'seller': t.sellerName,
                  'amount': t.total.toStringAsFixed(2),
                },
              )
              .toList(),
      'sellerBreakdown': formattedSellerBreakdown,
    };
  }

  /// Prepare seller-specific report data
  static Map<String, dynamic> _prepareSellerReportData(
    List<Transaction> transactions,
    String sellerName, {
    String? storeName,
    String? generatedBy,
  }) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final dateTimeFormatter = DateFormat('dd/MM HH:mm');
    final now = DateTime.now();

    // Filter transactions for specific seller
    final sellerTransactions =
        transactions
            .where(
              (t) => t.sellerName.toLowerCase() == sellerName.toLowerCase(),
            )
            .toList();

    double totalSales = sellerTransactions.fold(0.0, (sum, t) => sum + t.total);
    double avgTransaction =
        sellerTransactions.isEmpty
            ? 0.0
            : totalSales / sellerTransactions.length;

    // Get date range from transactions
    String dateRange = '';
    if (sellerTransactions.isNotEmpty) {
      final dates = sellerTransactions.map((t) => t.dateTime).toList();
      dates.sort();
      final earliest = dates.first;
      final latest = dates.last;

      if (DateFormat('dd/MM/yyyy').format(earliest) ==
          DateFormat('dd/MM/yyyy').format(latest)) {
        dateRange = dateFormatter.format(earliest);
      } else {
        dateRange =
            '${dateFormatter.format(earliest)} - ${dateFormatter.format(latest)}';
      }
    }

    return {
      'storeName': storeName ?? 'Blankets And Wine',
      'reportTitle': 'SELLER REPORT: ${sellerName.toUpperCase()}',
      'dateRange': dateRange.isEmpty ? 'No transactions' : dateRange,
      'generatedAt':
          '${dateFormatter.format(now)} ${timeFormatter.format(now)}',
      'totalTransactions': sellerTransactions.length.toString(),
      'totalSales': totalSales.toStringAsFixed(2),
      'averageTransaction': avgTransaction.toStringAsFixed(2),
      'generatedBy': generatedBy ?? 'Admin',
      'transactions':
          sellerTransactions
              .map(
                (t) => {
                  'id': t.id,
                  'dateTime': dateTimeFormatter.format(t.dateTime),
                  'seller': t.sellerName,
                  'amount': t.total.toStringAsFixed(2),
                },
              )
              .toList(),
      'sellerBreakdown': null, // Not needed for individual seller report
    };
  }
}
