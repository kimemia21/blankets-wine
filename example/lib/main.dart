



import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/features/Stockist/Stockist.dart';
import 'package:blankets_and_wines_example/features/Test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: set up custom logger or use print
  void log(String message) {
    // Could also use logger package or FirebaseCrashlytics here
    debugPrint('[SmartPOS] $message');
  }

  try {
    log('App starting...');
    final initResult = await SmartposPlugin.initializeDevice();
    log('Device initialization result: ${initResult['message']}');

    // final platformVersion = await SmartposPlugin.platformVersion ?? 'Unknown platform version';
    // log('Platform version: $platformVersion');

    final openResult = await SmartposPlugin.openDevice();
    log('Device open result: ${openResult['message']}');

    final info = await SmartposPlugin.getDeviceInfo();
    log('Device Info: $info');

    // Optional: close device at the end of init for testing
    // final closeResult = await SmartposPlugin.closeDevice();
    // log('Device closed: ${closeResult['message']}');
  } catch (e, stacktrace) {
    log('Initialization error: $e');
    log('Stacktrace: $stacktrace');
  }
  runApp(
    // MyApp()
  QRScannerPage()
  // StockistMainScreen()
    );
// runApp(BarPOSApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: StockistMainScreen());
  }
}

class BarPOSApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashier System',
      theme: BarPOSTheme.darkTheme, // Use the centralized theme
      home: POSMainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DrinkItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String image;
  final int quantity;

  DrinkItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
    required this.quantity,
  });
}

class CartItem {
  final DrinkItem drink;
  int quantity;

  CartItem({required this.drink, this.quantity = 1});

  double get totalPrice => drink.price * quantity;
}

class POSMainScreen extends StatefulWidget {
  @override
  _POSMainScreenState createState() => _POSMainScreenState();
}

class _POSMainScreenState extends State<POSMainScreen> {
  List<CartItem> cart = [];
  String selectedCategory = 'All';
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  bool isCartVisible = false;

  final List<String> categories = [
    'All',
    'Beer',
    'Wine',
    'Cocktails',
    'Spirits',
    'Non-Alcoholic',
  ];

  final List<DrinkItem> drinks = [
    DrinkItem(
      id: '1',
      name: 'Corona Extra',
      category: 'Beer',
      price: 5.50,
      image: '🍺',
      quantity: 20,
    ),
    DrinkItem(
      id: '2',
      name: 'Heineken',
      category: 'Beer',
      price: 6.00,
      image: '🍺',

      quantity: 20,
    ),
    DrinkItem(
      id: '3',
      name: 'Guinness',
      category: 'Beer',
      price: 6.50,
      image: '🍺',

      quantity: 20,
    ),
    DrinkItem(
      id: '4',
      name: 'Cabernet Sauvignon',
      category: 'Wine',
      price: 12.00,
      image: '🍷',

      quantity: 20,
    ),
    DrinkItem(
      id: '5',
      name: 'Chardonnay',
      category: 'Wine',
      price: 11.00,
      image: '🍷',

      quantity: 20,
    ),
    DrinkItem(
      id: '6',
      name: 'Pinot Grigio',
      category: 'Wine',
      price: 10.50,
      image: '🍷',

      quantity: 20,
    ),
    DrinkItem(
      id: '7',
      name: 'Mojito',
      category: 'Cocktails',
      price: 9.00,
      image: '🍹',

      quantity: 20,
    ),
    DrinkItem(
      id: '8',
      name: 'Margarita',
      category: 'Cocktails',
      price: 9.50,
      image: '🍹',

      quantity: 20,
    ),
    DrinkItem(
      id: '9',
      name: 'Old Fashioned',
      category: 'Cocktails',
      price: 11.00,
      image: '🥃',

      quantity: 20,
    ),
    DrinkItem(
      id: '10',
      name: 'Whiskey',
      category: 'Spirits',
      price: 8.00,
      image: '🥃',

      quantity: 20,
    ),
    DrinkItem(
      id: '11',
      name: 'Vodka',
      category: 'Spirits',
      price: 7.50,
      image: '🥃',

      quantity: 20,
    ),
    DrinkItem(
      id: '12',
      name: 'Rum',
      category: 'Spirits',
      price: 7.50,
      image: '🥃',

      quantity: 20,
    ),
    DrinkItem(
      id: '13',
      name: 'Coca Cola',
      category: 'Non-Alcoholic',
      price: 3.00,
      image: '🥤',

      quantity: 20,
    ),
    DrinkItem(
      id: '14',
      name: 'Orange Juice',
      category: 'Non-Alcoholic',
      price: 3.50,
      image: '🧃',
      quantity: 20,
    ),
    DrinkItem(
      id: '15',
      name: 'Water',
      category: 'Non-Alcoholic',
      price: 2.00,
      image: '💧',
      quantity: 20,
    ),
  ];

