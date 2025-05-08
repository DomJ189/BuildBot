import 'package:flutter/material.dart';

/// App color constants used throughout the application
class AppColors {
  /// Primary blue color for main interactive elements
  static const Color primaryColor = Color(0xFF007BFF);
  
  /// Secondary green color for success states and indicators
  static const Color secondaryColor = Color(0xFF28A745);
  
  /// Default white background for light theme
  static const Color backgroundColor = Color(0xFFFFFFFF);
  
  /// Primary dark text color for good readability
  static const Color textColor = Color(0xFF343A40);
  
  /// Light gray for subtle backgrounds and form fields
  static const Color lightGray = Color(0xFFF8F9FA);
}

/// Theme configuration for the application
class AppTheme {
  /// Default light theme with blue accents
  static ThemeData get defaultTheme => _buildThemeData(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        background: AppColors.backgroundColor,
        text: AppColors.textColor,
        isDark: false,
      );

  /// Dark theme for low-light environments
  static ThemeData get darkTheme => _buildThemeData(
        primary: Colors.white,
        secondary: Color(0xFF424242),
        background: Colors.black,
        text: Colors.white,
        isDark: true,
        onPrimary: Colors.black,
      );

  /// Alias for default light theme
  static ThemeData get lightTheme => defaultTheme;

  /// Builds theme data with consistent styling from colors
  static ThemeData _buildThemeData({
    required Color primary, //The main brand color for interactive elements like buttons and selection controls
    required Color secondary, //Secondary color for secondary interactive elements like selection controls
    required Color background, //Default background color for the app
    required Color text, //Default text color for the app
    required bool isDark, //Boolean flag to determine if the theme is dark or light
    Color? onPrimary, //Optional color for the primary text on the primary background
  }) {
    return ThemeData(
      // Core theme settings
      primaryColor: primary, // Set the primary color
      
      // Controls overall color contrast and system UI elements (status bar, etc.)
      brightness: isDark ? Brightness.dark : Brightness.light, // Set brightness based on theme type
      
      // Complete color scheme
      colorScheme: ColorScheme(
        // Base brightness setting (dark/light)
        brightness: isDark ? Brightness.dark : Brightness.light, // Set color scheme brightness
        
        // Primary and secondary brand colors
        primary: primary,
        secondary: secondary,
        
        // Surface and background colors
        surface: background,
        
        // Text colors for different surfaces
        onSurface: text,
        
        // Text color on primary/secondary colored elements (for contrast)
        onPrimary: onPrimary ?? (isDark ? Colors.black : Colors.white),
        onSecondary: Colors.white,
        
        // Error states
        error: Colors.red,
        onError: Colors.white,
      ),
      
      // Component-specific styling
      scaffoldBackgroundColor: background,
      
      // App bar appearance
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        titleTextStyle: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: text), // Set app bar icon color
        elevation: 0, // Flat design without shadows
      ),
      
      // Text and icon styling
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: text),
        titleLarge: TextStyle(color: text),
      ),
      
      // Icon styling
      iconTheme: IconThemeData(color: text),
      
      // Bottom navigation bar styling
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: text.withAlpha(153), // 60% opacity for inactive items
      ),
    );
  }
} 