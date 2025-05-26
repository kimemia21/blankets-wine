import 'package:blankets_and_wines/blankets_and_wines.dart';
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

  runApp(BarPOSApp());
}

class BarPOSApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashier System',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Color(0xFF1A1A2E),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF16213E),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0F3460),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
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

  DrinkItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
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
    ),
    DrinkItem(
      id: '2',
      name: 'Heineken',
      category: 'Beer',
      price: 6.00,
      image: '🍺',
    ),
    DrinkItem(
      id: '3',
      name: 'Guinness',
      category: 'Beer',
      price: 6.50,
      image: '🍺',
    ),
    DrinkItem(
      id: '4',
      name: 'Cabernet Sauvignon',
      category: 'Wine',
      price: 12.00,
      image: '🍷',
    ),
    DrinkItem(
      id: '5',
      name: 'Chardonnay',
      category: 'Wine',
      price: 11.00,
      image: '🍷',
    ),
    DrinkItem(
      id: '6',
      name: 'Pinot Grigio',
      category: 'Wine',
      price: 10.50,
      image: '🍷',
    ),
    DrinkItem(
      id: '7',
      name: 'Mojito',
      category: 'Cocktails',
      price: 9.00,
      image: '🍹',
    ),
    DrinkItem(
      id: '8',
      name: 'Margarita',
      category: 'Cocktails',
      price: 9.50,
      image: '🍹',
    ),
    DrinkItem(
      id: '9',
      name: 'Old Fashioned',
      category: 'Cocktails',
      price: 11.00,
      image: '🥃',
    ),
    DrinkItem(
      id: '10',
      name: 'Whiskey',
      category: 'Spirits',
      price: 8.00,
      image: '🥃',
    ),
    DrinkItem(
      id: '11',
      name: 'Vodka',
      category: 'Spirits',
      price: 7.50,
      image: '🥃',
    ),
    DrinkItem(
      id: '12',
      name: 'Rum',
      category: 'Spirits',
      price: 7.50,
      image: '🥃',
    ),
    DrinkItem(
      id: '13',
      name: 'Coca Cola',
      category: 'Non-Alcoholic',
      price: 3.00,
      image: '🥤',
    ),
    DrinkItem(
      id: '14',
      name: 'Orange Juice',
      category: 'Non-Alcoholic',
      price: 3.50,
      image: '🧃',
    ),
    DrinkItem(
      id: '15',
      name: 'Water',
      category: 'Non-Alcoholic',
      price: 2.00,
      image: '💧',
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
        title: Text('Bar POS System'),
        centerTitle: true,
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
                  icon: Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                if (cart.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        '${cart.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
                backgroundColor: Color(0xFF4CAF50),
                label: Text(
                  '\$${cartTotal.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                icon: Icon(Icons.payment),
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            margin: EdgeInsets.only(bottom: 16),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search drinks...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 16),
                prefixIcon: Icon(Icons.search, color: Colors.white54, size: 24),
                filled: true,
                fillColor: Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
            height: 50,
            margin: EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Color(0xFF0F3460) : Color(0xFF16213E),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: filteredDrinks.length,
              itemBuilder: (context, index) {
                final drink = filteredDrinks[index];
                return GestureDetector(
                  onTap: () => addToCart(drink),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(drink.image, style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            drink.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '\$${drink.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
      color: Color(0xFF16213E),
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (cart.isNotEmpty)
                      IconButton(
                        onPressed: clearCart,
                        icon: Icon(
                          Icons.clear_all,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                    if (!isLargeScreen(context))
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isCartVisible = false;
                          });
                        },
                        icon: Icon(Icons.close, color: Colors.white, size: 24),
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
                            color: Colors.white54,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No items in cart',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF0F3460),
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        () => removeFromCart(item.drink.id),
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    constraints: BoxConstraints(),
                                    padding: EdgeInsets.all(4),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
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
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        constraints: BoxConstraints(),
                                        padding: EdgeInsets.all(4),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          '${item.quantity}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        constraints: BoxConstraints(),
                                        padding: EdgeInsets.all(4),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF0F3460),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${cartTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _showPaymentDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
          backgroundColor: Color(0xFF16213E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Confirm Payment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Amount: \$${cartTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Confirm payment received?',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                _processSale();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _processSale() async {
    String orderNumber = "ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    
    print("Processing sale with order number: $orderNumber");
    
    try {
        await SmartposPlugin.printReceipt({
            "storeName": "The Local Bar & Grill",
            "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
            "time": DateFormat('HH:mm:ss').format(DateTime.now()),
            "orderNumber": orderNumber,
            "items": cart.map((item) => {
                "name": item.drink.name,
                "quantity": item.quantity,
                "price": item.totalPrice.toStringAsFixed(2)
            }).toList(),
            "subtotal": (cartTotal * 0.9).toStringAsFixed(2), // Assuming 10% tax
            "tax": (cartTotal * 0.1).toStringAsFixed(2),
            "total": cartTotal.toStringAsFixed(2),
            "paymentMethod": "Cash", // You can make this dynamic
        });
        
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

    // 'Bar POS Sale Receipt\n' +
    // '====================\n' +
    // 'Date: ${DateTime.now()}\n' +
    // 'Items:\n' +
    // cart.map((item) => '${item.drink.name} x${item.quantity} - \$${item.totalPrice.toStringAsFixed(2)}').join('\n') +
    // '\nTotal: \$${cartTotal.toStringAsFixed(2)}\n' +
    // 'Thank you for your order!\n\n\n',
    // fontSize: 40,
    // alignment: 'CENTER',);

    // Show success dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF16213E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
              SizedBox(width: 8),
              Text(
                'Sale Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Payment of \$${cartTotal.toStringAsFixed(2)} confirmed.\nSale has been recorded.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                clearCart();
                if (!isLargeScreen(context)) {
                  setState(() {
                    isCartVisible = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: Text('New Order'),
            ),
          ],
        );
      },
    );
  }
}

// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   String _platformVersion = 'Unknown';
//   String _deviceStatus = 'Not initialized';
//   String _lastOperation = 'None';
//   bool _deviceReady = false;
//   DeviceInfo? _deviceInfo;

//   @override
//   void initState() {
//     super.initState();
//     initPlatformState();
//   }

//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initPlatformState() async {
//     String platformVersion;
//     // Platform messages may fail, so we use a try/catch PlatformException.
//     try {
//       platformVersion = await SmartposPlugin.platformVersion ?? 'Unknown platform version';
//     } on PlatformException {
//       platformVersion = 'Failed to get platform version.';
//     }

//     // If the widget was removed from the tree while the asynchronous platform
//     // message was in flight, we want to discard the reply rather than calling
//     // setState to update our non-existent appearance.
//     if (!mounted) return;

//     setState(() {
//       _platformVersion = platformVersion;
//     });
//   }

//   Future<void> _initializeDevice() async {
//     try {
//       setState(() {
//         _lastOperation = 'Initializing device...';
//       });

//       final result = await SmartposPlugin.initializeDevice();
      
//       setState(() {
//         _deviceStatus = result['message'];
//         _lastOperation = 'Device initialized successfully';
//       });

//       // After initialization, get device info
//       await _getDeviceInfo();
//     } catch (e) {
//       setState(() {
//         _lastOperation = 'Initialize failed: $e';
//         _deviceStatus = 'Initialize failed';
//       });
//     }
//   }

//   Future<void> _openDevice() async {
//     try {
//       setState(() {
//         _lastOperation = 'Opening device...';
//       });

//       final result = await SmartposPlugin.openDevice();
      
//       setState(() {
//         _deviceStatus = result['message'];
//         _lastOperation = 'Device opened successfully';
//         _deviceReady = true;
//       });
//     } catch (e) {
//       setState(() {
//         _lastOperation = 'Open failed: $e';
//         _deviceStatus = 'Open failed';
//       });
//     }
//   }

//   Future<void> _closeDevice() async {
//     try {
//       setState(() {
//         _lastOperation = 'Closing device...';
//       });

//       final result = await SmartposPlugin.closeDevice();
      
//       setState(() {
//         _deviceStatus = result['message'];
//         _lastOperation = 'Device closed successfully';
//         _deviceReady = false;
//       });
//     } catch (e) {
//       setState(() {
//         _lastOperation = 'Close failed: $e';
//       });
//     }
//   }

//   Future<void> _getDeviceInfo() async {
//     try {
//       setState(() {
//         _lastOperation = 'Getting device info...';
//       });

//       final deviceInfo = await SmartposPlugin.getDeviceInfo();
      
//       setState(() {
//         _deviceInfo = deviceInfo;
//         _lastOperation = 'Device info retrieved successfully';
//       });
//     } catch (e) {
//       setState(() {
//         _lastOperation = 'Get device info failed: $e';
//       });
//     }
//   }

//   Future<void> _readMagneticCard() async {
//     if (!_deviceReady) {
//       setState(() {
//         _lastOperation = 'Device not ready. Please initialize and open first.';
//       });
//       return;
//     }

//     try {
//       setState(() {
//         _lastOperation = 'Reading magnetic card... Please swipe card.';
//       });

//       final cardData = await SmartposPlugin.readMagneticCard();
      
//       setState(() {
//         _lastOperation = 'Card read: ${cardData.maskedPan} - ${cardData.cardholderName}';
//       });

//       // Show card details dialog
//       _showCardDetailsDialog(cardData);
//     } catch (e) {
//       setState(() {
//         _lastOperation = 'Card read failed: $e';
//       });
//     }
//   }

//   Future<void> _readICCard() async {
//     if (!_deviceReady) {
//       setState(() {
//         _lastOperation = 'Device not ready. Please initialize and open first.';
//       });
//       return;
//     }

//     try {
//       setState(() {
//         _lastOperation = 'Reading IC card... Please insert card.';
//       });

//       final cardData = await SmartposPlugin.readICCard();
      
//       setState(() {
//         _lastOperation = 'IC Card read: ${cardData.maskedPan} - ${cardData.cardholderName}';
//       });

//       _showCardDetailsDialog(cardData);
//     } catch (e) {
//       setState(() {
//         _lastOperation = 'IC card read failed: $e';
//       });
//     }
//   }

//   Future<void> _readContactlessCard() async {
//     if (!_deviceReady) {
//       setState(() {
//         _lastOperation = 'Device not ready. Please initialize and open first.';
//       });
//       return;
//     }

//     try {
//       setState(() {
//         _lastOperation = 'Reading contactless card... Please tap card.';
//       });

//       final cardData = await SmartposPlugin.readContactlessCard();
      
//       setState(() {
//         _lastOperation = 'Contactless card read: ${cardData.maskedPan} - ${cardData.cardholderName}';
//       });

//       _showCardDetailsDialog(cardData);
//     } catch (e) {
//       setState(() {
//         _lastOperation = 'Contactless card read failed: $e';
//       });
//     }
//   }

//   Future<void> _printTest() async {
//     if (!_deviceReady) {
//       setState(() {
//         _lastOperation = 'Device not ready. Please initialize and open first.';
//       });
//       return;
//     }

//     try {
//       setState(() {
//         _lastOperation = 'Printing test...';
//       });

//       await SmartposPlugin.printText(
//         'SmartPos Test Print\n' +
//         '====================\n' +
//         'Date: ${DateTime.now()}\n' +
//         'Device: ${_deviceInfo?.model ?? 'Unknown'}\n' +
//         'Serial: ${_deviceInfo?.serialNumber ?? 'Unknown'}\n' +
//         '====================\n' +
//         'Test completed successfully!\n\n\n',
//         fontSize: 24,
//         alignment: 'CENTER',
//       );

//       setState(() {
//         _lastOperation = 'Test print completed successfully';
//       });
//     } catch (e) {
//       setState(() {
//         _lastOperation = 'Print test failed: $e';
//       });
//     }
//   }

//   Future<void> _startEmvTransaction() async {
//     if (!_deviceReady) {
//       setState(() {
//         _lastOperation = 'Device not ready. Please initialize and open first.';
//       });
//       return;
//     }

//     try {
//       setState(() {
//         _lastOperation = 'Starting EMV transaction...';
//       });

//       final result = await SmartposPlugin.startEmvTransaction(
//         amount: 10.50,
//         currency: 'USD',
//         transactionType: 'SALE',
//       );

//       setState(() {
//         _lastOperation = 'EMV transaction started: ${result['transactionId']}';
//       });
//     } catch (e) {
//       setState(() {
//         _lastOperation = 'EMV transaction failed: $e';
//       });
//     }
//   }

//   Future<void> _playBeep() async {
//     try {
//       final result = await SmartposPlugin.playBeep();
//       setState(() {
//         _lastOperation = 'Beep: $result';
//       });
//     } catch (e) {
//       setState(() {
//         _lastOperation = 'Beep failed: $e';
//       });
//     }
//   }

//   void _showCardDetailsDialog(CardData cardData) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Card Details'),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildDetailRow('Card Type', cardData.cardType),
//                 if (cardData.maskedPan != null)
//                   _buildDetailRow('PAN', cardData.maskedPan!),
//                 if (cardData.cardholderName != null)
//                   _buildDetailRow('Cardholder', cardData.cardholderName!),
//                 if (cardData.expiryDate != null)
//                   _buildDetailRow('Expiry', cardData.expiryDate!),
//                 if (cardData.applicationLabel != null)
//                   _buildDetailRow('Application', cardData.applicationLabel!),
//                 if (cardData.atr != null)
//                   _buildDetailRow('ATR', cardData.atr!),
//                 if (cardData.uid != null)
//                   _buildDetailRow('UID', cardData.uid!),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: Text('Close'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 80,
//             child: Text(
//               '$label:',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: Text(value),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SmartPos Plugin Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('SmartPos Plugin Demo'),
//         ),
//         body: SingleChildScrollView(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Platform Version
//               Card(
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Platform Version:', style: TextStyle(fontWeight: FontWeight.bold)),
//                       Text(_platformVersion),
//                     ],
//                   ),
//                 ),
//               ),

//               // Device Status
//               Card(
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Device Status:', style: TextStyle(fontWeight: FontWeight.bold)),
//                       Text(_deviceStatus),
//                       SizedBox(height: 8),
//                       Text('Last Operation:', style: TextStyle(fontWeight: FontWeight.bold)),
//                       Text(_lastOperation),
//                     ],
//                   ),
//                 ),
//               ),

//               // Device Info
//               if (_deviceInfo != null)
//                 Card(
//                   child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Device Info:', style: TextStyle(fontWeight: FontWeight.bold)),
//                         Text('Model: ${_deviceInfo?.model ?? 'N/A'}'),
//                         Text('Serial: ${_deviceInfo?.serialNumber ?? 'N/A'}'),
//                         Text('Version: ${_deviceInfo?.firmwareVersion ?? 'N/A'}'),
//                       ],
//                     ),
//                   ),
//                 ),

//               SizedBox(height: 16),

//               // Device Control Buttons
//               Text('Device Control:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: _initializeDevice,
//                       child: Text('Initialize'),
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: _openDevice,
//                       child: Text('Open'),
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: _closeDevice,
//                       child: Text('Close'),
//                     ),
//                   ),
//                 ],
//               ),

//               SizedBox(height: 16),

//               // Card Reading Buttons
//               Text('Card Reading:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               ElevatedButton(
//                 onPressed: _readMagneticCard,
//                 child: Text('Read Magnetic Card'),
//               ),
//               SizedBox(height: 8),
//               ElevatedButton(
//                 onPressed: _readICCard,
//                 child: Text('Read IC Card'),
//               ),
//               SizedBox(height: 8),
//               ElevatedButton(
//                 onPressed: _readContactlessCard,
//                 child: Text('Read Contactless Card'),
//               ),

//               SizedBox(height: 16),

//               // Other Functions
//               Text('Other Functions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               ElevatedButton(
//                 onPressed: _printTest,
//                 child: Text('Print Test'),
//               ),
//               SizedBox(height: 8),
//               ElevatedButton(
//                 onPressed: _startEmvTransaction,
//                 child: Text('Start EMV Transaction'),
//               ),
//               SizedBox(height: 8),
//               ElevatedButton(
//                 onPressed: _playBeep,
//                 child: Text('Play Beep'),
//               ),
//               SizedBox(height: 8),
//               ElevatedButton(
//                 onPressed: _getDeviceInfo,
//                 child: Text('Get Device Info'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }