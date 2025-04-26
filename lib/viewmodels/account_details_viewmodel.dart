import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Manages user account details and authentication operations
class AccountDetailsViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool isLoading = false; // Tracks operation progress
  String? errorMessage;   // Stores error messages
  
  // Get the current Firebase user
  User? get currentUser => _auth.currentUser;
  
  String get displayName => currentUser?.displayName ?? 'User';
  String get email => currentUser?.email ?? '';
  DateTime get creationDate => currentUser?.metadata.creationTime ?? DateTime.now();
  String get initial => displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  
  // Update user display name
  Future<bool> updateDisplayName(String newName) async {
    try {
      isLoading = true;
      notifyListeners();
      
      // Update display name in Firebase Auth
      await currentUser?.updateDisplayName(newName);
      
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Update user email with validation
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      isLoading = true;
      notifyListeners();
      
      // Re-authenticate user before changing email
      await reauthenticateUser(password);
      
      // Store old email for data migration
      final oldEmail = currentUser?.email;
      
      // Send verification email before updating email in Firebase Auth
      await currentUser?.verifyBeforeUpdateEmail(newEmail);
      
      // Mark pending email change in Firestore to handle migration on next login
      if (oldEmail != null) {
        await _firestore.collection('users').doc(oldEmail).set({
          'pendingEmail': newEmail,
          'requestedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      throw errorMessage!;
    }
  }
  
  // Update user password with validation
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      isLoading = true;
      notifyListeners();
      
      // Re-authenticate before password change
      await reauthenticateUser(currentPassword);
      
      // Update password in Firebase Auth
      await currentUser?.updatePassword(newPassword);
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      throw errorMessage!;
    }
  }
  
  // Migrate user data between emails
  Future<void> migrateUserData(String oldEmail, String newEmail) async {
    try {
      // Get all chat documents for old email
      final chatDocs = await _firestore.collection('users').doc(oldEmail).collection('chats').get();
      
      // Create batch for efficient writing
      final batch = _firestore.batch();
      
      // Copy each chat to the new user account
      for (var doc in chatDocs.docs) {
        final newDocRef = _firestore.collection('users').doc(newEmail).collection('chats').doc(doc.id);
        batch.set(newDocRef, doc.data());
      }
      
      // Execute the batch write
      await batch.commit();
      
      // Delete old data
      final batchDelete = _firestore.batch();
      for (var doc in chatDocs.docs) {
        batchDelete.delete(doc.reference);
      }
      
      // Delete the old user document
      batchDelete.delete(_firestore.collection('users').doc(oldEmail));
      
      // Execute deletion
      await batchDelete.commit();
      
      print('User data migrated from $oldEmail to $newEmail and old data deleted');
    } catch (e) {
      print('Error migrating user data: $e');
    }
  }
  
  // Check for pending email changes and migrate data
  Future<void> checkAndMigrateUserData() async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) return;
      
      final userEmail = user.email!;
      
      // Find documents that have a pendingEmail matching current email
      final usersCollection = await _firestore.collection('users').get();
      
      DocumentSnapshot? mostRecentDoc;
      Timestamp? mostRecentTimestamp;
      
      for (var doc in usersCollection.docs) {
        // Skip current email document
        if (doc.id == userEmail) continue;
        
        // Check for pending email change
        final data = doc.data();
        if (data.containsKey('pendingEmail') && data['pendingEmail'] == userEmail) {
          if (data.containsKey('requestedAt')) {
            final timestamp = data['requestedAt'];
            if (mostRecentTimestamp == null || timestamp.compareTo(mostRecentTimestamp) > 0) {
              mostRecentTimestamp = timestamp;
              mostRecentDoc = doc;
            }
          } else {
            mostRecentDoc ??= doc;
          }
        }
      }
      
      // Migrate data if needed
      if (mostRecentDoc != null) {
        final oldEmail = mostRecentDoc.id;
        await migrateUserData(oldEmail, userEmail);
        
        // Mark migration complete
        await _firestore.collection('users').doc(userEmail).set({
          'migratedFrom': oldEmail,
          'migratedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error checking for email change: $e');
    }
  }
  
  // Re-authenticate user for security-sensitive operations
  Future<void> reauthenticateUser(String password) async {
    try {
      if (currentUser != null && currentUser!.email != null) {
        // Create credential with current email and provided password
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser!.email!,
          password: password,
        );
        
        // Re-authenticate with Firebase
        await currentUser!.reauthenticateWithCredential(credential);
      } else {
        throw 'No user is currently signed in.';
      }
    } catch (e) {
      String errorMsg = e.toString();
      
      // Convert technical errors to user-friendly messages
      if (errorMsg.contains('invalid-credential') || errorMsg.contains('invalid-email-credential')) {
        throw 'Your password is incorrect. Please check and try again.';
      } else if (errorMsg.contains('wrong-password')) {
        throw 'Incorrect password. Please check and try again.';
      } else if (errorMsg.contains('network-request-failed')) {
        throw 'Network error. Please check your internet connection and try again.';
      } else if (errorMsg.contains('too-many-requests')) {
        throw 'Too many failed attempts. Please try again later.';
      } else {
        throw 'Authentication failed. Please try again later.';
      }
    }
  }
  
  // Delete user account and associated data
  Future<void> deleteAccount() async {
    try {
      if (currentUser != null && currentUser!.email != null) {
        final userEmail = currentUser!.email!;
        
        //Get all chat documents from subcollection
        final chatDocs = await _firestore
            .collection('users')
            .doc(userEmail)
            .collection('chats')
            .get();
        
        // Create batch for efficient deletion
        WriteBatch batch = _firestore.batch();
        
        // Add chat documents to deletion batch
        for (var doc in chatDocs.docs) {
          batch.delete(doc.reference);
        }
        
        //Execute batch deletion of chats
        await batch.commit();
        
        // Delete main user document
        await _firestore.collection('users').doc(userEmail).delete();
        
        // Delete any pending email change references
        final usersCollection = await _firestore.collection('users').get();
        batch = _firestore.batch();
        
        for (var doc in usersCollection.docs) {
          final data = doc.data();
          if (data.containsKey('pendingEmail') && data['pendingEmail'] == userEmail) {
            batch.delete(doc.reference);
          }
        }
        
        await batch.commit();
        
        // Delete Firebase Auth account
        await currentUser!.delete();
        
        print('Successfully deleted user account and all associated data');
      } else {
        throw 'No user is currently signed in.';
      }
    } catch (e) {
      print('Error during account deletion: $e');
      throw e.toString();
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
      }
    } catch (e) {
      print('Error checking pending email changes: $e');
    }
  }
} 