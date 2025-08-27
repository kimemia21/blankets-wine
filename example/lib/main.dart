// File: lib/streams_example.dart
import 'dart:async';

import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/core/utils/sdkinitializer.dart';
import 'package:blankets_and_wines_example/data/models/RegAdapters.dart';
import 'package:blankets_and_wines_example/features/cashier/Auth/Login.dart';
import 'package:blankets_and_wines_example/offline/BackGroundService.dart';
import 'package:blankets_and_wines_example/offline/Connectivty.dart';
import 'package:blankets_and_wines_example/onBoarding/OnBoarding.dart';
import 'package:blankets_and_wines_example/widgets/Alerts.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await HiveAdapters.init();
  
  // Open metadata box for sync tracking
  await Hive.openBox('metadata');
  

  await BackgroundSyncService.initialize();
  
  await sdkInitializer();
  await preferences.init();

  runApp(MyApp());
}



Future<bool> isLoggedin() async {
  try {
    bool result = await preferences.isUserLoggedIn();
    if (result) {
      userData = (await preferences.getUserData())!;
      print(
        "##############################${userData.userRole}######################################",
      );
    }
    return result;
  } on Exception catch (e) {
    ToastService.showError(e.toString());
    throw Exception(e);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Track SDK check status
  bool _sdkCheckCompleted = false;
  bool _isInitializing = true;



 @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
     _initializeApp();
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up services when app is closed
    // ConnectivityService().dispose();
    BackgroundSyncService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Optimize background sync based on app state
    if (state == AppLifecycleState.paused) {
      // App is in background, reduce sync frequency
      BackgroundSyncService.backgroundTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // App is active, resume normal sync frequency
      BackgroundSyncService.startBackgroundTimer();
    }
  }

  Future<void> _initializeApp() async {
    // Add a small delay to ensure everything is properly initialized
    await Future.delayed(Duration(milliseconds: 100));
    
    // Check SDK initialization status
    await _checkSdkInitialization();
    
    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _checkSdkInitialization() async {
    try {
      print("🔍 Checking SDK initialization...");
      
      final initResult = await sdkInitializer();
      print("📊 SDK init result: $initResult");
      
      if (initResult is Map && !initResult["success"]) {
        print("❌ SDK initialization failed: ${initResult["msg"]}");
        
        // Schedule alert to show after the widget tree is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSdkErrorAlert(initResult["msg"]);
        });
      } else {
        print("✅ SDK initialized successfully");
      }
    } catch (e) {
      print("💥 Error during SDK check: $e");
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSdkErrorAlert("SDK initialization error: $e");
      });
    } finally {
      _sdkCheckCompleted = true;
    }
  }

  void _showSdkErrorAlert(String errorMessage) {
    // Method 1: Use navigator key context (Preferred)
    final navigatorContext = ToastService.navigatorKey.currentContext;
    
    if (navigatorContext != null) {
      print("📱 Showing alert using navigator context");
      _showAlertDialog(navigatorContext, errorMessage);
      return;
    }

    // Method 2: Use current context as fallback
    if (mounted && context != null) {
      print("📱 Showing alert using current context");
      _showAlertDialog(context, errorMessage);
      return;
    }

    // Method 3: Use ToastService as final fallback
    print("📱 Showing toast as fallback");
    ToastService.showError("SDK Error: $errorMessage");
  }

  void _showAlertDialog(BuildContext context, String errorMessage) {
    try {
      // Use your existing showalert function
      showalert(
        success: false,
        context: context,
        title: "SDK ERROR",
        subtitle: errorMessage,
      );
    } catch (e) {
      print("❌ Error showing alert dialog: $e");
      
      // Fallback to simple dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("SDK Error"),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Optionally restart the app or retry initialization
                  _retryInitialization();
                },
                child: Text("Retry"),
              ),
            ],
          );
        },
      );
    }
  }

  void _retryInitialization() async {
    setState(() {
      _isInitializing = true;
      _sdkCheckCompleted = false;
    });
    
    await _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: ToastService.navigatorKey,
      title: 'Blankets and Wines',
      debugShowCheckedModeBanner: false,
      home: 
      // Cashier()
      // BartenderPage()
      // DummyPrintPage(),
    _buildHome(),
    );
  }

  Widget _buildHome() {
    // Show loading while initializing
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Initializing app..."),
            ],
          ),
        ),
      );
    }

    // Main app content
    return FutureBuilder<bool>(
      future: isLoggedin(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading..."),
                ],
              ),
            ),
          );
        }

        // Handle error state
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text("Error: ${snapshot.error}"),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Trigger rebuild to retry
                      });
                    },
                    child: Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        // Handle success state - user is logged in
        if (snapshot.data == true) {
          return _buildUserScreen();
        }

        // Default state - user not logged in
        return OnboardingPage(wasFromLogin: false);
      },
    );
  }

  Widget _buildUserScreen() {
    // Check user role and navigate accordingly
    if (userData?.userRole != null) {
      switch (userData.userRole.toLowerCase()) {
        case 'cashier':
          return LoginPage();
        case 'admin':
          return LoginPage(); // Replace with AdminPage() when available
        case 'manager':
          return LoginPage(); // Replace with ManagerPage() when available
        default:
          return LoginPage(); // Default fallback
      }
    }
    
    // Fallback if userData is null or userRole is null
    return LoginPage();
  }
}

// Enhanced error handling wrapper (Optional)
class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  
  const AppErrorBoundary({Key? key, required this.child}) : super(key: key);

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  bool hasError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Set up global error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        hasError = true;
        errorMessage = details.exception.toString();
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text("App Error", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(errorMessage ?? "An unexpected error occurred"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      hasError = false;
                      errorMessage = null;
                    });
                  },
                  child: Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

// Usage with error boundary (wrap your MyApp if needed):
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await sdkInitializer();
//   await preferences.init();
//   
//   runApp(AppErrorBoundary(child: MyApp()));
// }