import 'dart:isolate';
import 'dart:async';
import 'package:blankets_and_wines_example/OFFLINE/CacheService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/data/models/DrinkCategory.dart';
import 'package:blankets_and_wines_example/data/models/Product.dart';
import 'package:blankets_and_wines_example/data/services/FetchGlobals.dart';
import 'package:blankets_and_wines_example/offline/Connectivty.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundSyncService {
  static const String SYNC_TASK = "syncData";
  static Timer? backgroundTimer;
  static bool _isSyncing = false;
  static DateTime? _lastSyncAttempt;
  static const int SYNC_COOLDOWN_SECONDS = 5;

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await _registerPeriodicTask();
    startBackgroundTimer();
  }

  static Future<void> _registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      SYNC_TASK,
      SYNC_TASK,
      frequency: Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  static void startBackgroundTimer() {
    backgroundTimer?.cancel();
    backgroundTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      bool result = await InternetConnection().hasInternetAccess;
      if (!result || _isSyncing) return;
      await _performBackgroundSync();
    });
  }

  static Future<void> _performBackgroundSync() async {
    if (_isSyncing) return;

    if (_lastSyncAttempt != null &&
        DateTime.now().difference(_lastSyncAttempt!).inSeconds < SYNC_COOLDOWN_SECONDS) {
      return;
    }

    _lastSyncAttempt = DateTime.now();

    try {
      final isProductsStale = await CacheService.isDataStale('products');
      final isCategoriesStale = await CacheService.isDataStale('categories');

      if (!isProductsStale && !isCategoriesStale) return;

      await syncNow();
    } catch (e) {
      print("Background sync check failed: $e");
    }
  }

  static Future<void> syncNow() async {
    if (_isSyncing) {
      print("Sync already in progress, skipping");
      return;
    }

    final connectivityService = ConnectivityService();

    if (!connectivityService.isConnected) {
      print("No internet connection, skipping sync");
      return;
    }

    _isSyncing = true;

    try {
      final data = await _syncInBackground();

      // ✅ Write to Hive (on root isolate)
      if (data['products'] != null) {
        await CacheService.cacheProducts(data['products']);
      }
      if (data['categories'] != null) {
        await CacheService.cacheCategories(data['categories']);
      }

      print("Background sync completed successfully");
    } catch (e) {
      print("Background sync failed: $e");
    } finally {
      _isSyncing = false;
    }
  }

  static Future<Map<String, dynamic>> _syncInBackground() async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_syncIsolate, receivePort.sendPort);

    final result = await receivePort.first as Map<String, dynamic>;
    receivePort.close();

    if (result['error'] != null) {
      throw Exception(result['error']);
    }
    return result;
  }

  /// Isolate entry point – only fetch & parse, no Hive or Flutter calls
  static void _syncIsolate(SendPort sendPort) async {
    try {
      List<Product>? products;
      List<DrinkCategory>? categories;

      // Fetch fresh products
      try {
        products = await fetchGlobal<Product>(
          getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
          fromJson: (json) => Product.fromJson(json),
          endpoint: 'products/${appUser.barId}',
        );
      } catch (e) {
        print("Failed to fetch products: $e");
      }

      // Fetch fresh categories
      try {
        categories = await fetchGlobal<DrinkCategory>(
          getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
          fromJson: (json) => DrinkCategory.fromJson(json),
          endpoint: 'ecom/categories',
        );
      } catch (e) {
        print("Failed to fetch categories: $e");
      }

      // ✅ Send raw data back to root isolate
      sendPort.send({
        'products': products,
        'categories': categories,
      });
    } catch (e) {
      sendPort.send({'error': e.toString()});
    }
  }

  static void dispose() {
    backgroundTimer?.cancel();
  }
}

// Workmanager dispatcher
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case BackgroundSyncService.SYNC_TASK:
        await BackgroundSyncService.syncNow();
        break;
    }
    return Future.value(true);
  });
}
