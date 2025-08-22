import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BarPOSTheme {
  // Color Palette
  static const Color primaryDark = Color(0xFF0A0A0A);
  static const Color secondaryDark = Color(0xFF1A1A2E);
  static const Color accentDark = Color(0xFF16213E);
  static const Color buttonColor = Color(0xFF0F3460);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color warningColor = Color(0xFFFF9800);
  
  // Text Colors
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFB0B0B0);
  static const Color accentText = Color(0xFF4CAF50);
  static const Color mutedText = Color(0xFF757575);
  
  // Font Sizes (Increased for outdoor nighttime use)
  static const double displayLarge = 56.0;
  static const double displayMedium = 44.0;
  static const double displaySmall = 38.0;
  static const double headlineLarge = 34.0;
  static const double headlineMedium = 30.0;
  static const double headlineSmall = 26.0;
  static const double titleLarge = 30.0;
  static const double titleMedium = 22.0;
  static const double titleSmall = 20.0;
  static const double bodyLarge = 22.0;
  static const double bodyMedium = 20.0;
  static const double bodySmall = 18.0;
  static const double labelLarge = 20.0;
  static const double labelMedium = 18.0;
  static const double labelSmall = 16.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;
  
  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // Button Dimensions
  static const double buttonHeight = 56.0;
  static const double buttonHeightSmall = 44.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 16.0,
  );
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  
  // Input Field Dimensions
  static const double inputHeight = 56.0;
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );
  
  // Card Dimensions
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20.0);
  
  // Create the main theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: primaryDark,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: accentDark,
        elevation: elevationMedium,
        centerTitle: true,
        titleTextStyle: GoogleFonts.rajdhani(
          color: primaryText,
          fontSize: headlineMedium,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(
          color: primaryText,
          size: 32.0,
        ),
      ),
      
      // Text Theme with Google Fonts for outdoor use
      textTheme: TextTheme(
        displayLarge: GoogleFonts.rajdhani(
          color: primaryText,
          fontSize: displayLarge,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        displayMedium: GoogleFonts.rajdhani(
          color: primaryText,
          fontSize: displayMedium,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.3,
        ),
        displaySmall: GoogleFonts.rajdhani(
          color: primaryText,
          fontSize: displaySmall,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
        headlineLarge: GoogleFonts.rajdhani(
          color: primaryText,
          fontSize: headlineLarge,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        headlineMedium: GoogleFonts.rajdhani(
          color: primaryText,
          fontSize: headlineMedium,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
        headlineSmall: GoogleFonts.rajdhani(
          color: primaryText,
          fontSize: headlineSmall,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
        titleLarge: GoogleFonts.inter(
          color: primaryText,
          fontSize: titleLarge,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        titleMedium: GoogleFonts.inter(
          color: primaryText,
          fontSize: titleMedium,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        titleSmall: GoogleFonts.inter(
          color: primaryText,
          fontSize: titleSmall,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.inter(
          color: primaryText,
          fontSize: bodyLarge,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.1,
        ),
        bodyMedium: GoogleFonts.inter(
          color: secondaryText,
          fontSize: bodyMedium,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.1,
        ),
        bodySmall: GoogleFonts.inter(
          color: mutedText,
          fontSize: bodySmall,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: GoogleFonts.inter(
          color: primaryText,
          fontSize: labelLarge,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.inter(
          color: secondaryText,
          fontSize: labelMedium,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.inter(
          color: mutedText,
          fontSize: labelSmall,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: primaryText,
          padding: buttonPadding,
          minimumSize: Size(0, buttonHeight),
          textStyle: GoogleFonts.rajdhani(
            fontSize: titleMedium,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: elevationMedium,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryText,
          padding: buttonPaddingSmall,
          textStyle: GoogleFonts.inter(
            fontSize: titleSmall,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: accentDark,
        hintStyle: GoogleFonts.inter(
          color: secondaryText,
          fontSize: bodyLarge,
        ),
        labelStyle: GoogleFonts.inter(
          color: primaryText,
          fontSize: bodyLarge,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        contentPadding: inputPadding,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: secondaryDark,
        elevation: elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: EdgeInsets.all(spacingS),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: primaryText,
        size: 28.0,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: accentDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        titleTextStyle: GoogleFonts.rajdhani(
          color: primaryText,
          fontSize: headlineSmall,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: primaryText,
          fontSize: bodyLarge,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: successColor,
        foregroundColor: primaryText,
        elevation: elevationHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: accentDark,
        contentTextStyle: GoogleFonts.inter(
          color: primaryText,
          fontSize: bodyLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Custom component styles
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: secondaryDark,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get accentCardDecoration => BoxDecoration(
    color: accentDark,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: [
      BoxShadow(
        color: Colors.black38,
        blurRadius: 8,
        offset: Offset(0, 3),
      ),
    ],
  );
  
  static BoxDecoration get buttonCardDecoration => BoxDecoration(
    color: buttonColor,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: [
      BoxShadow(
        color: Colors.black45,
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get successCardDecoration => BoxDecoration(
    color: successColor,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  // Text Styles for specific use cases with Google Fonts
  static TextStyle get priceTextStyle => GoogleFonts.jetBrainsMono(
    color: accentText,
    fontSize: titleLarge,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );
  
  static TextStyle get totalPriceTextStyle => GoogleFonts.jetBrainsMono(
    color: accentText,
    fontSize: headlineSmall,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  );
  
  static TextStyle get itemNameTextStyle => GoogleFonts.inter(
    color: primaryText,
    fontSize: bodyLarge,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
  );
  
  static TextStyle get categoryTextStyle => GoogleFonts.rajdhani(
    color: primaryText,
    fontSize: titleSmall,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );
  
  static TextStyle get quantityTextStyle => GoogleFonts.jetBrainsMono(
    color: primaryText,
    fontSize: titleMedium,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );
  
  static TextStyle get hintTextStyle => GoogleFonts.inter(
    color: secondaryText,
    fontSize: bodyLarge,
  );
}