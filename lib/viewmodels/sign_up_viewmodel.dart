import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  String? errorMessage;

  // Function to handle user registration
  Future<bool> signUp(String email, String password, String firstName, String lastName) async {
    try {
      isLoading = true;
      notifyListeners();
      
      // Sign up using Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Update the user's display name
      await userCredential.user?.updateDisplayName('$firstName $lastName');
      
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Registration failed: $e';
      notifyListeners();
      return false;
    }
  }
} 