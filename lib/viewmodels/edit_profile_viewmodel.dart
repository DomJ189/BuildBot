import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class EditProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
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