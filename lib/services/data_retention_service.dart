import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataRetentionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Call this method periodically (e.g., when app starts or on a schedule)
  Future<void> applyDataRetentionPolicy() async {
    final user = _auth.currentUser;
    if (user == null) {
      // No need to log this every time
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final saveChatHistory = prefs.getBool('save_chat_history') ?? true;
    
    // Force "Never delete" as default regardless of what's in preferences
    String deletionPeriod = prefs.getString('auto_deletion_period') ?? 'Never delete';
    
    // Set to "Never delete" if for some reason it's set to an invalid value
    if (![
      'Never delete', '24 hours', '15 days', '30 days', '60 days', '90 days'
    ].contains(deletionPeriod)) {
      deletionPeriod = 'Never delete';
      await prefs.setString('auto_deletion_period', deletionPeriod);
      // Keep this as it's important for configuration issues
      print('[DataRetentionService] Corrected invalid auto-deletion period to "Never delete"');
    }
    
    // If chat saving is disabled or set to never delete, exit early
    if (!saveChatHistory || deletionPeriod == 'Never delete') {
      return;
    }
    
    // Calculate the cutoff date based on the deletion period
    final now = DateTime.now();
    DateTime cutoffDate;
    
    // Determine the cutoff date based on retention period
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
      // Default to 30 days if setting is unrecognized
      cutoffDate = now.subtract(Duration(days: 30));
    }
    
    // Get all chats and filter manually (more reliable than query)
    final allChats = await _firestore
        .collection('users')
        .doc(user.email)
        .collection('chats')
        .get();
    
    // Find documents to delete by manually checking their dates
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
        // Log errors but be less verbose
        print('[DataRetentionService] Error processing document: $e');
      }
    }
    
    // If no chats to delete, exit
    if (docsToDelete.isEmpty) {
      return;
    }
    
    // Delete old chats in a batch
    final batch = _firestore.batch();
    for (var doc in docsToDelete) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    
    // Keep this log as it's useful to know what was deleted
    print('[DataRetentionService] Successfully deleted ${docsToDelete.length} old chats');
  }
} 