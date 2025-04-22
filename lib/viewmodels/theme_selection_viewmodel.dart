import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class ThemeSelectionViewModel extends ChangeNotifier {
  late ThemeData _selectedTheme;
  
  ThemeData get selectedTheme => _selectedTheme;
  
  ThemeSelectionViewModel(ThemeData currentTheme) {
    _selectedTheme = currentTheme;
  }
  
  void setSelectedTheme(ThemeData theme) {
    _selectedTheme = theme;
    notifyListeners();
  }
  
  bool isThemeSelected(ThemeData theme) {
    if (theme == AppTheme.defaultTheme && _selectedTheme == AppTheme.defaultTheme) {
      return true;
    } else if (theme == AppTheme.darkTheme && _selectedTheme == AppTheme.darkTheme) {
      return true;
    }
    return false;
  }
  
  Future<void> saveSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_selectedTheme == AppTheme.darkTheme) {
      await prefs.setString('theme', 'dark');
    } else if (_selectedTheme == AppTheme.defaultTheme) {
      await prefs.setString('theme', 'light');
    }
  }
} 