import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ForgotPasswordViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  String? errorMessage;
  String? email;
  
  // Method to send a standard password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      isLoading = true;
      this.email = email;
      notifyListeners();

      // Send a standard password reset email using Firebase Auth
      await _auth.sendPasswordResetEmail(email: email);

      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to send password reset email: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // This is kept for compatibility with reset_password_screen.dart
  // In practice, this would be implemented differently in a production app without dynamic links
  Future<bool> resetPassword(String newPassword) async {
    try {
      isLoading = true;
      notifyListeners();
      
      // In a real implementation, this would be used for already authenticated users
      // For demonstration purposes only
      await Future.delayed(Duration(seconds: 1));
      
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to reset password: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
} 