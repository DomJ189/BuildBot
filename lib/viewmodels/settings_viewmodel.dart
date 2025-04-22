import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // User information
  String get userName => _auth.currentUser?.displayName ?? 'User';
  String get userEmail => _auth.currentUser?.email ?? 'No email';
  
  // Settings state
  bool isDarkMode = false;
  bool isNotificationsEnabled = true;
  
  SettingsViewModel() {
    loadSettings();
  }
  
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('dark_mode') ?? false;
    isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    notifyListeners();
  }
  
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDarkMode);
    await prefs.setBool('notifications_enabled', isNotificationsEnabled);
  }
  
  void setDarkMode(bool value) {
    isDarkMode = value;
    saveSettings();
    notifyListeners();
  }
  
  void setNotificationsEnabled(bool value) {
    isNotificationsEnabled = value;
    saveSettings();
    notifyListeners();
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
} 