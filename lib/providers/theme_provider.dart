import 'package:flutter/material.dart';
import '../theme.dart';

// Manages the current theme of the application
class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = AppTheme.defaultTheme; // Default theme

  ThemeData get currentTheme => _currentTheme; // Get the current theme

  // Sets the current theme
  void setTheme(ThemeData theme) {
    _currentTheme = theme; // Set the current theme
    notifyListeners(); // Notify listeners when the theme changes
    // Save to shared preferences or other storage here
  }
} 