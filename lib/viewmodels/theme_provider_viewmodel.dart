import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class ThemeProviderViewModel extends ChangeNotifier {
  ThemeData _currentTheme = AppTheme.defaultTheme;
  
  ThemeData get currentTheme => _currentTheme;
  
  ThemeProviderViewModel() {
    loadTheme();
  }
  
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
      case 'blue':
        _currentTheme = AppTheme.blueTheme;
        break;
      default:
        _currentTheme = AppTheme.defaultTheme;
    }
    
    notifyListeners();
  }
  
  void setTheme(ThemeData theme) {
    _currentTheme = theme;
    _saveTheme();
    notifyListeners();
  }
  
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_currentTheme == AppTheme.darkTheme) {
      await prefs.setString('theme', 'dark');
    } else if (_currentTheme == AppTheme.lightTheme) {
      await prefs.setString('theme', 'light');
    } else if (_currentTheme == AppTheme.blueTheme) {
      await prefs.setString('theme', 'blue');
    } else {
      await prefs.setString('theme', 'default');
    }
  }
} 