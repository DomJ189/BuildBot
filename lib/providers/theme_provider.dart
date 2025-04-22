import 'package:flutter/material.dart';
import '../viewmodels/theme_provider_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

// Manages the current theme of the application
class ThemeProvider extends ChangeNotifier {
  final ThemeProviderViewModel _viewModel = ThemeProviderViewModel();
  bool isDarkMode = false;
  
  ThemeData get currentTheme => _viewModel.currentTheme;
  
  ThemeProvider() {
    _viewModel.addListener(_onViewModelChanged);
    _loadThemePreference();
  }
  
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('dark_mode') ?? false;
    if (isDarkMode) {
      _viewModel.setTheme(ThemeData.dark());
    } else {
      _viewModel.setTheme(AppTheme.defaultTheme);
    }
  }
  
  void setTheme(ThemeData theme) {
    _viewModel.setTheme(theme);
  }
  
  void _onViewModelChanged() {
    notifyListeners();
  }
  
  void toggleTheme() {
    isDarkMode = !isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }
  
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDarkMode);
  }
  
  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }
} 