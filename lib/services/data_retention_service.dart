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
      print('[DataRetentionService] No user logged in, skipping policy application');
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
      print('[DataRetentionService] Corrected invalid auto-deletion period to "Never delete"');
    }
    
    print('[DataRetentionService] Applying data retention policy with period: $deletionPeriod');
    
    // If chat saving is disabled, we don't need to check for deletion
    if (!saveChatHistory) {
      print('[DataRetentionService] Chat saving is disabled, skipping deletion check');
      return;
    }
    
    // If set to never delete, exit early
    if (deletionPeriod == 'Never delete') {
      print('[DataRetentionService] Auto-deletion is set to "Never delete", skipping');
      return;
    }
    
    // Calculate the cutoff date based on the deletion period
    final now = DateTime.now();
    DateTime cutoffDate;
    
    if (deletionPeriod == '24 hours') {
      cutoffDate = now.subtract(Duration(hours: 24));
      print('[DataRetentionService] Using 24 hour deletion period, cutoff: $cutoffDate');
    } else if (deletionPeriod == '15 days') {
      cutoffDate = now.subtract(Duration(days: 15));
      print('[DataRetentionService] Using 15 day deletion period, cutoff: $cutoffDate');
    } else if (deletionPeriod == '30 days') {
      cutoffDate = now.subtract(Duration(days: 30));
      print('[DataRetentionService] Using 30 day deletion period, cutoff: $cutoffDate');
    } else if (deletionPeriod == '60 days') {
      cutoffDate = now.subtract(Duration(days: 60));
      print('[DataRetentionService] Using 60 day deletion period, cutoff: $cutoffDate');
    } else if (deletionPeriod == '90 days') {
      cutoffDate = now.subtract(Duration(days: 90));
      print('[DataRetentionService] Using 90 day deletion period, cutoff: $cutoffDate');
    } else {
      // Default to 30 days if setting is unrecognized
      cutoffDate = now.subtract(Duration(days: 30));
      print('[DataRetentionService] Unrecognized period setting: $deletionPeriod, defaulting to 30 days');
    }
    
    print('[DataRetentionService] Cutoff date for deletion: $cutoffDate');
    
    // Get all chats and filter manually (more reliable than query)
    final allChats = await _firestore
        .collection('users')
        .doc(user.email)
        .collection('chats')
        .get();
    
    print('[DataRetentionService] Found ${allChats.docs.length} total chats to check');
    
    // Find documents to delete by manually checking their dates
    List<DocumentSnapshot> docsToDelete = [];
    for (var doc in allChats.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        print('[DataRetentionService] Checking chat: ${data['title'] ?? 'Untitled'}');
        
        final chatDateStr = data['createdAt'] as String?;
        if (chatDateStr != null) {
          final chatDate = DateTime.parse(chatDateStr);
          print('[DataRetentionService] Chat date: $chatDate, is before cutoff: ${chatDate.isBefore(cutoffDate)}');
          
          if (chatDate.isBefore(cutoffDate)) {
            docsToDelete.add(doc);
            print('[DataRetentionService] Adding chat for deletion: ${data['title']} created at $chatDate');
          }
        } else {
          print('[DataRetentionService] No createdAt date found for chat: ${data['title'] ?? 'Untitled'}');
        }
      } catch (e) {
        print('[DataRetentionService] Error processing document: $e');
      }
    }
    
    // If no chats to delete, exit
    if (docsToDelete.isEmpty) {
      print('[DataRetentionService] No chats found to delete');
      return;
    }
    
    print('[DataRetentionService] Preparing to delete ${docsToDelete.length} chats');
    
    // Delete old chats in a batch
    final batch = _firestore.batch();
    for (var doc in docsToDelete) {
      batch.delete(doc.reference);
      final data = doc.data() as Map<String, dynamic>;
      print('[DataRetentionService] Adding deletion operation for: ${data['title'] ?? 'Untitled'}');
    }
    
    await batch.commit();
    print('[DataRetentionService] Successfully deleted ${docsToDelete.length} old chats');
  }
} 