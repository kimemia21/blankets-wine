import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/data/models/DrinkItem.dart';
import 'package:blankets_and_wines_example/data/services/FetchGlobals.dart';

final List<String> categories = [
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
final List<DrinkItem> drinks = [
  // Mid-Range Whiskeys (3500-8000)
  DrinkItem(
    id: '1',
    name: 'Johnnie Walker Black Label',
    category: 'Whiskey',
    price: 4500,
    image: '🥃',
    quantity: 15,
  ),
  DrinkItem(
    id: '2',
    name: 'Jameson Irish Whiskey',
    category: 'Whiskey',
    price: 3800,
    image: '🥃',
    quantity: 18,
  ),
  DrinkItem(
    id: '3',
    name: 'Glenfiddich 12 Year',
    category: 'Whiskey',
    price: 6500,
    image: '🥃',
    quantity: 12,
  ),
  DrinkItem(
    id: '4',
    name: 'Chivas Regal 12 Year',
    category: 'Whiskey',
    price: 5200,
    image: '🥃',
    quantity: 14,
  ),
  DrinkItem(
    id: '5',
    name: 'Jack Daniels',
    category: 'Whiskey',
    price: 4800,
    image: '🥃',
    quantity: 16,
  ),

  // Premium Whiskeys (15000-50000)
  DrinkItem(
    id: '6',
    name: 'Johnnie Walker Blue Label',
    category: 'Premium Whiskey',
    price: 28000,
    image: '🥃',
    quantity: 4,
  ),
  DrinkItem(
    id: '7',
    name: 'Macallan 18 Year',
    category: 'Premium Whiskey',
    price: 45000,
    image: '🥃',
    quantity: 2,
  ),
  DrinkItem(
    id: '8',
    name: 'Glenfiddich 21 Year',
    category: 'Premium Whiskey',
    price: 18000,
    image: '🥃',
    quantity: 6,
  ),
  DrinkItem(
    id: '9',
    name: 'Chivas Regal 25 Year',
    category: 'Premium Whiskey',
    price: 35000,
    image: '🥃',
    quantity: 3,
  ),

  // Mid-Range Vodkas (3500-7000)
  DrinkItem(
    id: '10',
    name: 'Absolut Vodka',
    category: 'Vodka',
    price: 3500,
    image: '🥃',
    quantity: 20,
  ),
  DrinkItem(
    id: '11',
    name: 'Grey Goose',
    category: 'Vodka',
    price: 6800,
    image: '🥃',
    quantity: 12,
  ),
  DrinkItem(
    id: '12',
    name: 'Belvedere',
    category: 'Vodka',
    price: 5500,
    image: '🥃',
    quantity: 15,
  ),
  DrinkItem(
    id: '13',
    name: 'Ciroc',
    category: 'Vodka',
    price: 4200,
    image: '🥃',
    quantity: 18,
  ),

  // Premium Vodkas (12000-25000)
  DrinkItem(
    id: '14',
    name: 'Crystal Head Vodka',
    category: 'Premium Vodka',
    price: 12000,
    image: '🥃',
    quantity: 8,
  ),
  DrinkItem(
    id: '15',
    name: 'Beluga Gold Line',
    category: 'Premium Vodka',
    price: 25000,
    image: '🥃',
    quantity: 4,
  ),

  // Mid-Range Brandies & Cognacs (4000-8000)
  DrinkItem(
    id: '16',
    name: 'Hennessy VS',
    category: 'Brandy',
    price: 4500,
    image: '🥃',
    quantity: 16,
  ),
  DrinkItem(
    id: '17',
    name: 'Remy Martin VSOP',
    category: 'Brandy',
    price: 7200,
    image: '🥃',
    quantity: 10,
  ),
  DrinkItem(
    id: '18',
    name: 'Martell VS',
    category: 'Brandy',
    price: 4800,
    image: '🥃',
    quantity: 14,
  ),

  // Premium Brandies & Cognacs (15000-40000)
  DrinkItem(
    id: '19',
    name: 'Hennessy XO',
    category: 'Premium Brandy',
    price: 22000,
    image: '🥃',
    quantity: 5,
  ),
  DrinkItem(
    id: '20',
    name: 'Remy Martin XO',
    category: 'Premium Brandy',
    price: 32000,
    image: '🥃',
    quantity: 3,
  ),
  DrinkItem(
    id: '21',
    name: 'Hennessy Paradis',
    category: 'Premium Brandy',
    price: 50000,
    image: '🥃',
    quantity: 2,
  ),

  // Mid-Range Wines (3500-8000)
  DrinkItem(
    id: '22',
    name: 'Moët & Chandon',
    category: 'Champagne',
    price: 6500,
    image: '🍾',
    quantity: 12,
  ),
  DrinkItem(
    id: '23',
    name: 'Veuve Clicquot',
    category: 'Champagne',
    price: 7800,
    image: '🍾',
    quantity: 10,
  ),
  DrinkItem(
    id: '24',
    name: 'Nederburg Wine',
    category: 'Wine',
    price: 3500,
    image: '🍷',
    quantity: 20,
  ),
  DrinkItem(
    id: '25',
    name: 'KWV Wine',
    category: 'Wine',
    price: 4200,
    image: '🍷',
    quantity: 18,
  ),

  // Premium Wines & Champagne (15000-45000)
  DrinkItem(
    id: '26',
    name: 'Dom Pérignon',
    category: 'Premium Champagne',
    price: 38000,
    image: '🍾',
    quantity: 4,
  ),
  DrinkItem(
    id: '27',
    name: 'Cristal Champagne',
    category: 'Premium Champagne',
    price: 42000,
    image: '🍾',
    quantity: 3,
  ),
  DrinkItem(
    id: '28',
    name: 'Krug Grande Cuvée',
    category: 'Premium Champagne',
    price: 28000,
    image: '🍾',
    quantity: 5,
  ),

  // Mid-Range Tequila & Rum (3500-7000)
  DrinkItem(
    id: '29',
    name: 'Patron Silver',
    category: 'Tequila',
    price: 5500,
    image: '🥃',
    quantity: 14,
  ),
  DrinkItem(
    id: '30',
    name: 'Jose Cuervo Gold',
    category: 'Tequila',
    price: 3800,
    image: '🥃',
    quantity: 18,
  ),
  DrinkItem(
    id: '31',
    name: 'Captain Morgan',
    category: 'Rum',
    price: 4200,
    image: '🥃',
    quantity: 16,
  ),
  DrinkItem(
    id: '32',
    name: 'Bacardi 8 Year',
    category: 'Rum',
    price: 6800,
    image: '🥃',
    quantity: 12,
  ),

  // Premium Tequila (15000-35000)
  DrinkItem(
    id: '33',
    name: 'Clase Azul Reposado',
    category: 'Premium Tequila',
    price: 22000,
    image: '🥃',
    quantity: 6,
  ),
  DrinkItem(
    id: '34',
    name: 'Don Julio 1942',
    category: 'Premium Tequila',
    price: 35000,
    image: '🥃',
    quantity: 3,
  ),

  // Local Premium Options (5000-15000)
  DrinkItem(
    id: '35',
    name: 'Leleshwa Reserve Wine',
    category: 'Local Premium',
    price: 8500,
    image: '🍷',
    quantity: 8,
  ),
  DrinkItem(
    id: '36',
    name: 'Rift Valley Premium',
    category: 'Local Premium',
    price: 12000,
    image: '🍷',
    quantity: 6,
  ),
  DrinkItem(
    id: '37',
    name: 'Kenya Cane Premium',
    category: 'Local Premium',
    price: 5500,
    image: '🥃',
    quantity: 12,
  ),

  // Specialty & Liqueurs (4000-8000)
  DrinkItem(
    id: '38',
    name: 'Baileys Irish Cream',
    category: 'Liqueur',
    price: 4500,
    image: '🥃',
    quantity: 15,
  ),
  DrinkItem(
    id: '39',
    name: 'Kahlua',
    category: 'Liqueur',
    price: 4200,
    image: '🥃',
    quantity: 16,
  ),
  DrinkItem(
    id: '40',
    name: 'Grand Marnier',
    category: 'Liqueur',
    price: 7500,
    image: '🥃',
    quantity: 10,
  ),
];

Future<List<DrinkItem>> fetchDrinks(String endpoint) async {
  //  because the products endpoint is not ready  we will use the memory map
  try {
    final drinks = await fetchGlobal<DrinkItem>(
      getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
      fromJson: (json) => DrinkItem.fromJson(json),
      endpoint: endpoint,
    );
    return drinks;
  } on Exception catch (e) {
    throw Exception("fetch Drinks error $e");
  }
}


