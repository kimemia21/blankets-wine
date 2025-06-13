import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/data/models/DrinkItem.dart';
import 'package:blankets_and_wines_example/features/Stockist/Stockist.dart';
import 'package:blankets_and_wines_example/features/cashier/functions/fetchDrinks.dart';
import 'package:blankets_and_wines_example/features/cashier/models/CartItems.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// class Cashier extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Cashier System',
//       theme: BarPOSTheme.darkTheme,
//       home: Cashier(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }




class Cashier extends StatefulWidget {
  @override
  _CashierState createState() => _CashierState();
}

class _CashierState extends State<Cashier> {
  List<CartItem> cart = [];
  String selectedCategory = 'All';
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  bool isCartVisible = false;

  int istappedThree = 0;

 

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
          // Navigate to debug screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StockistMainScreen()),
          );
          // Reset counter
          istappedThree = 0;
        }
      });
        },
      ),
      
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
                    'KSHS ${cartTotal.toStringAsFixed(2)}',
                    style: BarPOSTheme.totalPriceTextStyle.copyWith(
                      color: BarPOSTheme.primaryText,
                    ),
                  ),
                  icon: Icon(Icons.payment, size: 28),
                )
                : null,
      ),
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
                                    'kshs ${item.totalPrice.toStringAsFixed(2)}',
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
                'Total Amount: kshs ${cartTotal.toStringAsFixed(2)}',
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
      // Calculate subtotal (before tax)
      double subtotal =
          cartTotal / 1.16; // Reverse calculation to get pre-tax amount
      double tax = cartTotal - subtotal; // Tax amount

      await SmartposPlugin.printReceipt({
        "storeName": "Blankets Bar",
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
        "subtotal": subtotal.toStringAsFixed(2),
        "tax": tax.toStringAsFixed(2),
        "total": cartTotal.toStringAsFixed(2),
        "paymentMethod": "Cash", 
        // You can make this dynamic
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
