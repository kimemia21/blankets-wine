import 'dart:io';
import 'dart:async';

import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/data/models/UserRoles.dart';
import 'package:blankets_and_wines_example/data/services/FetchGlobals.dart';
import 'package:blankets_and_wines_example/features/Stockist/Stockist.dart';
import 'package:blankets_and_wines_example/features/cashier/Auth/Login.dart';
import 'package:blankets_and_wines_example/widgets/servigram.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OnboardingPage extends StatefulWidget {
  final bool wasFromLogin;
  const OnboardingPage({required this.wasFromLogin});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  String? _selectedUserType;
  int? _selectedUserId;
  bool _isLoading = false;
  bool _hasInternet = true;
  bool _isInitialized = false;
  bool _disposed = false;

  // Cached data with Map for O(1) lookup
  List<UserRoles>? _cachedRoles;
  Map<String, UserRoles> _rolesMap = {};
  Timer? _networkTimer;

  // Animation controller - optimized
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Pre-computed icon map for O(1) lookup
  static const Map<String, IconData> _iconMap = {
    'Super Admin': Icons.admin_panel_settings,
    'Cashier': Icons.point_of_sale,
    'Stockist': Icons.inventory_2,
    'Steward': Icons.room_service,
    'Cowgirl': Icons.person,
    'Store Keeper': Icons.store,
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAsync();
  }

  // Optimized single initialization method
  Future<void> _initializeAsync() async {
    if (_disposed) return;
    
    // Load preferences in parallel for better performance
    final preferenceFutures = [
      preferences.getUserRole(),
      preferences.getUserRoleId(),
      preferences.isUserLoggedIn(),
    ];

    try {
      final results = await Future.wait(preferenceFutures);
      if (_disposed) return;

      _selectedUserType = results[0] as String?;
      _selectedUserId = results[1] as int?;
      final isLoggedIn = results[2] as bool;

      // Early navigation for logged-in users
      if (isLoggedIn && !widget.wasFromLogin && _selectedUserType != null) {
        return nextScreenNavigator(_selectedUserType!, _selectedUserId!);
      }

      // Run network operations in parallel with role loading
      final futures = <Future>[
        _loadUserRoles(),
        _checkNetworkConnection(),
      ];
      
      await Future.wait(futures);
      _setupPeriodicNetworkCheck();

      if (mounted && !_disposed) {
        setState(() => _isInitialized = true);
        _animationController.forward();
      }
    } catch (e) {
      if (!_disposed && mounted) {
        ToastService.showError("Initialization failed: $e");
        setState(() => _isInitialized = true);
        _animationController.forward();
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Reduced from 400ms
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadUserRoles() async {
    if (_disposed || _cachedRoles != null) return; // Already cached

    try {
      final roles = await fetchGlobal<UserRoles>(
        getRequests: (endpoint) => comms.getRequests(endpoint: endpoint),
        fromJson: (json) => UserRoles.fromJson(json),
        endpoint: "users/roles",
      );
      
      if (_disposed) return;
      
      _cachedRoles = roles;
      // Build Map for O(1) lookups
      _rolesMap = {for (var role in roles) role.name: role};
      
    } catch (e) {
      if (!_disposed) {
        ToastService.showError("Failed to load roles: $e");
        print('Error loading user roles: $e');
        // Set empty list to prevent infinite loading
        _cachedRoles = [];
      }
    }
  }

  Future<void> _checkNetworkConnection() async {
    if (_disposed) return;
    
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 1500)); // Reduced from 2s

      if (_disposed) return;
      
      final hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (mounted && _hasInternet != hasInternet) {
        setState(() => _hasInternet = hasInternet);
      }
    } catch (e) {
      if (_disposed) return;
      if (mounted && _hasInternet) {
        setState(() => _hasInternet = false);
      }
    }
  }

  void _setupPeriodicNetworkCheck() {
    if (_disposed) return;
    _networkTimer = Timer.periodic(
      const Duration(seconds: 8), // Increased from 5s to reduce overhead
      (_) => _checkNetworkConnection(),
    );
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
    nextScreenNavigator(_selectedUserType!, _selectedUserId!);
  }

  IconData _getUserTypeIcon(String userType) {
    return _iconMap[userType] ?? Icons.person_outline;
  }

  void nextScreenNavigator(String userType, int userRole) async {
  
    if (_disposed) return;
    
    try {
      // Remove artificial delay for faster navigation
      // await Future.delayed(const Duration(milliseconds: 200));

      // Navigate based on user type
      final users selectedRole = stringToUser(userType);
      
      // Update preferences in parallel
      await Future.wait([
        preferences.updateUserRole(userType),
        preferences.updateUserRoleId(userRole),
      ]);
      
      userData.copyWith(userRole: userType);
      
      if (_disposed || !mounted) return;

     
      
      
      if (selectedRole == users.cashier||selectedRole == users.stockist|| selectedRole == users.bartender) {
         Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      
      } 
       else {
        ToastService.showInfo(
          'Welcome! Please contact support for account setup.',
        );
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (_disposed) return;
      ToastService.showError('Something went wrong. Please try again.$e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _networkTimer?.cancel();
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
          child: _isInitialized
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(),
                )
              : _buildLoadingState(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated progress
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              color: Colors.pinkAccent,
            ),
          ),
          const SizedBox(height: 20),

          // Vibrant loading text
          Text(
            '🎪 Rolling out the red carpet...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  blurRadius: 6,
                  color: Colors.black54,
                  offset: Offset(1, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '...or should we say, blanket? 🧺',
            style: TextStyle(
              color: Colors.amberAccent.shade100,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildLogoSection(),
          const SizedBox(height: 24),
          _buildTitleSection(),
          const SizedBox(height: 32),
          _buildNetworkIndicator(),
          _buildUserTypeSelection(),
          const SizedBox(height: 24),
          _buildHelpText(),
          servigram(),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width * 0.65,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Image.asset("assets/images/logo.png", fit: BoxFit.contain),
    );
  }

  Widget _buildTitleSection() {
    return const Column(
      children: [
        Text(
          'Welcome',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Select your role to get started',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNetworkIndicator() {
    if (_hasInternet) return const SizedBox.shrink();

    return Container(
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
            child: const Icon(Icons.refresh, color: Colors.red, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelection() {
    return Container(
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
          _buildRolesList(),
          const SizedBox(height: 24),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildRolesList() {
    if (_cachedRoles == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_cachedRoles!.isEmpty) {
      return const Center(
        child: Text(
          'No roles available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: _cachedRoles!.map((role) => _buildUserTypeCard(role)).toList(),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (_isLoading || _selectedUserType == null) ? null : _handleContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: BarPOSTheme.successColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildHelpText() {
    return Text(
      'Need help? Contact support',
      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUserTypeCard(UserRoles user) {
    final isSelected = _selectedUserType == user.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Remove async operations from tap for immediate response  
            setState(() {
              _selectedUserType = user.name;
              _selectedUserId = user.id;
            });
            // Defer preference saving until continue is pressed for better UX
            // This makes selection feel instant
            _deferredUpdatePreferences(user.name, user.id);
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100), // Reduced from 150ms
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? BarPOSTheme.successColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? BarPOSTheme.successColor.withOpacity(0.1)
                  : Colors.grey.shade50,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100), // Reduced from 150ms
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? BarPOSTheme.successColor : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getUserTypeIcon(user.name),
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
                        user.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? BarPOSTheme.successColor : Colors.black87,
                        ),
                      ),
                      if (user.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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

  // Deferred preference update to avoid blocking UI
  void _deferredUpdatePreferences(String userType, int userId) {
    Future.microtask(() async {
      if (!_disposed) {
        try {
          await Future.wait([
            preferences.updateUserRole(userType),
            preferences.updateUserRoleId(userId),
          ]);
        } catch (e) {
          // Silent fail - preferences will be updated on continue anyway
          print('Deferred preference update failed: $e');
        }
      }
    });
  }
}