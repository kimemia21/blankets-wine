import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/data/models/Category.dart';
import 'package:blankets_and_wines_example/data/models/Product.dart';
import 'package:blankets_and_wines_example/data/models/ProductCategory.dart';
import 'package:blankets_and_wines_example/features/cashier/models/CartItems.dart';
import 'package:blankets_and_wines_example/features/cashier/widgets/DrinkItemCard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MenuPanel extends StatelessWidget {
  final Future<List<ProductCategory>> productsWithCat;
  final String selectedCategory;
  final String searchQuery;
  final TextEditingController searchController;
  final List<CartItem> cart;
  final Function(String) onCategoryChanged;
  final Function(String) onSearchChanged;
  final Function(Product) onAddToCart;
  final VoidCallback onRefresh;

  const MenuPanel({
    Key? key,
    required this.productsWithCat,
    required this.selectedCategory,
    required this.searchQuery,
    required this.searchController,
    required this.cart,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.onAddToCart,
    required this.onRefresh,
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
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, size: 32),
              ),
              onChanged: onSearchChanged,
            ),
          ),

          // Category Tabs
          Container(
            height: BarPOSTheme.buttonHeight,
            margin: EdgeInsets.only(bottom: BarPOSTheme.spacingL),
            child: FutureBuilder<List<ProductCategory>>(
              future: productsWithCat,
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
                    child: Text(
                      'Error loading categories',
                      style: TextStyle(color: BarPOSTheme.errorColor),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No categories available',
                      style: BarPOSTheme.categoryTextStyle,
                    ),
                  );
                }

                final categories = snapshot.data!;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1, // +1 for "All" category
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "All" category button
                      final isSelected = selectedCategory == 'All';
                      return Container(
                        margin: EdgeInsets.only(right: BarPOSTheme.spacingS),
                        child: ElevatedButton(
                          onPressed: () => onCategoryChanged('All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected
                                    ? BarPOSTheme.buttonColor
                                    : BarPOSTheme.accentDark,
                            foregroundColor: BarPOSTheme.primaryText,
                            textStyle: BarPOSTheme.categoryTextStyle,
                          ),
                          child: Text('All'),
                        ),
                      );
                    }
                    
                    final category = categories[index - 1];
                    final isSelected = selectedCategory == category.categoryId.toString();
                    return Container(
                      margin: EdgeInsets.only(right: BarPOSTheme.spacingS),
                      child: ElevatedButton(
                        onPressed: () => onCategoryChanged(category.categoryId.toString()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelected
                                  ? BarPOSTheme.buttonColor
                                  : BarPOSTheme.accentDark,
                          foregroundColor: BarPOSTheme.primaryText,
                          textStyle: BarPOSTheme.categoryTextStyle,
                        ),
                        child: Text(category.categoryName),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Products Grid with RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                onRefresh();
                // Add a small delay to allow the parent to update the Future
                await Future.delayed(Duration(milliseconds: 100));
              },
              color: BarPOSTheme.buttonColor,
              backgroundColor: BarPOSTheme.accentDark,
              child: FutureBuilder<List<ProductCategory>>(
                future: productsWithCat,
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
                            'Error loading products',
                            style: TextStyle(color: BarPOSTheme.errorColor),
                          ),
                          TextButton(
                            onPressed: onRefresh,
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Text(
                            'No products available',
                            style: TextStyle(color: BarPOSTheme.secondaryText),
                          ),
                        ),
                      ),
                    );
                  }

                  // Flatten all products from all categories
                  final allProducts = <Product>[];
                  for (final category in snapshot.data!) {
                    allProducts.addAll(category.products);
                  }

                  // Filter products based on selected category and search query
                  final filteredProducts = allProducts.where((product) {
                    bool categoryMatch = selectedCategory == 'All' ||
                        snapshot.data!.any((cat) => 
                            cat.categoryId.toString() == selectedCategory && 
                            cat.products.contains(product));
                    
                    bool searchMatch = product.name.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    );
                    
                    return categoryMatch && searchMatch;
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Text(
                            'No products found',
                            style: TextStyle(color: BarPOSTheme.secondaryText),
                          ),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: getGridCount(context),
                      crossAxisSpacing: BarPOSTheme.spacingM,
                      mainAxisSpacing: BarPOSTheme.spacingM,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final cartItem = cart.firstWhere(
                        (item) => item.drink.id == product.id,
                        orElse: () => CartItem(drink: product, quantity: 0),
                      );

                      return DrinkItemCard(
                        drink: product,
                        cartQuantity: cartItem.quantity,
                        onTap: () => onAddToCart(product),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}