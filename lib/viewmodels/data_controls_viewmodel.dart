import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';

// Manages data retention and chat history settings
class DataControlsViewModel extends ChangeNotifier {
  final ChatService _chatService;
  bool saveChatHistory = true;
  String deletionPeriod = '30';
  bool isLoading = true;
  
  // Initialie with required services
  DataControlsViewModel({ChatService? chatService}) 
      : _chatService = chatService ?? ChatService() {
    loadPreferences();
  }
  
  // Load saved user preferences from storage
  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get chat saving preference from service
      saveChatHistory = await _chatService.isChatSavingEnabled();
      
      // Get auto-deletion period with fallback
      String period = prefs.getString('auto_deletion_period') ?? 'Never';
      
      // Convert legacy string format to new numeric format
      if (period == 'Never delete') {
        period = 'Never';
      } else if (period == '24 hours') {
        period = '1';
      } else if (period.endsWith(' days')) {
        period = period.split(' ')[0];
      }
      
      deletionPeriod = period;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading preferences: $e');
      isLoading = false;
      notifyListeners();
    }
  }
  
  // Save preferences to storage and apply to services
  Future<void> savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save chat history preference to service
      await _chatService.setChatSavingEnabled(saveChatHistory);
      
      // Save auto-deletion period
      await prefs.setString('auto_deletion_period', deletionPeriod);
      
      // Apply auto-deletion period to service
      await _chatService.setAutoDeletionPeriod(
        deletionPeriod == 'Never' ? 'Never delete' : 
        deletionPeriod == '1' ? '24 hours' : 
        '$deletionPeriod days'
      );
      
      notifyListeners();
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }
  
  // Update chat saving preference
  void setSaveChatHistory(bool value) {
    saveChatHistory = value;
    notifyListeners();
  }
  
  // Update deletion period preference
  void setDeletionPeriod(String value) {
    deletionPeriod = value;
    notifyListeners();
  }
} 