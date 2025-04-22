import 'package:flutter/material.dart';

// Defines a set of colors used throughout the application
class AppColors {
  static const Color primaryColor = Color(0xFF007BFF); // Blue
  static const Color secondaryColor = Color(0xFF28A745); // Green
  static const Color backgroundColor = Color(0xFFFFFFFF); // White
  static const Color textColor = Color(0xFF343A40); // Dark Gray
  static const Color lightGray = Color(0xFFF8F9FA); // Light Gray
}

// Provides different theme configurations for the application
class AppTheme {
  // Default theme configuration
  static ThemeData get defaultTheme => _buildThemeData(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        background: AppColors.backgroundColor,
        text: AppColors.textColor,
        isDark: false,
      );

  // Dark theme configuration
  static ThemeData get darkTheme => _buildThemeData(
        primary: Colors.white,
        secondary: Color(0xFF424242),
        background: Colors.black,
        text: Colors.white,
        isDark: true,
        onPrimary: Colors.black,
      );

  // Light theme configuration (alias for defaultTheme)
  static ThemeData get lightTheme => defaultTheme;

  // Blue theme configuration
  static ThemeData get blueTheme => _buildThemeData(
        primary: Colors.blue,
        secondary: Colors.lightBlue,
        background: Colors.white,
        text: Colors.grey[900]!,
        isDark: false,
      );

  // Private method to build the theme data based on provided parameters
  static ThemeData _buildThemeData({
    required Color primary,
    required Color secondary,
    required Color background,
    required Color text,
    required bool isDark,
    Color? onPrimary,
  }) {
    return ThemeData(
      primaryColor: primary, // Set the primary color
      brightness: isDark ? Brightness.dark : Brightness.light, // Set brightness based on theme
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light, // Set color scheme brightness
        primary: primary, // Primary color for the color scheme
        secondary: secondary, // Secondary color for the color scheme
        surface: background, // Background color for surfaces
        onSurface: text, // Text color on surfaces
        onPrimary: onPrimary ?? (isDark ? Colors.black : Colors.white), // Text color on primary color
        onSecondary: Colors.white, // Text color on secondary color
        error: Colors.red, // Error color
        onError: Colors.white, // Text color on error
      ),
      scaffoldBackgroundColor: background, // Background color for scaffold
      appBarTheme: AppBarTheme(
        backgroundColor: background, // Background color for app bar
        titleTextStyle: TextStyle(
          color: text, // Text color for app bar title
          fontWeight: FontWeight.bold, // Bold font weight for title
          fontSize: 20, // Font size for title
        ),
        iconTheme: IconThemeData(color: text), // Icon color in app bar
        elevation: 0, // No elevation for app bar
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: text), // Text style for body
        titleLarge: TextStyle(color: text), // Text style for titles
      ),
      iconTheme: IconThemeData(color: text), // Default icon color
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background, // Background color for bottom navigation bar
        selectedItemColor: primary, // Color for selected item
        unselectedItemColor: text.withAlpha(153), // Color for unselected items
      ),
    );
  }
} 