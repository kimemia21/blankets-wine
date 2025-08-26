import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/data/models/DrinkCategory.dart';

import 'package:blankets_and_wines_example/data/models/Product.dart';
import 'package:blankets_and_wines_example/features/Stockist/Stockist.dart';
import 'package:blankets_and_wines_example/features/cashier/functions/fetchDrinks.dart';
import 'package:blankets_and_wines_example/features/cashier/models/CartItems.dart';
import 'package:blankets_and_wines_example/features/cashier/widgets/CartPanel.dart';
import 'package:blankets_and_wines_example/features/cashier/widgets/MenuPanel.dart';
import 'package:flutter/material.dart';

class Cashier extends StatefulWidget {
  @override
  _CashierState createState() => _CashierState();
}

class _CashierState extends State<Cashier> {
  late Future<List<Product>> drinks;
  late Future<List<DrinkCategory>> categories;
  List<CartItem> cart = [];

  String selectedCategory = 'All';
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  bool isCartVisible = false;
  int istappedThree = 0;

  double get cartTotal {
    return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void addToCart(Product drink) {
    setState(() {
      final existingItemIndex = cart.indexWhere(
        (item) => item.drink.id == drink.id,
      );

      if (existingItemIndex >= 0) {
        cart[existingItemIndex].quantity++;
      } else {
        cart.add(CartItem(drink: drink));
        cartG.items = cart;
        print(cartG.toOrderFormat());
      }
    });
  }

  void removeFromCart(int drinkId) {
    debugPrint("Removed item $drinkId");
    setState(() {
      cart.removeWhere((item) => item.drink.id == drinkId);
      cartG.items = cart;
    });
  }

  void updateQuantity(int drinkId, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        removeFromCart(drinkId);
        cartG.items = cart;
      } else {
        final item = cart.firstWhere((item) => item.drink.id == drinkId);
        item.quantity = newQuantity;
        cartG.items = cart;
      }
    });
  }

  void clearCart() {
    setState(() {
      cart.clear();
      cartG.items = cart;
    });
  }

  bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 768;
  }

  void refreshDrinks() {
    setState(() {
      drinks = CashierFunctions.fetchDrinks("products/${appUser.barId}");
      categories = CashierFunctions.fetchCategories("ecom/categories");
    });
  }

  @override
  void initState() {
    super.initState();
    drinks = CashierFunctions.fetchDrinks("products/${appUser.barId}");
    categories = CashierFunctions.fetchCategories("ecom/categories");
  }

  @override
  Widget build(BuildContext context) {
    bool largeScreen = isLargeScreen(context);

    return MaterialApp(
      title: 'Cashier System',
      theme: BarPOSTheme.darkTheme,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Cashier System'),
          leading: IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: () {
              setState(() {
                istappedThree++;
                if (istappedThree >= 3) {
                  print("Debug mode activated");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StockistMainScreen(),
                    ),
                  );
                  istappedThree = 0;
                }
              });
            },
          ),
          actions: [
            if (!largeScreen)
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isCartVisible = !isCartVisible;
                      });
                    },
                    icon: Icon(
                      Icons.shopping_cart,
                      size: 42,
                    ), // Increased icon size
                    iconSize: 42, // Makes the clickable area larger
                  ),
                  if (cart.isNotEmpty)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: EdgeInsets.all(2), // Increased padding
                        decoration: BoxDecoration(
                          color: BarPOSTheme.errorColor,
                          borderRadius: BorderRadius.circular(
                            BarPOSTheme.radiusSmall,
                          ),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 28, // Increased minimum width
                          minHeight: 28, // Increased minimum height
                        ),
                        child: Text(
                          '${cart.length}',
                          style: TextStyle(
                            color: BarPOSTheme.primaryText,
                            fontSize: 16, // Increased font size
                            fontWeight: FontWeight.w800, // Made text bolder
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        body: _buildMobileLayout(),
        floatingActionButton:
            cart.isNotEmpty && !isCartVisible
                ? Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 56,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      setState(() {
                        isCartVisible = true;
                      });
                    },
                    backgroundColor: BarPOSTheme.buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_cart, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '${cart.length} items  ',
                              style: TextStyle(
                                fontSize: 14,
                                color: BarPOSTheme.primaryText,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Pay KSH ${formatWithCommas(cartTotal.toStringAsFixed(0))}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: BarPOSTheme.primaryText,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        MenuPanel(
          products: drinks,
          categories: categories,
          selectedCategory: selectedCategory,
          searchQuery: searchQuery,
          searchController: searchController,
          cart: cart,
          onCategoryChanged: (category) {
            setState(() {
              selectedCategory = category;
            });
          },
          onRefresh: () {
            drinks = CashierFunctions.fetchDrinks("products/${appUser.barId}");
          },

          onSearchChanged: (query) {
            setState(() {
              searchQuery = query;
            });
          },
          onAddToCart: addToCart,
        ),
        if (isCartVisible)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isCartVisible = false;
                });
              },
              child: Container(
                color: Colors.black54,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: CartPanel(
                        onPaymentConfirm: () {
                          refreshDrinks();
                          clearCart();
                          isCartVisible = false;
                        },

                        cartTotal: cartTotal,
                        isLargeScreen: false,
                        onRemoveFromCart: removeFromCart,
                        onUpdateQuantity: updateQuantity,
                        onClearCart: clearCart,
                        onShowPayment: () {},
                        //  _showPaymentDialog,
                        onCloseCart: () {
                          setState(() {
                            isCartVisible = false;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
