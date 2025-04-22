import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  String? errorMessage;

  // Function to handle user login
  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();
      
      // Sign in using Firebase Authentication
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Login failed: $e';
      notifyListeners();
      return false;
    }
  }
} 