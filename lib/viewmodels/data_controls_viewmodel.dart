import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataControlsViewModel extends ChangeNotifier {
  bool saveChatHistory = true;
  String deletionPeriod = '30';
  bool isLoading = true;
  
  DataControlsViewModel() {
    loadPreferences();
  }
  
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    saveChatHistory = prefs.getBool('save_chat_history') ?? true;
    deletionPeriod = prefs.getString('chat_deletion_period') ?? '30';
    isLoading = false;
    notifyListeners();
  }
  
  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('save_chat_history', saveChatHistory);
    await prefs.setString('chat_deletion_period', deletionPeriod);
    notifyListeners();
  }
  
  void setSaveChatHistory(bool value) {
    saveChatHistory = value;
    notifyListeners();
  }
  
  void setDeletionPeriod(String value) {
    deletionPeriod = value;
    notifyListeners();
  }
} 