import 'package:blankets_and_wines_example/core/theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class ToastService {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  // Cached values for performance
  static ThemeData? _cachedTheme;
  static Size? _cachedScreenSize;
  static bool? _cachedIsDark;
  
  // Navigation safety guards
  static bool _isNavigating = false;
  static final List<Flushbar> _activeToasts = [];
  static const int _maxConcurrentToasts = 3;
  
  /// Initialize the ToastService with a navigator key
  /// Call this in your MaterialApp: navigatorKey: ToastService.navigatorKey
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
  
  /// Get the current context from the navigator
  static BuildContext? get _context => _navigatorKey.currentContext;
  
  /// Shows a success toast notification
  static void showSuccess(String message) {
    _showToast(
      message: message,
      icon: Icons.check_circle_outline,
      type: ToastType.success,
    );
  }

  /// Shows an error toast notification
  static void showError(String message) {
    _showToast(
      message: message,
      icon: Icons.error_outline,
      type: ToastType.error,
    );
  }

  /// Shows an informational toast notification
  static void showInfo(String message) {
    _showToast(
      message: message,
      icon: Icons.info_outline,
      type: ToastType.info,
    );
  }

  /// Shows a warning toast notification
  static void showWarning(String message) {
    _showToast(
      message: message,
      icon: Icons.warning_amber_outlined,
      type: ToastType.warning,
    );
  }

  /// Shows a custom toast with full control
  static void showCustom({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
    Duration duration = const Duration(seconds: 3),
    FlushbarPosition position = FlushbarPosition.TOP,
  }) {
    final context = _context;
    if (context == null) {
      debugPrint('ToastService: Context not available. Make sure to set navigatorKey in MaterialApp.');
      return;
    }

    _showCustomToast(
      context: context,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
      iconColor: iconColor,
      duration: duration,
      position: position,
    );
  }

  /// Core method to display toast notifications
  static void _showToast({
    required String message,
    required IconData icon,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
    FlushbarPosition position = FlushbarPosition.TOP,
  }) {
    final context = _context;
    if (context == null) {
      debugPrint('ToastService: Context not available. Make sure to set navigatorKey in MaterialApp.');
      return;
    }

    // Check if we're already navigating or have too many active toasts
    if (_isNavigating || _activeToasts.length >= _maxConcurrentToasts) {
      debugPrint('ToastService: Skipping toast - navigation in progress or too many active toasts');
      return;
    }

    // Cache theme and screen info for performance
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;
    
    // Update cache if needed
    if (_cachedTheme != theme || _cachedScreenSize != screenSize || _cachedIsDark != isDark) {
      _cachedTheme = theme;
      _cachedScreenSize = screenSize;
      _cachedIsDark = isDark;
    }

    // Get colors based on toast type - optimized with const colors
    final toastColors = _getToastColors(type, theme, isDark);
    
    _showCustomToast(
      context: context,
      message: message,
      icon: icon,
      backgroundColor: toastColors.backgroundColor,
      textColor: toastColors.textColor,
      iconColor: toastColors.iconColor,
      duration: duration,
      position: position,
    );
  }

  /// Helper method to show custom toast with navigation safety
  static void _showCustomToast({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    required Duration duration,
    required FlushbarPosition position,
  }) {
    // Calculate responsive width - cached for performance
    final toastWidth = _calculateToastWidth(_cachedScreenSize!);
    
    // Declare flushbar variable first
    late Flushbar flushbar;
    
    flushbar = Flushbar(
      maxWidth: toastWidth,
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(
        icon,
        size: 24.0,
        color: iconColor,
      ),
      duration: duration,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: position,
      boxShadows: [
        BoxShadow(
          color: backgroundColor.withOpacity(0.3),
          offset: const Offset(0, 2),
          blurRadius: 6,
        ),
      ],
      dismissDirection: FlushbarDismissDirection.VERTICAL,
      forwardAnimationCurve: Curves.easeOutQuart,
      reverseAnimationCurve: Curves.easeInQuart,
      // Add safety callbacks
      onStatusChanged: (FlushbarStatus? status) {
        switch (status) {
          case FlushbarStatus.SHOWING:
            _activeToasts.add(flushbar);
            break;
          case FlushbarStatus.DISMISSED:
            _activeToasts.remove(flushbar);
            _isNavigating = false;
            break;
          case FlushbarStatus.IS_APPEARING:
            _isNavigating = true;
            break;
          case FlushbarStatus.IS_HIDING:
            _isNavigating = true;
            break;
          default:
            break;
        }
      },
    );

    // Safety check before showing
    if (!_isNavigating && _activeToasts.length < _maxConcurrentToasts) {
      try {
        flushbar.show(context);
      } catch (e) {
        debugPrint('ToastService: Error showing toast - $e');
        _isNavigating = false;
        _activeToasts.remove(flushbar);
      }
    }
  }

  /// Get toast colors based on type - optimized with const colors
  static _ToastColors _getToastColors(ToastType type, ThemeData theme, bool isDark) {
    switch (type) {
      case ToastType.success:
        return _ToastColors(
          backgroundColor: isDark ? AppColors.success : const Color(0xFF4CAF50),
          textColor: Colors.white,
          iconColor: Colors.white,
        );
      case ToastType.error:
        return _ToastColors(
          backgroundColor: theme.colorScheme.error,
          textColor: Colors.white,
          iconColor: Colors.white,
        );
      case ToastType.warning:
        return _ToastColors(
          backgroundColor: isDark ? const Color(0xFFFFA000) : const Color(0xFFFF9800),
          textColor: Colors.white,
          iconColor: Colors.white,
        );
      case ToastType.info:
      default:
        return _ToastColors(
          backgroundColor: theme.colorScheme.primary,
          textColor: Colors.white,
          iconColor: Colors.white,
        );
    }
  }

  /// Calculate toast width based on screen size - optimized
  static double _calculateToastWidth(Size screenSize) {
    final screenWidth = screenSize.width;
    
    if (screenWidth > 1024) {
      return 400; // Fixed width for desktops (reduced from 500)
    } else if (screenWidth > 600) {
      return screenWidth * 0.65; // 65% width for tablets (reduced from 70%)
    } else {
      return screenWidth * 0.85; // 85% width for mobile (reduced from 90%)
    }
  }

  /// Dismiss all active toasts safely
  static void dismissAll() {
    if (_isNavigating) return;
    
    final toastsCopy = List<Flushbar>.from(_activeToasts);
    for (final toast in toastsCopy) {
      try {
        toast.dismiss();
      } catch (e) {
        debugPrint('ToastService: Error dismissing toast - $e');
      }
    }
    _activeToasts.clear();
    _isNavigating = false;
  }

  /// Clear any cached values (call this if theme changes)
  static void clearCache() {
    _cachedTheme = null;
    _cachedScreenSize = null;
    _cachedIsDark = null;
  }

  /// Reset the service state
  static void reset() {
    dismissAll();
    clearCache();
  }

  /// Check if toast service is properly initialized
  static bool get isInitialized => _context != null;
  
  /// Get the number of active toasts
  static int get activeToastCount => _activeToasts.length;
  
  /// Check if navigation is in progress
  static bool get isNavigating => _isNavigating;
}

/// Helper class for toast colors
class _ToastColors {
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;

  const _ToastColors({
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
  });
}

/// Enum representing different toast notification types
enum ToastType {
  success,
  error,
  info,
  warning,
}