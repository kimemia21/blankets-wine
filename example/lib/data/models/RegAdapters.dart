import 'package:hive/hive.dart';

// Import all generated adapters
import 'DrinkCategory.dart';
import 'DrinkItem.dart';
import 'DrinkOrder.dart';
import 'Product.dart';
import 'ProductCategory.dart';
import 'UserData.dart';
// import 'UserRoles.dart';



class HiveAdapters {
  // Register all adapters
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
    // if (!Hive.isAdapterRegistered(UserRolesAdapter().typeId)) {
    //   Hive.registerAdapter(UserRolesAdapter());
    // }
  }

  // Open all boxes (async)
  static Future<void> openAllBoxes() async {
    await Hive.openBox<DrinkCategory>('drinkCategories');
    await Hive.openBox<DrinkItem>('drinkItems');
    await Hive.openBox<DrinkOrder>('drinkOrders');
    await Hive.openBox<Product>('products');
    await Hive.openBox<ProductCategory>('productCategories');
    await Hive.openBox<UserData>('users');
    // await Hive.openBox<UserRoles>('userRoles');
  }

  // Helper init = register + open
  static Future<void> init() async {
    registerAll();
    await openAllBoxes();
  }
}
