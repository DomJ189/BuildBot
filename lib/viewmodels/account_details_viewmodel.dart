import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountDetailsViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  
  String get displayName => currentUser?.displayName ?? 'User';
  String get email => currentUser?.email ?? '';
  DateTime get creationDate => currentUser?.metadata.creationTime ?? DateTime.now();
  String get initial => displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  
  // Update user profile
  Future<void> updateDisplayName(String newName) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(newName);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update display name: $e');
    }
  }
  
  // Update email
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      if (currentUser != null) {
        // Re-authenticate user first
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser!.email!,
          password: password,
        );
        
        await currentUser!.reauthenticateWithCredential(credential);
        
        // Use verifyBeforeUpdateEmail to send verification to the new email
        await currentUser!.verifyBeforeUpdateEmail(newEmail);
        
        // Store the pending email change in Firestore for reference
        final userEmail = currentUser!.email;
        if (userEmail != null) {
          await _firestore
              .collection('users')
              .doc(userEmail)
              .set({
                'pendingEmail': newEmail,
                'requestedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
        
        notifyListeners();
        return;
      }
    } catch (e) {
      if (e.toString().contains('requires-recent-login')) {
        throw Exception('Please log out and log back in before changing your email');
      } else if (e.toString().contains('email-already-in-use')) {
        throw Exception('This email is already in use by another account');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('The email address is not valid');
      } else if (e.toString().contains('wrong-password')) {
        throw Exception('The password you entered is incorrect');
      } else {
        throw Exception('Failed to update email: $e');
      }
    }
  }
  
  // Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      if (currentUser != null) {
        // Re-authenticate user before changing password
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser!.email!,
          password: currentPassword,
        );
        
        await currentUser!.reauthenticateWithCredential(credential);
        await currentUser!.updatePassword(newPassword);
      }
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }
  
  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) return;
      
      final userEmail = user.email;
      if (userEmail == null) {
        throw Exception('No email associated with this account');
      }
      
      // 1. Delete all user's chats from Firestore
      final chatCollection = _firestore
          .collection('users')
          .doc(userEmail)
          .collection('chats');
          
      final chatDocs = await chatCollection.get();
      
      // Create a batch operation for efficient deletion
      final batch = _firestore.batch();
      
      for (var doc in chatDocs.docs) {
        batch.delete(doc.reference);
      }
      
      // 2. Delete the user document itself
      batch.delete(_firestore.collection('users').doc(userEmail));
      
      // 3. Execute the batch deletion
      await batch.commit();
      
      // 4. Delete user's shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all preferences for this user
      
      // 5. Delete the Firebase Authentication account
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
  
  // Check for pending email changes
  Future<void> checkPendingEmailChanges() async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) return;
      
      final userDoc = await _firestore
          .collection('users')
          .doc(user.email)
          .get();
      
      if (userDoc.exists && userDoc.data()!.containsKey('pendingEmail')) {
        // Just log the pending email for now
        final pendingEmail = userDoc.data()!['pendingEmail'];
        print('Pending email change found: $pendingEmail');
        
        // In a real app, you would verify that the user has clicked the verification link
        // For this demo, we'll just show a message
      }
    } catch (e) {
      print('Error checking pending email changes: $e');
    }
  }
  
  // Migrate user data after email change
  Future<void> migrateUserData(String oldEmail, String newEmail) async {
    try {
      // 1. Get all collections and documents from the old email
      final oldUserDoc = await _firestore.collection('users').doc(oldEmail).get();
      
      // 2. If the old user document exists, copy its data to the new email
      if (oldUserDoc.exists) {
        final userData = oldUserDoc.data();
        if (userData != null) {
          // Remove the pendingEmail field if it exists
          userData.remove('pendingEmail');
          userData.remove('requestedAt');
          
          // Create the new user document with the same data
          await _firestore.collection('users').doc(newEmail).set(userData);
        }
      }
      
      // 3. Copy all chats from old email to new email
      final oldChatsCollection = _firestore
          .collection('users')
          .doc(oldEmail)
          .collection('chats');
      
      final newChatsCollection = _firestore
          .collection('users')
          .doc(newEmail)
          .collection('chats');
      
      final chatDocs = await oldChatsCollection.get();
      
      // Create a batch for efficient writes
      final batch = _firestore.batch();
      
      // Copy each chat document
      for (var doc in chatDocs.docs) {
        final newDocRef = newChatsCollection.doc(doc.id);
        batch.set(newDocRef, doc.data());
      }
      
      // Execute the batch
      await batch.commit();
      
      // 4. Delete the old user data after successful migration
      // First delete all chat documents
      final batchDelete = _firestore.batch();
      for (var doc in chatDocs.docs) {
        batchDelete.delete(doc.reference);
      }
      
      // Then delete the user document itself
      batchDelete.delete(_firestore.collection('users').doc(oldEmail));
      
      // Execute the deletion batch
      await batchDelete.commit();
      
      print('User data migrated from $oldEmail to $newEmail and old data deleted');
    } catch (e) {
      print('Error migrating user data: $e');
    }
  }
  
  // Check if user email has changed and migrate data if needed
  Future<void> checkAndMigrateUserData() async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) return;
      
      final userEmail = user.email!;
      
      // Check all documents in the users collection
      final usersCollection = await _firestore.collection('users').get();
      
      // Find the most recent document with a pendingEmail matching the current email
      DocumentSnapshot? mostRecentDoc;
      Timestamp? mostRecentTimestamp;
      
      for (var doc in usersCollection.docs) {
        // Skip the current email document
        if (doc.id == userEmail) continue;
        
        // Check if this document has a pendingEmail that matches the current email
        final data = doc.data();
        if (data.containsKey('pendingEmail') && data['pendingEmail'] == userEmail) {
          // Check if this is the most recent change
          if (data.containsKey('requestedAt')) {
            final timestamp = data['requestedAt'];
            if (mostRecentTimestamp == null || timestamp.compareTo(mostRecentTimestamp) > 0) {
              mostRecentTimestamp = timestamp;
              mostRecentDoc = doc;
            }
          } else {
            // If no timestamp, just use the first one found
            mostRecentDoc ??= doc;
          }
        }
      }
      
      // If we found a document, migrate from the most recent one
      if (mostRecentDoc != null) {
        final oldEmail = mostRecentDoc.id;
        await migrateUserData(oldEmail, userEmail);
        
        // Update a flag in the new document to indicate migration is complete
        await _firestore.collection('users').doc(userEmail).set({
          'migratedFrom': oldEmail,
          'migratedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error checking for email change: $e');
    }
  }
  
  // Re-authenticate user with password
  Future<void> reauthenticateUser(String password) async {
    try {
      if (currentUser != null && currentUser!.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser!.email!,
          password: password,
        );
        
        await currentUser!.reauthenticateWithCredential(credential);
      } else {
        throw Exception('No user is currently signed in');
      }
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        throw Exception('Incorrect password');
      } else {
        throw Exception('Authentication failed: $e');
      }
    }
  }
} 