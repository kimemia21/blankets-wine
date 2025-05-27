import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color primaryMedium = Color(0xFF16213E);
  static const Color primaryLight = Color(0xFF0F3460);
  
  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textHint = Colors.white54;
  
  // Accent Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  
  // Background Colors
  static const Color scaffoldBackground = primaryDark;
  static const Color cardBackground = primaryMedium;
  static const Color buttonBackground = primaryLight;
  
  // Other Colors
  static const Color shadow = Colors.black26;
  static const Color overlay = Colors.black54;
  static const Color transparent = Colors.transparent;
  
  // Indigo theme color (for MaterialApp)
  static const MaterialColor indigoPrimary = Colors.indigo;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: AppColors.indigoPrimary,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryMedium,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBackground,
          foregroundColor: AppColors.textPrimary,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  // Additional theme methods
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
  
  static BoxDecoration get cartItemDecoration {
    return BoxDecoration(
      color: AppColors.buttonBackground,
      borderRadius: BorderRadius.circular(8),
    );
  }
  
  static BoxDecoration get cartTotalDecoration {
    return BoxDecoration(
      color: AppColors.buttonBackground,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
    );
  }
  
  static InputDecoration searchInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 16),
      prefixIcon: Icon(Icons.search, color: AppColors.textHint, size: 24),
      filled: true,
      fillColor: AppColors.primaryMedium,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
  }
  
  // Text Styles
  static TextStyle get priceTextStyle {
    return TextStyle(
      color: AppColors.success,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
  }
  
  static TextStyle get largePriceTextStyle {
    return TextStyle(
      color: AppColors.success,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );
  }
  
  static TextStyle get headerTextStyle {
    return TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );
  }
  
  static TextStyle get dialogTitleStyle {
    return TextStyle(
      color: AppColors.textPrimary,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    );
  }
  
  static TextStyle get itemNameStyle {
    return TextStyle(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
  }
  
  static TextStyle get quantityStyle {
    return TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
  }
  
  // Button Styles
  static ButtonStyle get successButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.success,
      foregroundColor: AppColors.textPrimary,
      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
  
  static ButtonStyle categoryButtonStyle(bool isSelected) {
    return ElevatedButton.styleFrom(
      backgroundColor: isSelected ? AppColors.buttonBackground : AppColors.primaryMedium,
      foregroundColor: AppColors.textPrimary,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }
  
  // Dialog Styles
  static RoundedRectangleBorder get dialogShape {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
  }
}