import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Manages automated chat history cleanup based on user preferences
class DataRetentionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Applies the user's retention policy to delete old chat data
  Future<void> applyDataRetentionPolicy() async {
    // Skip if user not logged in
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    
    // Get user preferences
    final prefs = await SharedPreferences.getInstance();
    final saveChatHistory = prefs.getBool('save_chat_history') ?? true;
    
    // Use "Never delete" as the default retention setting
    String deletionPeriod = prefs.getString('auto_deletion_period') ?? 'Never delete';
    
    // Validate the deletion period is a recognized value
    if (![
      'Never delete', '24 hours', '15 days', '30 days', '60 days', '90 days'
    ].contains(deletionPeriod)) {
      deletionPeriod = 'Never delete';
      await prefs.setString('auto_deletion_period', deletionPeriod);
      print('[DataRetentionService] Corrected invalid auto-deletion period to "Never delete"');
    }
    
    // Exit early if chat saving is disabled or no deletion is needed
    if (!saveChatHistory || deletionPeriod == 'Never delete') {
      return;
    }
    
    // Calculate the cutoff date based on user's retention period setting
    final now = DateTime.now();
    DateTime cutoffDate;
    
    // Set appropriate cutoff date based on user preference
    if (deletionPeriod == '24 hours') {
      cutoffDate = now.subtract(Duration(hours: 24));
    } else if (deletionPeriod == '15 days') {
      cutoffDate = now.subtract(Duration(days: 15));
    } else if (deletionPeriod == '30 days') {
      cutoffDate = now.subtract(Duration(days: 30));
    } else if (deletionPeriod == '60 days') {
      cutoffDate = now.subtract(Duration(days: 60));
    } else if (deletionPeriod == '90 days') {
      cutoffDate = now.subtract(Duration(days: 90));
    } else {
      // Use 30 days as a fallback
      cutoffDate = now.subtract(Duration(days: 30));
    }
    
    // Fetch all the user's chats
    final allChats = await _firestore
        .collection('users')
        .doc(user.email)
        .collection('chats')
        .get();
    
    // Identify chats older than the cutoff date
    List<DocumentSnapshot> docsToDelete = [];
    for (var doc in allChats.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        
        final chatDateStr = data['createdAt'] as String?;
        if (chatDateStr != null) {
          final chatDate = DateTime.parse(chatDateStr);
          
          if (chatDate.isBefore(cutoffDate)) {
            docsToDelete.add(doc);
          }
        }
      } catch (e) {
        print('[DataRetentionService] Error processing document: $e');
      }
    }
    
    // Exit if no chats need deletion
    if (docsToDelete.isEmpty) {
      return;
    }
    
    // Delete old chats using a batch operation for efficiency
    final batch = _firestore.batch();
    for (var doc in docsToDelete) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    
    print('[DataRetentionService] Successfully deleted ${docsToDelete.length} old chats');
  }
} 