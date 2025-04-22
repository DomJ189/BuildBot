import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataRetentionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Call this method periodically (e.g., when app starts or on a schedule)
  Future<void> applyDataRetentionPolicy() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final saveChatHistory = prefs.getBool('save_chat_history') ?? true;
    final deletionPeriod = prefs.getString('chat_deletion_period') ?? '30';
    
    // If chat saving is disabled, we don't need to check for deletion
    if (!saveChatHistory) return;
    
    // If set to never delete, exit early
    if (deletionPeriod == 'never') return;
    
    // Calculate the cutoff date based on the deletion period
    final int days = int.tryParse(deletionPeriod) ?? 30;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    // Query for chats older than the cutoff date
    final chatCollection = _firestore
        .collection('users')
        .doc(user.email)
        .collection('chats');
    
    final oldChats = await chatCollection
        .where('createdAt', isLessThan: cutoffDate)
        .get();
    
    // Delete old chats in a batch
    final batch = _firestore.batch();
    for (var doc in oldChats.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
} 