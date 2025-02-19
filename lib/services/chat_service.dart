import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';

// Manages chat-related operations such as saving, deleting, and retrieving chats
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance for database operations
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance for user authentication

  Chat? _currentChat; // Holds the current chat being interacted with

  // Getter for the current chat
  Chat? get currentChat => _currentChat;

  // Sets the current chat and saves it if not null
  void setCurrentChat(Chat? chat) {
    _currentChat = chat; // Update the current chat
    if (chat != null) {
      saveChat(chat); // Persist the chat when setting it as current
    }
  }

  // Saves a chat to Firestore
  Future<void> saveChat(Chat chat) async {
    final userId = _auth.currentUser?.uid; // Get the current user's ID
    if (userId == null) return; // Exit if no user is logged in

    // Save the chat in the user's chats collection
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chat.id)
        .set(chat.toMap()); // Convert Chat object to Map for storage
  }

  // Deletes a chat from Firestore
  Future<void> deleteChat(String chatId) async {
    final userId = _auth.currentUser?.uid; // Get the current user's ID
    if (userId == null) return; // Exit if no user is logged in

    // Delete the chat document from the user's chats collection
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .delete(); // Remove the chat document
  }

  // Retrieves a stream of chats for the current user
  Stream<List<Chat>> getChats() {
    final userId = _auth.currentUser?.uid; // Get the current user's ID
    if (userId == null) return Stream.value([]); // Return an empty stream if no user is logged in

    // Listen to changes in the user's chats collection
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('createdAt', descending: true) // Order chats by creation date
        .snapshots() // Get real-time updates
        .map((snapshot) {
      // Convert Firestore documents to Chat objects
      return snapshot.docs
          .map((doc) => Chat.fromMap(doc.data())) // Create Chat objects from document data
          .toList(); // Return a list of Chat objects
    });
  }
} 