import 'package:flutter/material.dart';

/// AppColors defines the application's color palette.
/// 
/// This class centralizes all color constants used throughout the app,
/// ensuring consistent visual identity across the application.
class AppColors {
  /// Primary brand color - blue (#007BFF)
  /// Used for primary buttons, app bar, links, and key interactive elements
  static const Color primaryColor = Color(0xFF007BFF);
  
  /// Secondary accent color - green (#28A745)
  /// Used for success states, progress indicators, and call-to-action elements
  static const Color secondaryColor = Color(0xFF28A745);
  
  /// Default light background color - white (#FFFFFF)
  /// Used as the main background color in light theme
  static const Color backgroundColor = Color(0xFFFFFFFF);
  
  /// Primary text color - dark gray (#343A40)
  /// Used for headings and body text in light theme for good readability
  static const Color textColor = Color(0xFF343A40);
  
  /// Light gray background color (#F8F9FA)
  /// Used for subtle backgrounds, cards, form fields, and dividers in light theme
  static const Color lightGray = Color(0xFFF8F9FA);
}

/// AppTheme provides pre-configured theme options for the application.
/// 
/// This class contains factory methods that create complete [ThemeData] 
/// objects with consistent styling across different theme variants.
/// The app's visual appearance can be changed by selecting one of these themes.
class AppTheme {
  /// Default light theme - The standard theme with blue accent and light background
  /// 
  /// Features:
  /// - Light backgrounds with dark text for optimal readability
  /// - Blue primary color for brand identity
  /// - High contrast for accessibility
  static ThemeData get defaultTheme => _buildThemeData(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        background: AppColors.backgroundColor,
        text: AppColors.textColor,
        isDark: false,
      );

  /// Dark theme - Inverted color scheme for low-light environments
  /// 
  /// Features:
  /// - Dark backgrounds with light text to reduce eye strain in low light
  /// - White accent color for consistency with dark mode standards
  /// - Reduced brightness for better viewing in dark environments
  static ThemeData get darkTheme => _buildThemeData(
        primary: Colors.white,
        secondary: Color(0xFF424242),
        background: Colors.black,
        text: Colors.white,
        isDark: true,
        onPrimary: Colors.black,
      );

  /// Light theme - Alias for defaultTheme
  /// 
  /// This getter exists to provide semantic clarity when selecting themes
  /// by explicitly requesting a 'light' theme rather than the 'default'
  static ThemeData get lightTheme => defaultTheme;

  /// Private factory method that constructs a complete [ThemeData] object
  /// with consistent styling based on provided color parameters.
  /// 
  /// This method centralizes theme construction logic to ensure
  /// all themes have consistent structure.
  /// 
  /// ## Parameters:
  /// 
  /// * [primary] - The main brand color for interactive elements like buttons and selection controls
  /// * [secondary] - The supporting color for secondary UI elements and accents
  /// * [background] - The color used for main surfaces like scaffold backgrounds
  /// * [text] - The default color for text content
  /// * [isDark] - Whether this theme uses dark mode semantics (affects contrast and system UI)
  /// * [onPrimary] - Optional color for text/icons on primary color surfaces (defaults to white/black based on contrast)
  static ThemeData _buildThemeData({
    required Color primary,
    required Color secondary,
    required Color background,
    required Color text,
    required bool isDark,
    Color? onPrimary,
  }) {
    return ThemeData(
      // --- CORE THEME ATTRIBUTES ---
      
      // Primary branding color used throughout the app
      primaryColor: primary,
      
      // Controls overall color contrast and system UI elements (status bar, etc.)
      brightness: isDark ? Brightness.dark : Brightness.light,
      
      // --- COLOR SCHEME DEFINITION ---
      // Comprehensive color scheme that defines all color relationships
      colorScheme: ColorScheme(
        // Base brightness setting (dark/light)
        brightness: isDark ? Brightness.dark : Brightness.light,
        
        // Primary and secondary brand colors
        primary: primary,
        secondary: secondary,
        
        // Surface and background colors
        surface: background,
        background: background,
        
        // Text colors for different surfaces
        onSurface: text,
        onBackground: text,
        
        // Text color on primary/secondary colored elements (for contrast)
        onPrimary: onPrimary ?? (isDark ? Colors.black : Colors.white),
        onSecondary: Colors.white,
        
        // Error states
        error: Colors.red,
        onError: Colors.white,
      ),
      
      // --- COMPONENT-SPECIFIC THEMING ---
      
      // Background color for Scaffold widgets
      scaffoldBackgroundColor: background,
      
      // App bar appearance
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        titleTextStyle: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: text),
        elevation: 0, // Flat design without shadows
      ),
      
      // Default text styling
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