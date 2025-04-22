import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart'; - Remove this
import 'dart:io';

class EditProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance; - Remove this
  
  bool isLoading = false;
  String? errorMessage;
  String? profileImageUrl;
  File? selectedImageFile;
  
  // User information getters
  String get userName => _auth.currentUser?.displayName ?? 'User';
  String get userEmail => _auth.currentUser?.email ?? 'No email';
  
  EditProfileViewModel() {
    loadUserProfile();
  }
  
  Future<void> loadUserProfile() async {
    try {
      isLoading = true;
      notifyListeners();
      
      // Get profile image URL if it exists
      profileImageUrl = _auth.currentUser?.photoURL;
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to load profile: $e';
      notifyListeners();
    }
  }
  
  void setSelectedImage(File imageFile) {
    selectedImageFile = imageFile;
    notifyListeners();
  }
  
  Future<bool> updateProfile(String firstName, String lastName) async {
    try {
      isLoading = true;
      notifyListeners();
      
      // Comment out image upload functionality for now
      /*
      if (selectedImageFile != null) {
        final ref = _storage.ref().child('profile_images/${_auth.currentUser?.uid}');
        await ref.putFile(selectedImageFile!);
        final downloadUrl = await ref.getDownloadURL();
        await _auth.currentUser?.updatePhotoURL(downloadUrl);
        profileImageUrl = downloadUrl;
      }
      */
      
      // Update display name
      await _auth.currentUser?.updateDisplayName('$firstName $lastName');
      
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }
} 