import 'dart:io';

import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/features/Stockist/Stockist.dart';
import 'package:blankets_and_wines_example/features/cashier/Auth/Login.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  users? _selectedUserType;
  bool _isLoading = false;
  bool _hasInternet = true;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkNetworkConnection();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      setState(() {
        _hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });

      if (!_hasInternet) {
        ToastService.showError(
          'No internet connection. Please check your network settings.',
        );
      }
    } catch (e) {
      setState(() => _hasInternet = false);
      ToastService.showError('Network check failed. Please try again.');
    }
  }

  Future<void> _handleContinue() async {
    if (_selectedUserType == null) {
      ToastService.showError('Please select a user type to continue');
      return;
    }

    if (!_hasInternet) {
      await _checkNetworkConnection();
      if (!_hasInternet) {
        ToastService.showError('Internet connection required to continue');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Simulate network request or save user preference
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate based on user type
      if (_selectedUserType == users.cashier) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CashierLoginPage()),
        );
      } else if (_selectedUserType == users.stockist) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StockistMainScreen()),
        );
      } else {
        ToastService.showInfo(
          'Welcome! Please contact support for account setup.',
        );
      }
    } catch (e) {
      ToastService.showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getUserTypeTitle(users userType) {
    switch (userType) {
      case users.cashier:
        return 'Cashier';
      case users.stockist:
        return 'Stockist';
      case users.nobody:
        return 'Guest';
    }
  }

  String _getUserTypeDescription(users userType) {
    switch (userType) {
      case users.cashier:
        return 'Process payments and manage sales transactions';
      case users.stockist:
        return 'Manage inventory and stock levels';
      case users.nobody:
        return 'Browse as a guest user';
    }
  }

  IconData _getUserTypeIcon(users userType) {
    switch (userType) {
      case users.cashier:
        return Icons.point_of_sale;
      case users.stockist:
        return Icons.inventory_2;
      case users.nobody:
        return Icons.person_outline;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: BarPOSTheme.secondaryDark,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder:
                (context, child) => Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: _slideAnimation.value * 50,
                    child: _buildContent(),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Logo section
          Container(
            padding: const EdgeInsets.all(10),
            width: MediaQuery.of(context).size.width * 0.65,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Image.network(
              "https://blanketsandwine.com/kenya/wp-content/themes/blankets2020/library/img/logo.png",
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    color: Colors.white,
                    size: 40,
                  ),
            ),
          ),

          const SizedBox(height: 24),

          // Title section
          const Text(
            'Welcome to BarPOS',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          const Text(
            'Select your role to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Network status indicator
          if (!_hasInternet)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'No internet connection',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _checkNetworkConnection,
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.red,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

          // User type selection
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Choose Your Role',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // User type options
                ...users.values.map((userType) => _buildUserTypeCard(userType)),

                const SizedBox(height: 24),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading || _selectedUserType == null)
                            ? null
                            : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BarPOSTheme.successColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Help text
          Text(
            'Need help? Contact support',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard(users userType) {
    final isSelected = _selectedUserType == userType;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedUserType = userType;
              user = userType;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected
                        ? BarPOSTheme.successColor
                        : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              color:
                  isSelected
                      ? BarPOSTheme.successColor.withOpacity(0.1)
                      : Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? BarPOSTheme.successColor
                            : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getUserTypeIcon(userType),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getUserTypeTitle(userType),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected
                                  ? BarPOSTheme.successColor
                                  : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getUserTypeDescription(userType),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: BarPOSTheme.successColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
