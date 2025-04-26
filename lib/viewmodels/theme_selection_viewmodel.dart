import 'package:flutter/material.dart'; // Import Flutter's material design package
import '../theme.dart'; // Import app theme definitions

/// Manages the state for the theme selection UI.
class ThemeSelectionViewModel extends ChangeNotifier {
  late ThemeData _selectedTheme; // Stores the currently selected theme
  
  /// The currently selected theme in the theme picker UI
  ThemeData get selectedTheme => _selectedTheme; 
  
  /// Initialize with the current application theme
  ThemeSelectionViewModel(ThemeData currentTheme) {
    _selectedTheme = currentTheme;
  }
  
  /// Updates the selected theme in the UI
  void setSelectedTheme(ThemeData theme) {
    _selectedTheme = theme;
    notifyListeners();
  }
  
  /// Checks if a specific theme is currently selected
  bool isThemeSelected(ThemeData theme) {
    if (theme == AppTheme.defaultTheme && _selectedTheme == AppTheme.defaultTheme) {
      return true; 
    } else if (theme == AppTheme.darkTheme && _selectedTheme == AppTheme.darkTheme) {
      return true;
    }
    return false; // Return false if the theme is not selected
  }
  
  /// Applies the selected theme 
  Future<void> saveSelectedTheme() async {
    // This method is kept for compatibility with the existing UI code
    return;
  }
} 