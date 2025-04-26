import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

// Handles password recovery functionality for users who forgot their password
class ForgotPasswordViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;  // Tracks operation progress
  String? errorMessage;    // Stores error messages
  String? email;           // Email address for password reset
  
  // Sends password reset email via Firebase Auth
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      isLoading = true;
      this.email = email;
      notifyListeners();

      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email);

      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;  // Email sent successfully
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to send password reset email: ${e.toString()}';
      notifyListeners();
      return false;  // Email sending failed
    }
  }
}
