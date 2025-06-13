import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/features/cashier/models/CartItems.dart';
import 'package:flutter/material.dart';

class CartItemTile extends StatefulWidget {
  final CartItem cartItem;
  final VoidCallback onRemove;
  final Function(int) onUpdateQuantity;

  const CartItemTile({
    Key? key,
    required this.cartItem,
    required this.onRemove,
    required this.onUpdateQuantity,
  }) : super(key: key);

  @override
  _CartItemTileState createState() => _CartItemTileState();
}

class _CartItemTileState extends State<CartItemTile> {
  bool _isEditing = false;
  late TextEditingController _quantityController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _focusNode = FocusNode();
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _finishEditing();
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _quantityController.text = widget.cartItem.quantity.toString();
    });
    
    // Focus and select all text after a brief delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _quantityController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _quantityController.text.length,
      );
    });
  }

  void _finishEditing() {
    if (_isEditing) {
      final newQuantity = int.tryParse(_quantityController.text) ?? widget.cartItem.quantity;
      final validQuantity = newQuantity > 0 ? newQuantity : 1;
      
      if (validQuantity != widget.cartItem.quantity) {
        widget.onUpdateQuantity(validQuantity);
      }
      
      // Explicitly unfocus and clear editing state
      _focusNode.unfocus();
      setState(() {
        _isEditing = false;
      });
    }
  }

  // Handle taps outside the editing area
  void _handleTapOutside() {
    if (_isEditing) {
      _finishEditing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Detect taps outside the editing area
      onTap: _handleTapOutside,
      child: Container(
        margin: EdgeInsets.only(bottom: BarPOSTheme.spacingS),
        padding: BarPOSTheme.cardPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Product info row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cartItem.drink.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Ksh ${widget.cartItem.totalPrice}',
                        style: TextStyle(
                          fontSize: 18,
                          color: BarPOSTheme.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Controls row
            Row(
              children: [
                // Remove quantity button
                Expanded(
                  child: Container(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: widget.cartItem.quantity > 1 
                          ? () {
                              // Stop editing if active, then update quantity
                              if (_isEditing) _finishEditing();
                              widget.onUpdateQuantity(widget.cartItem.quantity - 1);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.cartItem.quantity > 1 ? Colors.orange : Colors.grey[300],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 28,
                        color: widget.cartItem.quantity > 1 ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 12),
                
                // Quantity display - now clickable and editable
                GestureDetector(
                  onDoubleTap: () {
                    // Prevent the outer GestureDetector from interfering
                    _startEditing();
                  },
                  child: Container(
                    width: 80,
                    height: 56,
                    decoration: BoxDecoration(
                      color:  Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isEditing ? Colors.blue : Colors.grey[300]!, 
                        width: _isEditing ? 3 : 2,
                      ),
                    ),
                    child: _isEditing
                        ? TextField(
                            controller: _quantityController,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            // Handle "Done" button press (submit)
                            onSubmitted: (_) => _finishEditing(),
                            // Handle individual text changes if needed
                            onChanged: (value) {
                              // Optional: Handle real-time validation here
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${widget.cartItem.quantity}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Double tap',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                
                SizedBox(width: 12),
                
                // Add quantity button
                Expanded(
                  child: Container(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Stop editing if active, then update quantity
                        if (_isEditing) _finishEditing();
                        widget.onUpdateQuantity(widget.cartItem.quantity + 1);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 12),
                
                // Delete button
                Container(
                  height: 56,
                  width: 56,
                  child: ElevatedButton(
                    onPressed: () {

                      // Stop editing if active, then remove item
                      if (_isEditing) _finishEditing();
                      widget.onRemove();
                      
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}