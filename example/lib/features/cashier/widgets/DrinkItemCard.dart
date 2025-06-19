import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/data/models/DrinkItem.dart';
import 'package:blankets_and_wines_example/data/models/Product.dart';
import 'package:flutter/material.dart';

class DrinkItemCard extends StatelessWidget {
  final Product drink;
  final int cartQuantity;
  final VoidCallback onTap;

  const DrinkItemCard({
    Key? key,
    required this.drink,
    required this.cartQuantity,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isInCart = cartQuantity > 0;
    final screenSize = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    // Optimized for Android POS devices (typically 7-10 inch tablets)
    final isCompactDevice = screenSize.width < 600;
    final isTabletDevice = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeDevice = screenSize.width >= 1200;
    
    // Dynamic sizing for Android POS devices
    double cardPadding = isCompactDevice ? 12.0 : (isTabletDevice ? 16.0 : 20.0);
    double iconContainerSize = isCompactDevice ? 60.0 : (isTabletDevice ? 70.0 : 80.0);
    double iconSize = isCompactDevice ? 32.0 : (isTabletDevice ? 40.0 : 48.0);
    double verticalSpacing = isCompactDevice ? 8.0 : (isTabletDevice ? 12.0 : 16.0);
    double badgeSize = isCompactDevice ? 28.0 : (isTabletDevice ? 32.0 : 36.0);
    double badgeFontSize = isCompactDevice ? 16.0 : (isTabletDevice ? 18.0 : 20.0);

    return GestureDetector(
      onTap:  onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isInCart 
              ? BarPOSTheme.successColor.withOpacity(0.15) 
              : BarPOSTheme.secondaryDark,
          borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
          border: Border.all(
            color: isInCart 
                ? BarPOSTheme.successColor.withOpacity(0.5) 
                : BarPOSTheme.accentDark.withOpacity(0.3),
            width: isInCart ? 3.0 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            if (isInCart)
              BoxShadow(
                color: BarPOSTheme.successColor.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon container with better proportions
                    Container(
                    width: iconContainerSize * 1.5,
                    height: iconContainerSize * 1.5,
                    decoration: BoxDecoration(
                      color: BarPOSTheme.buttonColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(iconContainerSize / 2),
                    ),
                    child: Center(
                      child: Image.network(
                      drink.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: verticalSpacing),
                  
                  // Product name with better text handling for outdoor visibility
                  Flexible(
                    child: Text(
                      drink.name,
                      style: BarPOSTheme.itemNameTextStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        height: 1.3,
                        fontSize: isCompactDevice ? 18.0 : (isTabletDevice ? 22.0 : 26.0),
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  SizedBox(height: verticalSpacing * 0.5),
                  
                  // Stock quantity display
                  if (drink.stock > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompactDevice ? 12.0 : 16.0,
                        vertical: isCompactDevice ? 6.0 : 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: _getStockColor(drink.stock).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _getStockColor(drink.stock).withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: isCompactDevice ? 14.0 : 16.0,
                            color: _getStockColor(drink.stock),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${drink.stock} in stock',
                            style: TextStyle(
                              color: _getStockColor(drink.stock),
                              fontSize: isCompactDevice ? 12.0 : (isTabletDevice ? 14.0 : 16.0),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: verticalSpacing * 0.75),
                  
                  // Price container with enhanced visibility for outdoor use
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactDevice ? 16.0 : 20.0,
                      vertical: isCompactDevice ? 10.0 : 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: BarPOSTheme.buttonColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: BarPOSTheme.buttonColor.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'KSH ${formatWithCommas( drink.price.toStringAsFixed(0))}',
                      style: BarPOSTheme.priceTextStyle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: isCompactDevice ? 17.0 : (isTabletDevice ? 20.0 : 24.0),
                        color: BarPOSTheme.buttonColor,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                            color: Colors.black.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Stock indicator
            if (drink.stock <= 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.block,
                          color: Colors.red[300],
                          size: isCompactDevice ? 40 : (isTabletDevice ? 50 : 60),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isCompactDevice ? 16 : (isTabletDevice ? 20 : 24),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            
            // Cart quantity badge with better positioning
            if (isInCart)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BarPOSTheme.successColor,
                          BarPOSTheme.successColor.withGreen(220),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(badgeSize / 2),
                      boxShadow: [
                        BoxShadow(
                          color: BarPOSTheme.successColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        cartQuantity > 99 ? '99+' : '$cartQuantity',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: badgeFontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Ripple effect overlay
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(BarPOSTheme.radiusMedium),
                  splashColor: BarPOSTheme.buttonColor.withOpacity(0.15),
                  highlightColor: BarPOSTheme.buttonColor.withOpacity(0.08),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to determine stock color based on quantity
  Color _getStockColor(int stock) {
    if (stock <= 5) {
      return Colors.red[600]!; // Low stock - red
    } else if (stock <= 15) {
      return Colors.orange[600]!; // Medium stock - orange
    } else {
      return Colors.green[600]!; // High stock - green
    }
  }
}