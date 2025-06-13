import 'package:blankets_and_wines_example/core/utils/initializers.dart';
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
}
