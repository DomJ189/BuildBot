import 'package:flutter/material.dart'; // Import Flutter material design package
import 'package:shared_preferences/shared_preferences.dart'; // Import shared preferences for theme persistence
import '../theme.dart'; // Import app theme definitions

/// Manages the application's theme state and persistence. Handles loading, storing, and changing themes throughout the app.
class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = AppTheme.defaultTheme;
  
  /// The currently active theme
  ThemeData get currentTheme => _currentTheme;
  
  /// Whether the app is currently using a dark theme
  bool get isDarkMode => _currentTheme.brightness == Brightness.dark;
  
  /// Constructor initializes the provider and loads saved theme
  ThemeProvider() {
    loadTheme();
  }
  
  /// Loads the saved theme preference from persistent storage
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme') ?? 'default';
    
    switch (themeName) {
      case 'dark':
        _currentTheme = AppTheme.darkTheme;
        break;
      case 'light':
        _currentTheme = AppTheme.lightTheme;
        break;
      default:
        _currentTheme = AppTheme.defaultTheme;
    }
    
    notifyListeners();
  }
  
  /// Sets a specific theme and saves the preference
  void setTheme(ThemeData theme) {
    _currentTheme = theme;
    _saveTheme();
    notifyListeners();
  }
  
  /// Toggles between light and dark themes
  void toggleTheme() {
    if (isDarkMode) {
      setTheme(AppTheme.defaultTheme); // Switch to light theme if currently dark
    } else {
      setTheme(AppTheme.darkTheme); // Switch to dark theme if currently light
    }
  }
  
  /// Saves the current theme preference to persistent storage
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_currentTheme == AppTheme.darkTheme) {
      await prefs.setString('theme', 'dark'); // Save dark theme preference
    } else if (_currentTheme == AppTheme.lightTheme || _currentTheme == AppTheme.defaultTheme) {
      await prefs.setString('theme', 'light'); // Save light theme preference
    } else {
      await prefs.setString('theme', 'default'); // Save default theme preference
    }
    
    // Also update the legacy dark_mode value for backward compatibility
    await prefs.setBool('dark_mode', isDarkMode); // Save boolean for legacy support
  }
} 