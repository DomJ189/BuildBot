import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Manages account creation logic
class SignUpViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;  // Tracks registration progress
  String? errorMessage;    // Stores error messages for display

  // Creates a new user account and profile
  Future<bool> signUp(String email, String password, String firstName, String lastName) async {
    try {
      isLoading = true;
      notifyListeners();
      
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Set user's display name
      await userCredential.user?.updateDisplayName('$firstName $lastName');
      
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;  // Registration successful
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return false;  // Registration failed
    }
  }
} 