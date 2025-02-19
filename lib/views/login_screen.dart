import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_up_screen.dart'; // Import Sign-Up Screen


// LoginScreen: Handles user login functionality
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>(); // Key to manage form state
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance for login

  // Function to handle user login
  Future<void> _login(String email, String password) async {
    try {
      // Sign in using Firebase Authentication
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged in successfully!')), // Show success message
      );
      // Navigate to the Home Screen upon successful login
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      // Show error message in case of login failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')), // App bar title
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding around the form
        child: FormBuilder(
          key: _formKey, // Attach form key
          child: Column(
            children: [
              // Email Input Field
              FormBuilderTextField(
                name: 'email', 
                decoration: InputDecoration(labelText: 'Email'),  // Label for the text field
                validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(), // Ensures the field is not empty
                    FormBuilderValidators.email(), // Ensures a valid email address is entered
                ]),
              ),
              const SizedBox(height: 16), // Add spacing between fields

              // Password Input Field
              FormBuilderTextField(
                name: 'password',
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true, // Hides the password text
                validator: FormBuilderValidators.required(), // Ensures the field is not empty
              ),
              const SizedBox(height: 16), // Add spacing between fields

              // Login Button
              ElevatedButton(
                onPressed: () {
                  // Validate the form and perform login
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final email = _formKey.currentState?.fields['email']?.value;
                    final password = _formKey.currentState?.fields['password']?.value;
                    _login(email, password);
                  }
                },
                child: const Text('Login'),
              ),

              // Navigate to Sign-Up Screen
              TextButton(
                onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                    );
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
