import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Manages application settings and user preferences
class SettingsViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // User profile information getters
  String get userName => _auth.currentUser?.displayName ?? 'User';
  String get userEmail => _auth.currentUser?.email ?? 'No email';
  
  // User preference states
  bool isDarkMode = false;
  bool isNotificationsEnabled = true;
  
  // Load saved settings on initialisation
  SettingsViewModel() {
    loadSettings();
  }
  
  // Loads user preferences from storage
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('dark_mode') ?? false;
    isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    notifyListeners();
  }
  
  // Saves all user preferences to storage
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDarkMode);
    await prefs.setBool('notifications_enabled', isNotificationsEnabled);
  }
  
  // Updates dark mode preference
  void setDarkMode(bool value) {
    isDarkMode = value;
    saveSettings();
    notifyListeners();
  }
  
  // Updates notifications preference
  void setNotificationsEnabled(bool value) {
    isNotificationsEnabled = value;
    saveSettings();
    notifyListeners();
  }
  
  // Signs user out of the application
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
} 