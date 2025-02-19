import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Handles user registration functionality
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormBuilderState>(); // Key to manage form state
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance for sign-up

  // Function to handle user registration
  Future<void> _signUp(String email, String password, String firstName, String lastName) async {
    try {
      // Sign up using Firebase Authentication
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Update the user's display name
      await _auth.currentUser?.updateProfile(displayName: '$firstName $lastName');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registered successfully!')), // Show success message
      );
      // Navigate to the Login Screen upon successful registration
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // Show error message in case of registration failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')), // App bar title
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding around the form
        child: FormBuilder(
          key: _formKey, // Attach form key
          child: Column(
            children: [
              // First Name Field
              FormBuilderTextField(
                name: 'firstName',
                decoration: InputDecoration(labelText: 'First Name'),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(2),
                ]),
              ),
              const SizedBox(height: 16),
              // Last Name Field
              FormBuilderTextField(
                name: 'lastName',
                decoration: InputDecoration(labelText: 'Last Name'),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(2),
                ]),
              ),
              const SizedBox(height: 16),
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

              // Sign Up Button
              ElevatedButton(
                onPressed: () {
                  // Validate the form and perform sign-up
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final email = _formKey.currentState?.fields['email']?.value;
                    final password = _formKey.currentState?.fields['password']?.value;
                    final firstName = _formKey.currentState?.fields['firstName']?.value;
                    final lastName = _formKey.currentState?.fields['lastName']?.value;
                    _signUp(email, password, firstName, lastName);
                  }
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
