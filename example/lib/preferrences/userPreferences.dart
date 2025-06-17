import 'package:blankets_and_wines_example/data/models/UserDataPref.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesManager {
  // Singleton instance
  static UserPreferencesManager? _instance;
  static SharedPreferences? _preferences;

  // Private constructor
  UserPreferencesManager._internal();

  // Factory constructor to return the same instance
  factory UserPreferencesManager() {
    _instance ??= UserPreferencesManager._internal();
    return _instance!;
  }

  // Singleton instance getter
  static UserPreferencesManager get instance {
    _instance ??= UserPreferencesManager._internal();
    return _instance!;
  }

  // Initialize SharedPreferences
  Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  // Private method to ensure SharedPreferences is initialized
  Future<SharedPreferences> get _prefs async {
    _preferences ??= await SharedPreferences.getInstance();
    return _preferences!;
  }

  // Keys for storing data
  static const String _keyUserRole = 'user_role';
  static const String _keyUsername = 'username';
  static const String _keyPassword = 'password';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // Save user data
  Future<bool> saveUserData({
    required String userRole,
    required String username,
    required String password,
  }) async {
    try {
      final prefs = await _prefs;
      
      await prefs.setString(_keyUserRole, userRole);
      await prefs.setString(_keyUsername, username);
      await prefs.setString(_keyPassword, password);
      await prefs.setBool(_keyIsLoggedIn, true);
      
      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(_keyUserRole);
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Get username
  Future<String?> getUsername() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(_keyUsername);
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  // Get password
  Future<String?> getPassword() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(_keyPassword);
    } catch (e) {
      print('Error getting password: $e');
      return null;
    }
  }

  // Get all user data at once
  Future<UserData?> getUserData() async {
    try {
      final prefs = await _prefs;
      
      final userRole = prefs.getString(_keyUserRole);
      final username = prefs.getString(_keyUsername);
      final password = prefs.getString(_keyPassword);
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

      if (userRole != null && username != null && password != null) {
        return UserData(
          userRole: userRole,
          username: username,
          password: password,
          isLoggedIn: isLoggedIn,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await _prefs;
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Update user role
  Future<bool> updateUserRole(String newRole) async {
    try {
      final prefs = await _prefs;
      return await prefs.setString(_keyUserRole, newRole);
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  // Update username
  Future<bool> updateUsername(String newUsername) async {
    try {
      final prefs = await _prefs;
      return await prefs.setString(_keyUsername, newUsername);
    } catch (e) {
      print('Error updating username: $e');
      return false;
    }
  }

  // Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      final prefs = await _prefs;
      return await prefs.setString(_keyPassword, newPassword);
    } catch (e) {
      print('Error updating password: $e');
      return false;
    }
  }

  // Clear all user data (logout)
  Future<bool> clearUserData() async {
    try {
      final prefs = await _prefs;
      
      await prefs.remove(_keyUserRole);
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyPassword);
      await prefs.setBool(_keyIsLoggedIn, false);
      
      return true;
    } catch (e) {
      print('Error clearing user data: $e');
      return false;
    }
  }

  // Clear all preferences (complete reset)
  Future<bool> clearAllPreferences() async {
    try {
      final prefs = await _prefs;
      return await prefs.clear();
    } catch (e) {
      print('Error clearing all preferences: $e');
      return false;
    }
  }
}

// Example usage class
class AuthenticationService {
  final UserPreferencesManager _prefsManager = UserPreferencesManager();

  // Login method
  Future<bool> login({
    required String userRole,
    required String username,
    required String password,
  }) async {
    // Here you would typically validate credentials with your backend
    // For now, we'll just save them
    
    final success = await _prefsManager.saveUserData(
      userRole: userRole,
      username: username,
      password: password,
    );
    
    return success;
  }

  // Logout method
  Future<bool> logout() async {
    return await _prefsManager.clearUserData();
  }

  // Auto-login check
  Future<UserData?> checkAutoLogin() async {
    final isLoggedIn = await _prefsManager.isUserLoggedIn();
    if (isLoggedIn) {
      return await _prefsManager.getUserData();
    }
    return null;
  }
}