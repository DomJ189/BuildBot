import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// Allows users to edit their profile information
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>(); // Key to manage the form state
  late TextEditingController _firstNameController; // Controller for first name
  late TextEditingController _lastNameController; // Controller for last name
  final User? _user = FirebaseAuth.instance.currentUser; // Current user from Firebase 

  @override
  void initState() {
    super.initState();
    // Split display name into first and last names
    final names = _user?.displayName?.split(' ') ?? ['', ''];
    _firstNameController = TextEditingController(text: names[0]);
    _lastNameController = TextEditingController(
      text: names.length > 1 ? names.sublist(1).join(' ') : '',
    );
  }

  // Function to save changes to the profile
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        final fullName = '${_firstNameController.text} ${_lastNameController.text}';
        await _user?.updateDisplayName(fullName); // Update the user's display name
        Navigator.pop(context); // Go back to the previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        // Show error message if updating profile fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.currentTheme.iconTheme.color),
          onPressed: () => Navigator.pop(context), // Go back to the previous screen
        ),
        title: Text(
          'Edit Profile',
          style: themeProvider.currentTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Key to manage the form state
          child: Column(
            children: [
              // First Name Field
              TextFormField(
                controller: _firstNameController,
                style: TextStyle(
                  color: themeProvider.currentTheme.textTheme.bodyMedium?.color,
                ),
                cursorColor: themeProvider.currentTheme.primaryColor,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: TextStyle(color: themeProvider.currentTheme.primaryColor),
                  filled: true,
                  fillColor: themeProvider.currentTheme.brightness == Brightness.dark
                      ? Color(0xFF2D2D2D)
                      : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: themeProvider.currentTheme.primaryColor),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name'; // Validation message
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16), // Spacing between fields
              // Last Name Field
              TextFormField(
                controller: _lastNameController,
                style: TextStyle(
                  color: themeProvider.currentTheme.textTheme.bodyMedium?.color,
                ),
                cursorColor: themeProvider.currentTheme.primaryColor,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  labelStyle: TextStyle(color: themeProvider.currentTheme.primaryColor),
                  filled: true,
                  fillColor: themeProvider.currentTheme.brightness == Brightness.dark
                      ? Color(0xFF2D2D2D)
                      : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: themeProvider.currentTheme.primaryColor),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name'; // Validation message
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24), // Spacing between fields
              // Save Changes Button
              ElevatedButton(
                onPressed: _saveChanges, // Save changes to the profile
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.currentTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(
                    color: themeProvider.currentTheme.colorScheme.onPrimary,
                    fontSize: 16
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 