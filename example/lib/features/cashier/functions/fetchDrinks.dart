import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/data/models/Category.dart';
import 'package:blankets_and_wines_example/data/models/DrinkItem.dart';
import 'package:blankets_and_wines_example/data/services/FetchGlobals.dart';

class CashierFunctions {
  static final List<String> categories = [
    'All',
    'Whiskey',
    'Premium Whiskey',
    'Vodka',
    'Premium Vodka',
    'Brandy',
    'Premium Brandy',
    'Champagne',
    'Premium Champagne',
    'Wine',
    'Tequila',
    'Premium Tequila',
    'Rum',
    'Local Premium',
    'Liqueur',
  ];

  static Future<List<DrinkItem>> fetchDrinks(String endpoint) async {
    //  because the products endpoint is not ready  we will use the memory map
    try {
      final drinks = await fetchGlobal<DrinkItem>(
        getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
        fromJson: (json) => DrinkItem.fromJson(json),
        endpoint: endpoint,
      );
      print(drinks);
      return drinks;
    } on Exception catch (e) {
      throw Exception("fetch Drinks error $e");
    }
  }

  static Future<List<DrinnksCategory>> fetchCategories(String endpoint) async {
    try {
      final categories = await fetchGlobal<DrinnksCategory>(
        getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
        fromJson: (json) => DrinnksCategory.fromJson(json),
        endpoint: endpoint,
      );
      print(categories);
      return categories;
    } on Exception catch (e) {
      throw Exception("fetch Categories error $e");
    }
  }

  static Future<bool> payOrder(Map<String, dynamic> data) async {
    final resp = await comms.postRequest(
      endpoint: "orders/order/pay",
      data: data,
    );
    print("#############################$resp################################");
    if (resp["rsp"]["success"]) {
      return true;
    } else {
      ToastService.showError(resp["rsp"]["message"]);

      return false;
    }
  }
}