  List<DrinkItem> get filteredDrinks {
    return drinks.where((drink) {
      bool categoryMatch =
          selectedCategory == 'All' || drink.category == selectedCategory;
      bool searchMatch = drink.name.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      return categoryMatch && searchMatch;
    }).toList();
  }

  double get cartTotal {
    return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void addToCart(DrinkItem drink) {
    setState(() {
      final existingItemIndex = cart.indexWhere(
        (item) => item.drink.id == drink.id,
      );

      if (existingItemIndex >= 0) {
        cart[existingItemIndex].quantity++;
      } else {
        cart.add(CartItem(drink: drink));
      }
    });
  }

  void removeFromCart(String drinkId) {
    setState(() {
      cart.removeWhere((item) => item.drink.id == drinkId);
    });
  }

  void updateQuantity(String drinkId, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        removeFromCart(drinkId);
      } else {
        final item = cart.firstWhere((item) => item.drink.id == drinkId);
        item.quantity = newQuantity;
      }
    });
  }

  void clearCart() {
    setState(() {
      cart.clear();
    });
  }

  // Determine if we should show side-by-side layout (tablet/desktop)
  bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 768;
  }

  // Get responsive grid count based on screen size
  int getGridCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4; // Desktop
    if (width > 768) return 3; // Tablet landscape
    if (width > 600) return 2; // Tablet portrait
    return 2; // Mobile
  }

  @override
  Widget build(BuildContext context) {
    bool largeScreen = isLargeScreen(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cashier System'),

        actions: [
          // Cart button for mobile/tablet
          if (!largeScreen)
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      isCartVisible = !isCartVisible;
                    });
                  },
                  icon: Icon(Icons.shopping_cart),
                ),
                if (cart.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: BarPOSTheme.errorColor,
                        borderRadius: BorderRadius.circular(
                          BarPOSTheme.radiusSmall,
                        ),
                      ),
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      child: Text(
                        '${cart.length}',
                        style: TextStyle(
                          color: BarPOSTheme.primaryText,
                          fontSize: BarPOSTheme.labelMedium,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: largeScreen ? _buildDesktopLayout() : _buildMobileLayout(),
      // Floating cart total for mobile
      floatingActionButton:
          !largeScreen && cart.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: () => _showPaymentDialog(context),
                label: Text(
                  '\$${cartTotal.toStringAsFixed(2)}',
                  style: BarPOSTheme.totalPriceTextStyle.copyWith(
                    color: BarPOSTheme.primaryText,
                  ),
                ),
                icon: Icon(Icons.payment, size: 28),
              )
              : null,
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Panel - Menu Items
        Expanded(flex: 2, child: _buildMenuPanel()),
        // Right Panel - Cart
        Container(width: 400, child: _buildCartPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Main menu panel
        _buildMenuPanel(),
        // Sliding cart panel
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
                    onTap: () {}, // Prevent closing when tapping cart
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: _buildCartPanel(),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMenuPanel() {
    return Container(
      padding: BarPOSTheme.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            margin: EdgeInsets.only(bottom: BarPOSTheme.spacingL),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search drinks...',
                prefixIcon: Icon(Icons.search, size: 32),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // Category Tabs
          Container(
            height: BarPOSTheme.buttonHeight,
            margin: EdgeInsets.only(bottom: BarPOSTheme.spacingL),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Container(
                  margin: EdgeInsets.only(right: BarPOSTheme.spacingS),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected
                              ? BarPOSTheme.buttonColor
                              : BarPOSTheme.accentDark,
                      foregroundColor: BarPOSTheme.primaryText,
                      textStyle: BarPOSTheme.categoryTextStyle,
                    ),
                    child: Text(category),
                  ),
                );
              },
            ),
          ),

          // Drinks Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: getGridCount(context),
                crossAxisSpacing: BarPOSTheme.spacingM,
                mainAxisSpacing: BarPOSTheme.spacingM,
                childAspectRatio: 0.85,
              ),
              itemCount: filteredDrinks.length,
              itemBuilder: (context, index) {
                final drink = filteredDrinks[index];
                // Find if drink is in cart and get its quantity
                final cartItem = cart.firstWhere(
                  (item) => item.drink.id == drink.id,
                  orElse: () => CartItem(drink: drink, quantity: 0),
                );
                final isInCart = cartItem.quantity > 0;

                return GestureDetector(
                  onTap: () => addToCart(drink),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color:
                          isInCart
                              ? BarPOSTheme.successColor.withOpacity(0.1)
                              : BarPOSTheme.secondaryDark,
                      borderRadius: BorderRadius.circular(
                        BarPOSTheme.radiusMedium,
                      ),
                      border: Border.all(
                        color:
                            isInCart
                                ? BarPOSTheme.successColor.withOpacity(0.3)
                                : BarPOSTheme.accentDark.withOpacity(0.3),
                        width: isInCart ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                        if (isInCart)
                          BoxShadow(
                            color: BarPOSTheme.successColor.withOpacity(0.1),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(BarPOSTheme.spacingM),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Drink emoji with modern styling
                              Container(
                                padding: EdgeInsets.all(BarPOSTheme.spacingS),
                                decoration: BoxDecoration(
                                  color: BarPOSTheme.buttonColor.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    BarPOSTheme.radiusLarge,
                                  ),
                                ),
                                child: Text(
                                  drink.image,
                                  style: TextStyle(fontSize: 48),
                                ),
                              ),
                              SizedBox(height: BarPOSTheme.spacingM),

                              // Drink name
                              Text(
                                drink.name,
                                style: BarPOSTheme.itemNameTextStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: BarPOSTheme.spacingS),

                              // Price with modern styling
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: BarPOSTheme.spacingM,
                                  vertical: BarPOSTheme.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: BarPOSTheme.buttonColor.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    BarPOSTheme.radiusSmall,
                                  ),
                                ),
                                child: Text(
                                  '\kshs ${drink.price.toStringAsFixed(2)}',
                                  style: BarPOSTheme.priceTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Modern quantity badge
                        if (isInCart)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: AnimatedScale(
                              scale: 1.0,
                              duration: Duration(milliseconds: 200),
                              child: Container(
                                constraints: BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      BarPOSTheme.successColor,
                                      BarPOSTheme.successColor.withGreen(200),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BarPOSTheme.successColor
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${cartItem.quantity}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 34,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),

                        // Subtle hover/tap indication
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => addToCart(drink),
                              borderRadius: BorderRadius.circular(
                                BarPOSTheme.radiusMedium,
                              ),
                              splashColor: BarPOSTheme.buttonColor.withOpacity(
                                0.2,
                              ),
                              highlightColor: BarPOSTheme.buttonColor
                                  .withOpacity(0.1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartPanel() {
    return Container(
      decoration: BoxDecoration(color: BarPOSTheme.accentDark),
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: BarPOSTheme.cardPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Order',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  children: [
                    if (cart.isNotEmpty)
                      IconButton(
                        onPressed: clearCart,
                        icon: Icon(
                          Icons.clear_all,
                          color: BarPOSTheme.errorColor,
                          size: 28,
                        ),
                      ),
                    if (!isLargeScreen(context))
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isCartVisible = false;
                          });
                        },
                        icon: Icon(Icons.close, size: 28),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Cart Items
          Expanded(
            child:
                cart.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            color: BarPOSTheme.secondaryText,
                            size: 64,
                          ),
                          SizedBox(height: BarPOSTheme.spacingM),
                          Text(
                            'No items in cart',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: BarPOSTheme.secondaryText),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: BarPOSTheme.spacingL,
                      ),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: BarPOSTheme.spacingS),
                          padding: BarPOSTheme.cardPadding,
                          decoration: BarPOSTheme.buttonCardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.drink.name,
                                      style: BarPOSTheme.itemNameTextStyle,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        () => removeFromCart(item.drink.id),
                                    icon: Icon(
                                      Icons.delete,
                                      color: BarPOSTheme.errorColor,
                                      size: 24,
                                    ),
                                    constraints: BoxConstraints(),
                                    padding: EdgeInsets.all(4),
                                  ),
                                ],
                              ),
                              SizedBox(height: BarPOSTheme.spacingXS),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed:
                                            () => updateQuantity(
                                              item.drink.id,
                                              item.quantity - 1,
                                            ),
                                        icon: Icon(
                                          Icons.remove_circle,
                                          color: BarPOSTheme.secondaryText,
                                          size: 28,
                                        ),
                                        constraints: BoxConstraints(),
                                        padding: EdgeInsets.all(6),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: BarPOSTheme.spacingM,
                                        ),
                                        child: Text(
                                          '${item.quantity}',
                                          style: BarPOSTheme.quantityTextStyle,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed:
                                            () => updateQuantity(
                                              item.drink.id,
                                              item.quantity + 1,
                                            ),
                                        icon: Icon(
                                          Icons.add_circle,
                                          color: BarPOSTheme.secondaryText,
                                          size: 28,
                                        ),
                                        constraints: BoxConstraints(),
                                        padding: EdgeInsets.all(6),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                    style: BarPOSTheme.priceTextStyle,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),

          // Total and Checkout
          if (cart.isNotEmpty)
            Container(
              padding: BarPOSTheme.cardPaddingLarge,
              decoration: BoxDecoration(
                color: BarPOSTheme.buttonColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(BarPOSTheme.radiusLarge),
                  topRight: Radius.circular(BarPOSTheme.radiusLarge),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '\$${cartTotal.toStringAsFixed(2)}',
                        style: BarPOSTheme.totalPriceTextStyle,
                      ),
                    ],
                  ),
                  SizedBox(height: BarPOSTheme.spacingL),
                  SizedBox(
                    width: double.infinity,
                    height: BarPOSTheme.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () => _showPaymentDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BarPOSTheme.successColor,
                        foregroundColor: BarPOSTheme.primaryText,
                      ),
                      child: Text('Confirm Payment'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Amount: \$${cartTotal.toStringAsFixed(2)}',
                style: BarPOSTheme.totalPriceTextStyle,
              ),
              SizedBox(height: BarPOSTheme.spacingM),
              Text('Are you sure you want to process this payment?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processPayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BarPOSTheme.successColor,
                foregroundColor: BarPOSTheme.primaryText,
              ),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _processPayment() async {
    String orderNumber =
        "ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

    print("Processing sale with order number: $orderNumber");

    try {
      await SmartposPlugin.printReceipt({
        "storeName": "The Local Bar & Grill",
        "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "time": DateFormat('HH:mm:ss').format(DateTime.now()),
        "orderNumber": orderNumber,
        "items":
            cart
                .map(
                  (item) => {
                    "name": item.drink.name,
                    "quantity": item.quantity,
                    "price": item.totalPrice.toStringAsFixed(2),
                  },
                )
                .toList(),
        "subtotal": (cartTotal * 0.9).toStringAsFixed(2), // Assuming 10% tax
        "tax": (cartTotal * 0.1).toStringAsFixed(2),
        "total": cartTotal.toStringAsFixed(2),
        "paymentMethod": "Cash", // You can make this dynamic
      });

      //  await SmartposPlugin.printQrCode(orderNumber, size: 200);

      // Show success message with order number
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed successfully! Order #$orderNumber'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // // Clear cart after successful payment
      // setState(() {
      //     cart.clear();
      // });
    } catch (e) {
      print("Error printing receipt: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment processed successfully!'),
        backgroundColor: BarPOSTheme.successColor,
        duration: Duration(seconds: 2),
      ),
    );

    // Clear the cart
    clearCart();

    // Close cart panel if on mobile
    if (!isLargeScreen(context)) {
      setState(() {
        isCartVisible = false;
      });
    }
  }
}
