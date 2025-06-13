import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/features/cashier/models/CartItems.dart';
import 'package:blankets_and_wines_example/features/cashier/widgets/Cartitem.dart';
import 'package:blankets_and_wines_example/features/cashier/widgets/payments.dart';
import 'package:flutter/material.dart';

class CartPanel extends StatelessWidget {
  final List<CartItem> cart;
  final double cartTotal;
  final bool isLargeScreen;
  final Function(int) onRemoveFromCart;
  final Function(int, int) onUpdateQuantity;
  final VoidCallback onClearCart;
  final VoidCallback onShowPayment;
  final VoidCallback onCloseCart;

  const CartPanel({
    Key? key,
    required this.cart,
    required this.cartTotal,
    required this.isLargeScreen,
    required this.onRemoveFromCart,
    required this.onUpdateQuantity,
    required this.onClearCart,
    required this.onShowPayment,
    required this.onCloseCart,
  }) : super(key: key);

  // Calculate the correct total from cart items
  double get _calculatedTotal {
    return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void _showPaymentOptions(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: BarPOSTheme.primaryText,
            ),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width*0.55,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Amount: KSHS ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: BarPOSTheme.successColor,
                  ),
                ),
                SizedBox(height: 20),
                _buildPaymentOption(
                  context,
                  'M-Pesa',
                  Icons.phone_android,
                  Colors.green,
                  () => _handleMpesaPayment(context),
                ),
                SizedBox(height: 12),
                _buildPaymentOption(
                  context,
                  'Card Payment',
                  Icons.credit_card,
                  Colors.blue,
                  () =>{},
                  //  _handleCardPayment(context),
                ),
                // SizedBox(height: 12),
                // _buildPaymentOption(
                //   context,
                //   'Cash',
                //   Icons.money,
                //   Colors.orange,
                //   () => _handleCashPayment(context),
                // ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: BarPOSTheme.errorColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: BarPOSTheme.primaryText,
              ),
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _handleMpesaPayment(BuildContext context) {
    Navigator.of(context).pop(); // Close payment options dialog
    
    // Show M-Pesa payment dialog
    Payments.showMpesaPayment(
      context: context,
      amount: _calculatedTotal,
      onPaymentComplete: (bool success, String? transactionId) {
        if (success) {
          _showPaymentSuccess(context, 'M-Pesa', transactionId);
        } else {
          _showPaymentError(context, 'M-Pesa payment failed. Please try again.');
        }
      },
    );
  }

  void _handleCardPayment(BuildContext context) {
    Navigator.of(context).pop(); // Close payment options dialog
    
    // Show Card payment dialog
    Payments.showCardPayment(
      context: context,
      amount: _calculatedTotal,
      onPaymentComplete: (bool success, String? transactionId) {
        if (success) {
          _showPaymentSuccess(context, 'Card', transactionId);
        } else {
          _showPaymentError(context, 'Card payment failed. Please try again.');
        }
      },
    );
  }

  // void _handleCashPayment(BuildContext context) {
  //   Navigator.of(context).pop(); // Close payment options dialog
    
  //   // Show Cash payment dialog
  //   Payments.showCashPayment(
  //     context: context,
  //     amount: _calculatedTotal,
  //     onPaymentComplete: (bool success, String? transactionId) {
  //       if (success) {
  //         _showPaymentSuccess(context, 'Cash', transactionId);
  //       } else {
  //         _showPaymentError(context, 'Cash payment cancelled.');
  //       }
  //     },
  //   );
  // }

  void _showPaymentSuccess(BuildContext context, String paymentMethod, String? transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: BarPOSTheme.successColor, size: 28),
              SizedBox(width: 12),
              Text('Payment Successful!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment Method: $paymentMethod'),
              Text('Amount: KSHS ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}'),
              if (transactionId != null) Text('Transaction ID: $transactionId'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close success dialog
                onClearCart(); // Clear the cart
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BarPOSTheme.successColor,
              ),
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: BarPOSTheme.errorColor, size: 28),
              SizedBox(width: 12),
              Text('Payment Failed'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        onPressed: onClearCart,
                        icon: Icon(
                          Icons.clear_all,
                          color: BarPOSTheme.errorColor,
                          size: 28,
                        ),
                      ),
                    if (!isLargeScreen)
                      IconButton(
                        onPressed: onCloseCart,
                        icon: Icon(Icons.close, size: 28),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Cart Items
          Expanded(
            child: cart.isEmpty
                ? _buildEmptyCart(context)
                : _buildCartItems(),
          ),

          // Total and Checkout
          if (cart.isNotEmpty) _buildCheckoutSection(context),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
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
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: BarPOSTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: BarPOSTheme.spacingL),
      itemCount: cart.length,
      itemBuilder: (context, index) {
        final item = cart[index];
        return CartItemTile(
          cartItem: item,
          onRemove: () => onRemoveFromCart(item.drink.id),
          onUpdateQuantity: (quantity) => 
              onUpdateQuantity(item.drink.id, quantity),
        );
      },
    );
  }

  Widget _buildCheckoutSection(BuildContext context) {
    return Container(
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
                'KSHS ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
                style: BarPOSTheme.totalPriceTextStyle,
              ),
            ],
          ),
          SizedBox(height: BarPOSTheme.spacingL),
          SizedBox(
            width: double.infinity,
            height: BarPOSTheme.buttonHeight,
            child: ElevatedButton(
              onPressed: () => _showPaymentOptions(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: BarPOSTheme.successColor,
                foregroundColor: BarPOSTheme.primaryText,
              ),
              child: Text('Confirm Payment'),
            ),
          ),
        ],
      ),
    );
  }
}