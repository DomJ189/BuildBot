import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Handles user authentication logic for the login screen
class LoginViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;  // Tracks authentication progress
  String? errorMessage;    // Stores error messages for display

  // Attempts to sign in using email and password
  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();
      
      // Authenticate with Firebase Auth
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;  // Login successful
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();  // Store error for UI display
      notifyListeners();
      return false;  // Login failed
    }
  }
} 