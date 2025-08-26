
import 'package:blankets_and_wines_example/data/models/DrinkOrder.dart';
import 'package:blankets_and_wines_example/features/OnlineBar.dart/OrderService.dart';
import 'package:flutter/material.dart';

class BartenderPage extends StatefulWidget {
  const BartenderPage({Key? key}) : super(key: key);

  @override
  State<BartenderPage> createState() => _BartenderPageState();
}

class _BartenderPageState extends State<BartenderPage> {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  DrinkOrder? _currentOrder;
  bool _isLoading = false;
  bool _showOtpField = false;
  String _message = '';
  bool _isError = false;

  @override
  void dispose() {
    _orderIdController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _searchOrder() async {
    if (_orderIdController.text.trim().isEmpty) {
      _showMessage('Please enter an order ID', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
      _currentOrder = null;
      _showOtpField = false;
    });

    try {
      final order = await BartenderService.searchOrder(_orderIdController.text.trim());
      setState(() {
        _currentOrder = order;
        _isLoading = false;
      });

      if (order == null) {
        _showMessage('Order not found', isError: true);
      } else if (order.paymentStatus == 2 || order.paymentStatus == 3) { // Assuming 2 = received, 3 = completed
        _showMessage('Order already ${_getStatusText(order.paymentStatus)}', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage(e.toString(), isError: true);
    }
  }

  Future<void> _sendOtp({required Map<String,dynamic> data}) async {
    if (_currentOrder == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await BartenderService.sendOtp(data: data);
      setState(() {
        _isLoading = false;
        _showOtpField = response!.status;
      });

      _showMessage(response!.message, isError: !response.status);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage(e.toString(), isError: true);
    }
  }

  Future<void> _verifyOtp({required Map<String,dynamic> data}) async {
    if (_otpController.text.trim().isEmpty) {
      _showMessage('Please enter OTP', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await BartenderService.verifyOtpAndMarkReceived(
        data: data
 
      );

      setState(() {
        _isLoading = false;
      });

      if (success["status"] == true) {



        setState(() {
          // Create a new order with updated payment status
          _currentOrder = DrinkOrder(
            orderNo: _currentOrder!.orderNo,
            paymentStatus: 2, // Mark as received
            orderDate: _currentOrder!.orderDate,
            orderTotal: _currentOrder!.orderTotal,
            customerFirstName: _currentOrder!.customerFirstName,
            customerLastName: _currentOrder!.customerLastName,
            customerEmail: _currentOrder!.customerEmail,
            customerPhone: _currentOrder!.customerPhone,
            orderItems: _currentOrder!.orderItems,
          );
          _showOtpField = false;
        });
        _showMessage('Order marked as received!', isError: false);
        _otpController.clear();
      } else {
        _showMessage(success["message"], isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage(e.toString(), isError: true);
    }
  }

  Future<void> _markAsCollected() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await BartenderService.markAsCollected(_currentOrder!.orderNo);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        setState(() {
          // Create a new order with updated payment status
          _currentOrder = DrinkOrder(
            orderNo: _currentOrder!.orderNo,
            paymentStatus: 3, // Mark as completed
            orderDate: _currentOrder!.orderDate,
            orderTotal: _currentOrder!.orderTotal,
            customerFirstName: _currentOrder!.customerFirstName,
            customerLastName: _currentOrder!.customerLastName,
            customerEmail: _currentOrder!.customerEmail,
            customerPhone: _currentOrder!.customerPhone,
            orderItems: _currentOrder!.orderItems,
          );
        });
        _showMessage('Order marked as collected!', isError: false);
      } else {
        _showMessage('Failed to mark order as collected', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage(e.toString(), isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    setState(() {
      _message = message;
      _isError = isError;
    });
  }

  void _clearSearch() {
    setState(() {
      _orderIdController.clear();
      _otpController.clear();
      _currentOrder = null;
      _showOtpField = false;
      _message = '';
    });
  }

  String _getStatusText(int paymentStatus) {
    switch (paymentStatus) {
      case 0:
        return 'pending';
      case 1:
        return 'paid';
      case 2:
        return 'received';
      case 3:
        return 'completed';
      default:
        return 'unknown';
    }
  }

  String _getCustomerFullName() {
    return '${_currentOrder!.customerFirstName} ${_currentOrder!.customerLastName}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Bartender Orders'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          if (_currentOrder != null)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearSearch,
              tooltip: 'Clear',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchCard(theme, colorScheme),
            SizedBox(height: 16),
            _buildMessageCard(theme, colorScheme),
            if (_isLoading) _buildLoadingCard(theme, colorScheme),
            if (_currentOrder != null) _buildOrderCard(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: colorScheme.primary,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Search Order',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _orderIdController,
              decoration: InputDecoration(
                labelText: 'Enter Order Number',
                hintText: 'e.g., ORD001',
                prefixIcon: Icon(Icons.receipt),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabled: !_isLoading,
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _searchOrder(),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _searchOrder,
              icon: Icon(Icons.search),
              label: Text('Search Order'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(ThemeData theme, ColorScheme colorScheme) {
    if (_message.isEmpty) return SizedBox.shrink();

    return Card(
      elevation: 1,
      color: _isError 
          ? colorScheme.errorContainer 
          : colorScheme.primaryContainer,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isError ? Icons.error : Icons.check_circle,
              color: _isError 
                  ? colorScheme.error 
                  : colorScheme.primary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _message,
                style: TextStyle(
                  color: _isError 
                      ? colorScheme.error 
                      : colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing...', style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(ThemeData theme, ColorScheme colorScheme) {
    final canProcess = _currentOrder!.paymentStatus != 3 && 
                     _currentOrder!.paymentStatus != 2;
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(theme, colorScheme),
            Divider(height: 30),
            _buildDrinksList(theme, colorScheme),
            Divider(height: 30),
            if (canProcess) _buildOrderActions(theme, colorScheme),
            if (!canProcess) _buildOrderStatus(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order #${_currentOrder!.orderNo}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_currentOrder!.paymentStatus, colorScheme),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(_currentOrder!.paymentStatus).toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.person, color: colorScheme.onSurfaceVariant),
            SizedBox(width: 8),
            Text(
              _getCustomerFullName(),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.phone, color: colorScheme.onSurfaceVariant),
            SizedBox(width: 8),
            Text(
              _currentOrder!.customerPhone,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.email, color: colorScheme.onSurfaceVariant),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentOrder!.customerEmail,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today, color: colorScheme.onSurfaceVariant),
            SizedBox(width: 8),
            Text(
              '${_currentOrder!.orderDate.day}/${_currentOrder!.orderDate.month}/${_currentOrder!.orderDate.year} ${_currentOrder!.orderDate.hour}:${_currentOrder!.orderDate.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrinksList(ThemeData theme, ColorScheme colorScheme) {






    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drinks Ordered:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ...(_currentOrder!.orderItems.map((item) => Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_drink, // Generic drink icon since category is not available
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                 
                      item.productName ?? 'Unknown Product',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Qty: ${item.quantity}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'KSH ${(item.price * item.quantity).toStringAsFixed(0)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ))),
        Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'KSH ${_currentOrder!.orderTotal.toStringAsFixed(0)}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderActions(ThemeData theme, ColorScheme colorScheme) {
    final status = _currentOrder!.paymentStatus;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == 0 || status == 1) ...[ // pending or paid
          ElevatedButton.icon(
            onPressed: _isLoading ? null :(){
              _sendOtp(data: {
               "orderNo": _currentOrder!.orderNo,

"customerFirstName":_currentOrder!.customerFirstName,
"customerEmail": _currentOrder!.customerEmail,
"customerPhone": _currentOrder!.customerPhone,

              });
            } ,
            icon: Icon(Icons.message),
            label: Text('Send OTP to Customer'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_showOtpField) ...[
            SizedBox(height: 16),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'Enter OTP from Customer',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              enabled: !_isLoading,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null :(){
                _verifyOtp(data: {
                  "orderNo": _currentOrder!.orderNo,
                  "otp": _otpController.text.trim(),
                });
              } ,
              icon: Icon(Icons.verified),
              label: Text('Verify & Mark as Received'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ] else if (status == 2) ...[ // received
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Verified & Ready',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Customer can now collect their drinks',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _markAsCollected,
            icon: Icon(Icons.check_circle_outline),
            label: Text('Mark as Collected'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(16),
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderStatus(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 12),
          Text(
            'Order ${_getStatusText(_currentOrder!.paymentStatus).toUpperCase()}',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int paymentStatus, ColorScheme colorScheme) {
    switch (paymentStatus) {
      case 0: // pending
        return Colors.orange;
      case 1: // paid
        return Colors.blue;
      case 2: // received
        return Colors.blue;
      case 3: // completed
        return Colors.green;
      default:
        return colorScheme.primary;
    }
  }
}