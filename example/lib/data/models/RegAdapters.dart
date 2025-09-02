import 'package:blankets_and_wines_example/data/models/ProductChangeLog.dart';
import 'package:blankets_and_wines_example/data/models/Restock.dart';
import 'package:blankets_and_wines_example/data/models/Transaction.dart';
import 'package:blankets_and_wines_example/data/models/TransactionsItem.dart';
import 'package:hive/hive.dart';

// Import all generated adapters
import 'DrinkCategory.dart';
import 'DrinkItem.dart';
import 'DrinkOrder.dart';
import 'Product.dart';
import 'ProductCategory.dart';
import 'UserData.dart';

class HiveAdapters {
  static void registerAll() {
    if (!Hive.isAdapterRegistered(DrinkCategoryAdapter().typeId)) {
      Hive.registerAdapter(DrinkCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(DrinkItemAdapter().typeId)) {
      Hive.registerAdapter(DrinkItemAdapter());
    }
    if (!Hive.isAdapterRegistered(DrinkOrderAdapter().typeId)) {
      Hive.registerAdapter(DrinkOrderAdapter());
    }
    if (!Hive.isAdapterRegistered(ProductAdapter().typeId)) {
      Hive.registerAdapter(ProductAdapter());
    }
    if (!Hive.isAdapterRegistered(ProductCategoryAdapter().typeId)) {
      Hive.registerAdapter(ProductCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(UserDataAdapter().typeId)) {
      Hive.registerAdapter(UserDataAdapter());
    }
    if (!Hive.isAdapterRegistered(RestockAdapter().typeId)) {
      Hive.registerAdapter(RestockAdapter());
    }
    // MISSING: Add ProductChangeLog adapter
    if (!Hive.isAdapterRegistered(ProductChangeLogAdapter().typeId)) {
      Hive.registerAdapter(ProductChangeLogAdapter());
    }
    if (!Hive.isAdapterRegistered(TransactionAdapter().typeId)) {
      Hive.registerAdapter(TransactionAdapter());
    } 
    if (!Hive.isAdapterRegistered(TransactionItemAdapter().typeId)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  }

  static Future<void> openAllBoxes() async {
    await Hive.openBox<DrinkCategory>('drinkCategories');
    await Hive.openBox<DrinkItem>('drinkItems');
    await Hive.openBox<DrinkOrder>('drinkOrders');
    await Hive.openBox<Product>('products');
    await Hive.openBox<ProductCategory>('productCategories');
    await Hive.openBox<UserData>('users');
    await Hive.openBox<Restock>('restock');
    await Hive.openBox<ProductChangeLog>('productChangeLogs');

    await Hive.openBox('metadata');
    await Hive.openBox<Transaction>('transactions');
    await Hive.openBox<TransactionItem>('transactionItems');
    

  }

  static Future<void> init() async {
    registerAll();
    await openAllBoxes();
  }
}