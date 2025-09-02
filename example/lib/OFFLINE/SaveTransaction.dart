import 'package:blankets_and_wines_example/data/models/Transaction.dart';
import 'package:hive/hive.dart';


class TransactionService {
  static const String _boxName = 'transactions';
  
  static Box<Transaction>? _box;
  
  // Initialize the box
  static Future<void> init() async {
    _box = await Hive.openBox<Transaction>(_boxName);
  }
  
  // Save a transaction
  static Future<void> saveTransaction(Transaction transaction) async {
    await _box?.put(transaction.id, transaction);
  }
  
  // Get all transactions
  static List<Transaction> getAllTransactions() {
    return _box?.values.toList() ?? [];
  }
  
  // Get transactions by date range
  static List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _box?.values.where((transaction) {
      return transaction.dateTime.isAfter(start.subtract(Duration(days: 1))) &&
             transaction.dateTime.isBefore(end.add(Duration(days: 1)));
    }).toList() ?? [];
  }
  
  // Get transactions by seller
  static List<Transaction> getTransactionsBySeller(String sellerName) {
    return _box?.values.where((transaction) {
      return transaction.sellerName.toLowerCase() == sellerName.toLowerCase();
    }).toList() ?? [];
  }
  
  // Get transaction by ID
  static Transaction? getTransactionById(String id) {
    return _box?.get(id);
  }
  
  // Delete transaction
  static Future<void> deleteTransaction(String id) async {
    await _box?.delete(id);
  }
  
  // Get today's transactions
  static List<Transaction> getTodayTransactions() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    return getTransactionsByDateRange(startOfDay, endOfDay);
  }
  
  // Calculate total sales for a date range
  static double getTotalSales(DateTime start, DateTime end) {
    final transactions = getTransactionsByDateRange(start, end);
    return transactions.fold(0.0, (sum, transaction) => sum + transaction.total);
  }
  
  // Get transaction count
  static int getTransactionCount() {
    return _box?.length ?? 0;
  }
}