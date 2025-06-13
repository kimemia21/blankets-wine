import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/data/models/DrinkItem.dart';
import 'package:blankets_and_wines_example/features/cashier/functions/fetchDrinks.dart';
import 'package:blankets_and_wines_example/features/cashier/models/CartItems.dart';
import 'package:blankets_and_wines_example/features/cashier/widgets/DrinkItemCard.dart';
import 'package:flutter/material.dart';

class MenuPanel extends StatelessWidget {
  final Future<List<DrinkItem>> drinks;
  final String selectedCategory;
  final String searchQuery;
  final TextEditingController searchController;
  final List<CartItem> cart;
  final Function(String) onCategoryChanged;
  final Function(String) onSearchChanged;
  final Function(DrinkItem) onAddToCart;

  const MenuPanel({
    Key? key,
    required this.drinks,
    required this.selectedCategory,
    required this.searchQuery,
    required this.searchController,
    required this.cart,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.onAddToCart,
  }) : super(key: key);

  int getGridCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 768) return 3;
    if (width > 600) return 2;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: onSearchChanged,
            ),
          ),

          // Category Tabs
          Container(
            height: BarPOSTheme.buttonHeight,
            margin: EdgeInsets.only(bottom: BarPOSTheme.spacingL),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: CashierFunctions.categories.length,
              itemBuilder: (context, index) {
                final category = CashierFunctions.categories[index];
                final isSelected = selectedCategory == category;
                return Container(
                  margin: EdgeInsets.only(right: BarPOSTheme.spacingS),
                  child: ElevatedButton(
                    onPressed: () => onCategoryChanged(category),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected 
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
            child: FutureBuilder<List<DrinkItem>>(
              future: drinks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: BarPOSTheme.buttonColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: BarPOSTheme.errorColor,
                        ),
                        SizedBox(height: BarPOSTheme.spacingM),
                        Text(
                          'Error loading drinks',
                          style: TextStyle(color: BarPOSTheme.errorColor),
                        ),
                        TextButton(
                          onPressed: () {
                            // This would need to be handled by parent widget
                            // or passed as a callback
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No drinks available',
                      style: TextStyle(color: BarPOSTheme.secondaryText),
                    ),
                  );
                }

                final filteredDrinksList = snapshot.data!.where((drink) {
                  bool categoryMatch = selectedCategory == 'All' || 
                      drink.categoryId == selectedCategory;
                  bool searchMatch = drink.name.toLowerCase()
                      .contains(searchQuery.toLowerCase());
                  return categoryMatch && searchMatch;
                }).toList();

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getGridCount(context),
                    crossAxisSpacing: BarPOSTheme.spacingM,
                    mainAxisSpacing: BarPOSTheme.spacingM,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredDrinksList.length,
                  itemBuilder: (context, index) {
                    final drink = filteredDrinksList[index];
                    final cartItem = cart.firstWhere(
                      (item) => item.drink.id == drink.id,
                      orElse: () => CartItem(drink: drink, quantity: 0),
                    );

                    return DrinkItemCard(
                      drink: drink,
                      cartQuantity: cartItem.quantity,
                      onTap: () => onAddToCart(drink),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}