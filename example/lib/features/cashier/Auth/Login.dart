import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/theme/theme.dart';
import 'package:blankets_and_wines_example/core/utils/Comms.dart';
import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/data/models/UserRoles.dart';
import 'package:blankets_and_wines_example/data/services/FetchGlobals.dart';
import 'package:blankets_and_wines_example/features/Stockist/Stockist.dart';
import 'package:blankets_and_wines_example/features/cashier/Auth/authfunc.dart';
import 'package:blankets_and_wines_example/features/cashier/main/CashierMain.dart';
import 'package:blankets_and_wines_example/onBoarding/OnBoarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // User data from preferences
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _userRole;
  String? _lastLogin;
  bool _isReturningUser = false;

  // Single animation controller instead of multiple
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Single controller for both animations
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

  @override
  void dispose() {
    _animationController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Load user data from preferences
  Future<void> _loadUserData() async {
    try {
      _userRole = await preferences.getUserRole();
      if (await preferences.isUserLoggedIn()) {
        _userName = userData.username;
        _userEmail = userData.username;
        _userPhone = userData.phoneNumber;
      }

      // Check if user has logged in before
      if (_userName != null && _userName!.isNotEmpty) {
        setState(() {
          _isReturningUser = true;
          // Pre-fill phone number if available
          if (_userPhone != null) {
            _phoneNumberController.text = _userPhone!;
          }
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> data = {
        "username": _phoneNumberController.text,
        "password": _passwordController.text,
        "role": (await preferences.getUserRoleId()),
      };
      bool login = await CashierAuth.login(data: data);
      if (login) {
        await preferences.saveUserData(
          userRole: _userRole!,
          username: _phoneNumberController.text,
          password: _passwordController.text,
          phoneNumber: _phoneNumberController.text,
          userRoleId: (await preferences.getUserRoleId()) ?? 0,
        );
        print(await preferences.getUserData());

        userData = (await preferences.getUserData())!;

        setState(() => _isLoading = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => homepageNavigator(stringToUser(userData.userRole)),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        print("Failed");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget homepageNavigator(users user) {
    switch (user) {
      case users.cashier:
        return Cashier();
      case users.stockist:
        return StockistMainScreen();
      default:
        return Cashier();
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _isPasswordVisible = !_isPasswordVisible);
  }

  String _formatLastLogin(String? lastLogin) {
    if (lastLogin == null) return '';
    try {
      final DateTime loginDate = DateTime.parse(lastLogin);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(loginDate);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return 'Recently';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                    child: _buildContent(theme, colorScheme),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Logo section
          Container(
            padding: EdgeInsets.all(10),
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
            ),
          ),

          const SizedBox(height: 24),

          // Welcome message with user data
          _buildWelcomeSection(),

          const SizedBox(height: 8),

          Text(
            userDesc(stringToUser(_userRole!)),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          // User info card for returning users
          if (_isReturningUser) _buildUserInfoCard(),

          const SizedBox(height: 32),

          // Login form
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildForm(theme, colorScheme),
          ),

          const SizedBox(height: 24),

          // Sign up link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnboardingPage(wasFromLogin: true),
                    ),
                  );
                },
                child: const Text(
                  'Switch Role',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Text(
          _isReturningUser ? 'Welcome Back!' : 'Welcome',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        if (_isReturningUser && _userName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _userName!,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.95),
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          if (_userEmail != null) ...[
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _userEmail!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          if (_lastLogin != null) ...[
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last login: ${_formatLastLogin(_lastLogin)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            _isReturningUser ? 'Sign In' : 'Welcome Back',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Phone number field
          TextFormField(
            controller: _phoneNumberController,
            decoration: InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(
                Icons.person_outline,
                color: colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator:
                (value) =>
                    value?.isEmpty == true
                        ? 'Please enter your username'
                        : null,
          ),

          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: _togglePasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value?.isEmpty == true) return 'Please enter your password';
              if (value!.length < 6)
                return 'Password must be at least 6 characters';
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
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
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
