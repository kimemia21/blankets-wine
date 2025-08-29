import 'dart:ui';
import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/features/cashier/widgets/Cartitem.dart';
import 'package:blankets_and_wines_example/features/cashier/widgets/payments.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class CartPanel extends StatefulWidget {
  final double cartTotal;
  final bool isLargeScreen;
  final Function(int) onRemoveFromCart;
  final Function(int, int) onUpdateQuantity;
  final VoidCallback onClearCart;
  final VoidCallback onCloseCart;
  final VoidCallback onPaymentConfirm;

  const CartPanel({
    Key? key,
    required this.cartTotal,
    required this.isLargeScreen,
    required this.onRemoveFromCart,
    required this.onUpdateQuantity,
    required this.onClearCart,
    required this.onCloseCart,
    required this.onPaymentConfirm,
  }) : super(key: key);

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  bool isLoading = false;
  String orderNumber = "";


  @override
  void initState() {
    super.initState();
    // _paymentService = PaymentDialogWidget(
    //   orderNumber: orderNumber,
    //   total: _calculatedTotal,
    //   isOffline: false,
    //   onPaymentComplete: _handlePaymentComplete,
    //   onOrderNumberGenerated: (orderId) => setState(() => orderNumber = orderId),
    // );
  }

  double get _calculatedTotal => cartG.total;

  void _handlePaymentComplete() {
    cartG.items.clear();
    widget.onClearCart();
    widget.onPaymentConfirm();
  }

  Future<void> createOrder() async {
    if (isLoading) return;
    
    setState(() => isLoading = true);
    
    try {
      bool hasInternet = await InternetConnection().hasInternetAccess;
      
      if (hasInternet) {
        // Online flow - create order first, then show payment
        final response = await comms.postRequest(
          endpoint: "orders",
          data: cartG.toOrderFormat(),
        );

        if (response["rsp"]["success"]) {
          setState(() => orderNumber = response["rsp"]["data"]["orderNo"]);
    showPaymentDialog(
  context, 
  orderNumber, 
  _calculatedTotal, 

  false, // isOffline
  onPaymentComplete: _handlePaymentComplete,
  onOrderNumberGenerated: (String orderNumber) {
    // Your order number handling logic here
  },
);
        } else {
          ToastService.showError(response["rsp"]["message"] ?? "Failed to create order");
        }
      } else {
        // Offline flow - generate local order ID and show offline payment
        setState(() => orderNumber = "OFF-${DateTime.now().millisecondsSinceEpoch}");
       showPaymentDialog(
  context, 
  orderNumber, 
  _calculatedTotal, 
  true, // isOffline
  onPaymentComplete:_handlePaymentComplete,
 onOrderNumberGenerated: (orderId) => setState(() => orderNumber = orderId),
);
      }
    } catch (e) {
      ToastService.showError('Error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: BarPOSTheme.accentDark),
      child: Column(
        children: [
          // Header
          Container(
            padding: BarPOSTheme.cardPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current Order', style: Theme.of(context).textTheme.headlineSmall),
                Row(
                  children: [
                    if (cartG.items.isNotEmpty)
                      IconButton(
                        onPressed: widget.onClearCart,
                        icon: Icon(Icons.clear_all, color: BarPOSTheme.errorColor, size: 28),
                      ),
                    if (!widget.isLargeScreen)
                      IconButton(
                        onPressed: widget.onCloseCart,
                        icon: Icon(Icons.close, size: 28),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Cart Items
          Expanded(
            child: cartG.items.isEmpty ? _buildEmptyCart() : _buildCartItems(),
          ),

          // Checkout
          if (cartG.items.isNotEmpty) _buildCheckoutSection(),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, color: BarPOSTheme.secondaryText, size: 64),
          SizedBox(height: BarPOSTheme.spacingM),
          Text('No items in order', style: TextStyle(color: BarPOSTheme.secondaryText)),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: BarPOSTheme.spacingL),
      itemCount: cartG.items.length,
      itemBuilder: (context, index) {
        final item = cartG.items[index];
        return CartItemTile(
          cartItem: item,
          onRemove: () => widget.onRemoveFromCart(item.drink.id),
          onUpdateQuantity: (quantity) => widget.onUpdateQuantity(item.drink.id, quantity),
        );
      },
    );
  }

  Widget _buildCheckoutSection() {
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
              Text('Total:', style: Theme.of(context).textTheme.headlineSmall),
              Text(
                'KSH ${formatWithCommas(_calculatedTotal.toStringAsFixed(0))}',
                style: BarPOSTheme.totalPriceTextStyle,
              ),
            ],
          ),
          SizedBox(height: BarPOSTheme.spacingL),
          SizedBox(
            width: double.infinity,
            height: BarPOSTheme.buttonHeight,
            child: ElevatedButton(
              onPressed: isLoading ? null : createOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: BarPOSTheme.successColor,
                foregroundColor: BarPOSTheme.primaryText,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: BarPOSTheme.primaryText,
                      ),
                    )
                  : Text('Process Payment', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}