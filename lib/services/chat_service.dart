import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Manages chat-related operations such as saving, deleting, and retrieving chats
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance for database operations
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance for user authentication

  Chat? _currentChat; // Holds the current chat being interacted with
  final StreamController<List<Chat>> _chatStreamController = StreamController<List<Chat>>.broadcast();

  // Add this property
  double _typingSpeed = 1.5; // Default medium speed
  
  // Add getter
  double get typingSpeed => _typingSpeed;
  
  // Add setter method
  void setTypingSpeed(double speed) {
    _typingSpeed = speed;
    // Optionally save to SharedPreferences
    _saveTypingSpeedPreference();
  }
  
  // Method to save preference
  Future<void> _saveTypingSpeedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('typing_speed', _typingSpeed);
  }
  
  // Method to load preference (call this in your initialisation)
  Future<void> loadTypingSpeedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _typingSpeed = prefs.getDouble('typing_speed') ?? 1.5;
  }

  // Getter for the current chat
  Chat? get currentChat => _currentChat;

  // Sets the current chat and saves it if not null
  void setCurrentChat(Chat? chat) {
    _currentChat = chat; // Update the current chat
    if (chat != null) {
      saveChat(chat); // Persist the chat when setting it as current
    }
  }

  // Get the current user's email as document ID
  String? _getUserDocId() {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return null;
    return user.email;
  }

  // Get the current user's display name for the avatar
  String get currentUserDisplayName {
    final user = _auth.currentUser;
    return user?.displayName ?? 'User';
  }

  // Add this method to check if chat saving is enabled
  Future<bool> isChatSavingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('save_chat_history') ?? true; // Default to true if not set
  }

  // Modify your saveChat method to ensure proper timestamp handling
  Future<void> saveChat(Chat chat) async {
    // Check if chat saving is enabled
    final saveChatHistory = await isChatSavingEnabled();
    if (!saveChatHistory) {
      // If chat saving is disabled, don't save to database
      // But we might want to keep it in memory for the current session
      _currentChat = chat;
      return;
    }

    // Original save logic continues here if saving is enabled
    final user = _auth.currentUser;
    if (user == null) return;

    // Use sanitised title as document ID if available, otherwise use chat.id
    final docId = chat.title.isNotEmpty ? _sanitiseDocumentId(chat.title) : chat.id;
    
    // Create a data map with the proper timestamp format
    final data = chat.toMap();
    
    // Add a Firestore timestamp field to ensure proper date comparison
    data['firestoreTimestamp'] = FieldValue.serverTimestamp();
    
    await _firestore
        .collection('users')
        .doc(user.email)
        .collection('chats')
        .doc(docId)
        .set({
          ...data,
          'docId': docId, // Store the document ID for reference
        });
    
    // Update current chat
    _currentChat = chat;
  }

  // Sanitise the title to be used as a document ID
  String _sanitiseDocumentId(String title) {
    // Remove invalid characters and limit length
    String sanitised = title
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special chars except underscore, space, hyphen
        .trim()
        .replaceAll(RegExp(r'\s+'), '_'); // Replace spaces with underscores
    
    // Limit to 100 chars to avoid Firestore limitations
    if (sanitised.length > 100) {
      sanitised = sanitised.substring(0, 100);
    }
    
    // Ensure it's not empty
    return sanitised.isEmpty ? 'untitled_chat' : sanitised;
  }

  // Deletes a chat from Firestore
  Future<void> deleteChat(String chatId) async {
    final userEmail = _getUserDocId();
    if (userEmail == null) return;

    // First, find the document with matching chatId
    final snapshot = await _firestore
        .collection('users')
        .doc(userEmail)
        .collection('chats')
        .where('id', isEqualTo: chatId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Delete the found document
      await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('chats')
          .doc(snapshot.docs.first.id)
          .delete();
        
      // Clear current chat if it's the one being deleted
      if (_currentChat?.id == chatId) {
        _currentChat = null;
      }
    }
  }

  // Toggle pin status
  Future<void> togglePinChat(Chat chat) async {
    final userEmail = _getUserDocId();
    if (userEmail == null) return;

    // Create a new chat with toggled pin status
    final updatedChat = chat.copyWith(isPinned: !chat.isPinned);
    
    // Find the document with matching chatId
    final snapshot = await _firestore
        .collection('users')
        .doc(userEmail)
        .collection('chats')
        .where('id', isEqualTo: chat.id)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Update the chat in Firestore
      await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('chats')
          .doc(snapshot.docs.first.id)
          .set({
            ...updatedChat.toMap(),
            'docId': snapshot.docs.first.id, // Preserve the document ID
          });
          
      // Update current chat if it's the one being modified
      if (_currentChat?.id == chat.id) {
        setCurrentChat(updatedChat);
      }
    }
  }

  // Add this method to initialise chat history
  Future<void> initialiseChatHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Load initial chats
      final initialChats = await _firestore
          .collection('users')
          .doc(user.email)
          .collection('chats')
          .orderBy('isPinned', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      // Convert to Chat objects and notify listeners
      final chats = initialChats.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('docId')) {
          data['docId'] = doc.id;
        }
        return Chat.fromMap(data);
      }).toList();

      _chatStreamController.add(chats);
    } catch (e) {
      print('Error initialising chat history: $e');
      _chatStreamController.add([]);
    }
  }

  // Modify your getChats method
  Stream<List<Chat>> getChats() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    // Check if chat saving is enabled
    final saveChatHistory = await isChatSavingEnabled();
    
    if (!saveChatHistory) {
      // If chat saving is disabled, only return the current chat if it exists
      if (_currentChat != null) {
        yield [_currentChat!];
      } else {
        yield [];
      }
      return;
    }

    try {
      // Initialise chat history first
      await initialiseChatHistory();
      
      // Then listen for real-time updates
      yield* _firestore
          .collection('users')
          .doc(user.email)
          .collection('chats')
          .orderBy('isPinned', descending: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          // Ensure the document ID is included in the chat data
          if (!data.containsKey('docId')) {
            data['docId'] = doc.id;
          }
          return Chat.fromMap(data);
        }).toList();
      });
    } catch (e) {
      // Handle the error (likely missing index)
      print('Error fetching chats: $e');
      yield [];
    }
  }

  // Modify your createChat method to ensure proper timestamp handling
  Future<Chat> createChat(String title) async {
    final saveChatHistory = await isChatSavingEnabled();
    
    // Generate a unique ID for the chat
    final chatId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create the chat object with the current time
    final now = DateTime.now();
    final chat = Chat(
      id: chatId,
      title: title,
      messages: [],
      createdAt: now,
      isPinned: false,
    );

    // Only save to database if chat saving is enabled
    if (saveChatHistory) {
      final user = _auth.currentUser;
      if (user != null) {
        // Use sanitised title as document ID if available, otherwise use chatId
        final docId = title.isNotEmpty ? _sanitiseDocumentId(title) : chatId;
        
        // Convert chat to map and add server timestamp
        final data = chat.toMap();
        data['firestoreTimestamp'] = FieldValue.serverTimestamp();
        
        await _firestore
            .collection('users')
            .doc(user.email)
            .collection('chats')
            .doc(docId)
            .set({
              ...data,
              'docId': docId, // Store the document ID for reference
            });
      }
    }

    // Set as current chat and notify listeners
    _currentChat = chat;
    _chatStreamController.add([chat]);
    
    return chat;
  }

  // Add this method to your ChatService class
  Future<void> clearAllChats() async {
    // Implementation depends on how your chats are stored
    // For example, if using Firestore:
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail != null) {
      final chatCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('chats');
          
      final chatDocs = await chatCollection.get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in chatDocs.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    }
    
    // Clear current chat
    setCurrentChat(null);
  }

  // Add this method to your ChatService class
  Future<void> updateChat(Chat chat) async {
    final userEmail = _getUserDocId();
    if (userEmail == null) return;
    
    try {
      // First, try to find the existing document by querying for the chat ID
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('chats')
          .where('id', isEqualTo: chat.id)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // If we found the document, update it using its actual document ID
        final docId = querySnapshot.docs.first.id;
        await _firestore
            .collection('users')
            .doc(userEmail)
            .collection('chats')
            .doc(docId)
            .update(chat.toMap());
      } else {
        // If document doesn't exist, create a new one
        await _firestore
            .collection('users')
            .doc(userEmail)
            .collection('chats')
            .doc(chat.id) // Use chat.id as the document ID
            .set(chat.toMap());
      }
      
      // If this is the current chat, update it
      if (_currentChat?.id == chat.id) {
        _currentChat = chat;
      }
    } catch (e) {
      print('Error updating chat: $e');
      throw Exception('Failed to update chat: $e');
    }
  }

  // Add this method to your ChatService class
  Future<void> setChatSavingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('save_chat_history', enabled);
  }

  // Add these properties to the ChatService class
  Timer? _autoDeletionTimer;
  final Duration _checkInterval = Duration(hours: 1); // Check once per hour instead of every minute

  // Update this method to initialise auto-deletion
  void initialiseAutoDeletion() {
    // Cancel any existing timer
    _autoDeletionTimer?.cancel();
    
    // Run immediately once
    _performAutoDeletion();
    
    // Then set up periodic checks
    _autoDeletionTimer = Timer.periodic(_checkInterval, (_) {
      _performAutoDeletion();
    });
  }
  
  // Update this method to perform the auto-deletion
  Future<void> _performAutoDeletion() async {
    try {
      // Get the current auto-deletion period setting
      final prefs = await SharedPreferences.getInstance();
      // Force "Never delete" as default regardless of what's in preferences
      String periodSetting = prefs.getString('auto_deletion_period') ?? 'Never delete';
      
      // Set to "Never delete" if for some reason it's set to an invalid value
      if (![
        'Never delete', '24 hours', '15 days', '30 days', '60 days', '90 days'
      ].contains(periodSetting)) {
        periodSetting = 'Never delete';
        await prefs.setString('auto_deletion_period', periodSetting);
        // Only log this as it indicates a configuration problem
        print('Corrected invalid auto-deletion period to "Never delete"');
      }
      
      // If set to never delete, exit early
      if (periodSetting == 'Never delete') {
        return;
      }
      
      // Calculate the cutoff date based on the period setting
      final now = DateTime.now();
      DateTime cutoffDate;
      
      if (periodSetting == '24 hours') {
        cutoffDate = now.subtract(Duration(hours: 24));
      } else if (periodSetting == '15 days') {
        cutoffDate = now.subtract(Duration(days: 15));
      } else if (periodSetting == '30 days') {
        cutoffDate = now.subtract(Duration(days: 30));
      } else if (periodSetting == '60 days') {
        cutoffDate = now.subtract(Duration(days: 60));
      } else if (periodSetting == '90 days') {
        cutoffDate = now.subtract(Duration(days: 90));
      } else {
        // Default to 30 days if setting is unrecognised
        cutoffDate = now.subtract(Duration(days: 30));
      }
      
      // Get the user's email
      final userEmail = _getUserDocId();
      if (userEmail == null) {
        // No active user session, can't perform deletion
        return;
      }
      
      // Get all chats to ensure accuracy
      final allChats = await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('chats')
          .get();
      
      // Find documents to delete by checking their dates manually
      List<DocumentSnapshot> docsToDelete = [];
      
      for (var doc in allChats.docs) {
        try {
          final data = doc.data();
          
          // Check if chat has a creation date
          final chatDateStr = data['createdAt'] as String?;
          if (chatDateStr != null) {
            final chatDate = DateTime.parse(chatDateStr);
            
            // Check if chat is older than cutoff date
            if (chatDate.isBefore(cutoffDate)) {
              docsToDelete.add(doc);
            }
          }
        } catch (e) {
          // Skip chats with invalid dates
        }
      }
      
      // If no chats to delete, exit
      if (docsToDelete.isEmpty) {
        return;
      }
      
      // Delete the old chats in a batch
      final batch = _firestore.batch();
      for (var doc in docsToDelete) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch deletion
      await batch.commit();
      
      // Log the deletion - this is important to keep
      print('Successfully auto-deleted ${docsToDelete.length} chats older than $periodSetting');
      
      // Refresh the chat list after deletion
      initialiseChatHistory();
      
    } catch (e) {
      // Keep error logs
      print('Error performing auto-deletion: $e');
    }
  }

  // Modify the setAutoDeletionPeriod method to trigger a check
  Future<void> setAutoDeletionPeriod(String period) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auto_deletion_period', period);
    
    // Run auto-deletion check immediately after changing the setting
    _performAutoDeletion();
  }

  // Add this to dispose method or create one if it doesn't exist
  void dispose() {
    _autoDeletionTimer?.cancel();
    _chatStreamController.close();
  }

  // Add this method to run auto-deletion check manually
  Future<void> runAutoDeletionCheck() async {
    print('Manually triggering auto-deletion check...');
    return _performAutoDeletion();
  }
} 