import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

/// Manages the application's theme state and persistence.
/// This provider handles loading, storing, and changing themes throughout the app.
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
      setTheme(AppTheme.defaultTheme);
    } else {
      setTheme(AppTheme.darkTheme);
    }
  }
  
  /// Saves the current theme preference to persistent storage
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_currentTheme == AppTheme.darkTheme) {
      await prefs.setString('theme', 'dark');
    } else if (_currentTheme == AppTheme.lightTheme || _currentTheme == AppTheme.defaultTheme) {
      await prefs.setString('theme', 'light');
    } else {
      await prefs.setString('theme', 'default');
    }
    
    // Also update the legacy dark_mode value for backward compatibility
    await prefs.setBool('dark_mode', isDarkMode);
  }
} 