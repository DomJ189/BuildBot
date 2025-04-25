import 'package:flutter/material.dart';
import '../theme.dart';

/// Manages the state for the theme selection UI.
/// This ViewModel temporarily holds the selected theme before it's committed to the ThemeProvider.
class ThemeSelectionViewModel extends ChangeNotifier {
  late ThemeData _selectedTheme;
  
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
    return false;
  }
  
  /// Applies the selected theme - the actual saving is now handled by ThemeProvider
  Future<void> saveSelectedTheme() async {
    // No longer need to save preferences here since ThemeProvider handles that
    // This method is kept for compatibility with the existing UI code
    return;
  }
} 