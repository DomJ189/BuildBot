import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';

// Manages state and logic for the chat history screen
class ChatHistoryViewModel extends ChangeNotifier {
  final ChatService chatService;
  List<Chat> chats = [];       // All user's chats
  bool isLoading = true;       // Loading state flag
  String? errorMessage;        // Error display message
  
  // Search functionality vars
  String searchQuery = '';     
  List<Chat> filteredChats = []; 
  
  // Selection mode variables
  bool isSelectionMode = false;
  Set<String> selectedChats = {};
  
  // Store deleted chat for undo
  Chat? _lastDeletedChat;
  
  // Initialise with chat service
  ChatHistoryViewModel({required this.chatService}) {
    loadChats();
  }
  
  // Load all user chats
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
  
  // Update search query and filter results
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
  
  // Delete chat by ID
  void deleteChat(String chatId) async {
    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _lastDeletedChat = chats[chatIndex];
      chats.removeAt(chatIndex);
      filteredChats = List.from(chats);
      notifyListeners();
      
      await chatService.deleteChat(chatId);
    }
  }
  
  // Delete all user chats
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
  
  // Set active chat
  void selectChat(Chat chat) {
    chatService.setCurrentChat(chat);
  }
  
  // Start chat selection mode
  void startSelectionMode() {
    isSelectionMode = true;
    selectedChats.clear();
    notifyListeners();
  }
  
  // Exit selection mode
  void cancelSelectionMode() {
    isSelectionMode = false;
    selectedChats.clear();
    notifyListeners();
  }
  
  // Toggle chat selected state
  void toggleChatSelection(String chatId) {
    if (selectedChats.contains(chatId)) {
      selectedChats.remove(chatId);
    } else {
      selectedChats.add(chatId);
    }
    notifyListeners();
  }
  
  // Check if all visible chats are selected
  bool get areAllChatsSelected => 
      selectedChats.length == filteredChats.length && filteredChats.isNotEmpty;
  
  // Toggle selection of all visible chats
  void toggleSelectAll() {
    if (areAllChatsSelected) {
      selectedChats.clear();
    } else {
      selectedChats = filteredChats.map((chat) => chat.id).toSet();
    }
    notifyListeners();
  }
  
  // Delete all selected chats
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
  
  // Toggle chat pinned status
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
  
  // Pin all selected chats
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
  
  // Restore last deleted chat
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