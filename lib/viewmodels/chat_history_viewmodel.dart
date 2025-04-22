import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';

class ChatHistoryViewModel extends ChangeNotifier {
  final ChatService chatService;
  List<Chat> chats = [];
  bool isLoading = true;
  String? errorMessage;
  
  // Search functionality
  String searchQuery = '';
  List<Chat> filteredChats = [];
  
  // Selection mode
  bool isSelectionMode = false;
  Set<String> selectedChats = {};
  
  Chat? _lastDeletedChat;
  
  ChatHistoryViewModel({required this.chatService}) {
    loadChats();
  }
  
  Future<void> loadChats() async {
    try {
      isLoading = true;
      notifyListeners();
      
      final chatStream = chatService.getChats();
      chats = await chatStream.first;
      filteredChats = List.from(chats);
      
      isLoading = false;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to load chats: $e';
      notifyListeners();
    }
  }
  
  void setSearchQuery(String query) {
    searchQuery = query;
    if (query.isEmpty) {
      filteredChats = List.from(chats);
    } else {
      filteredChats = chats
          .where((chat) => chat.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
  
  void deleteChat(String chatId) async {
    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _lastDeletedChat = chats[chatIndex];
      chats.removeAt(chatIndex);
      filteredChats = List.from(chats);
      notifyListeners();
      
      // Delete from database
      await chatService.deleteChat(chatId);
    }
  }
  
  Future<void> clearAllChats() async {
    try {
      await chatService.clearAllChats();
      chats.clear();
      filteredChats.clear();
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to clear chats: $e';
      notifyListeners();
    }
  }
  
  void selectChat(Chat chat) {
    chatService.setCurrentChat(chat);
  }
  
  // Selection mode methods
  void startSelectionMode() {
    isSelectionMode = true;
    selectedChats.clear();
    notifyListeners();
  }
  
  void cancelSelectionMode() {
    isSelectionMode = false;
    selectedChats.clear();
    notifyListeners();
  }
  
  void toggleChatSelection(String chatId) {
    if (selectedChats.contains(chatId)) {
      selectedChats.remove(chatId);
    } else {
      selectedChats.add(chatId);
    }
    notifyListeners();
  }
  
  bool get areAllChatsSelected => 
      selectedChats.length == filteredChats.length && filteredChats.isNotEmpty;
  
  void toggleSelectAll() {
    if (areAllChatsSelected) {
      selectedChats.clear();
    } else {
      selectedChats = filteredChats.map((chat) => chat.id).toSet();
    }
    notifyListeners();
  }
  
  Future<void> deleteSelectedChats() async {
    try {
      for (final chatId in selectedChats) {
        await chatService.deleteChat(chatId);
        chats.removeWhere((chat) => chat.id == chatId);
      }
      
      filteredChats = chats
          .where((chat) => searchQuery.isEmpty || 
                chat.title.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
      
      cancelSelectionMode();
    } catch (e) {
      errorMessage = 'Failed to delete chats: $e';
      notifyListeners();
    }
  }
  
  // Pin functionality
  Future<void> togglePinChat(Chat chat) async {
    try {
      final updatedChat = chat.copyWith(isPinned: !chat.isPinned);
      await chatService.updateChat(updatedChat);
      
      final index = chats.indexWhere((c) => c.id == chat.id);
      if (index != -1) {
        chats[index] = updatedChat;
        
        final filteredIndex = filteredChats.indexWhere((c) => c.id == chat.id);
        if (filteredIndex != -1) {
          filteredChats[filteredIndex] = updatedChat;
        }
      }
      
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to update chat: $e';
      notifyListeners();
    }
  }
  
  Future<void> pinSelectedChats() async {
    try {
      for (final chatId in selectedChats) {
        final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
        if (chatIndex != -1) {
          final chat = chats[chatIndex];
          final updatedChat = chat.copyWith(isPinned: true);
          await chatService.updateChat(updatedChat);
          chats[chatIndex] = updatedChat;
          
          final filteredIndex = filteredChats.indexWhere((c) => c.id == chatId);
          if (filteredIndex != -1) {
            filteredChats[filteredIndex] = updatedChat;
          }
        }
      }
      
      cancelSelectionMode();
    } catch (e) {
      errorMessage = 'Failed to pin chats: $e';
      notifyListeners();
    }
  }
  
  void undoDelete() {
    if (_lastDeletedChat != null) {
      final index = chats.indexWhere((chat) => chat.createdAt.isAfter(_lastDeletedChat!.createdAt));
      if (index != -1) {
        chats.insert(index, _lastDeletedChat!);
      } else {
        chats.add(_lastDeletedChat!);
      }
      _lastDeletedChat = null;
      notifyListeners();
    }
  }
} 