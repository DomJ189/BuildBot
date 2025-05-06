import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../viewmodels/account_details_viewmodel.dart';
import '../widgets/styled_alert.dart';

// Screen for editing user profile information
class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final AccountDetailsViewModel viewModel;
  
  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.viewModel,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialise controllers with current name parts
    final nameParts = widget.currentName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    firstNameController = TextEditingController(text: firstName);
    lastNameController = TextEditingController(text: lastName);
  }
  
  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: isDarkTheme ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkTheme ? Colors.white : Colors.blue,
            size: 30,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'First Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white70 : Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                // First name input field
                TextField(
                  controller: firstNameController,
                  style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkTheme ? Color(0xFF1E1E1E) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter your first name',
                    hintStyle: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                
                Text(
                  'Last Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white70 : Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                // Last name input field
                TextField(
                  controller: lastNameController,
                  style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkTheme ? Color(0xFF1E1E1E) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter your last name',
                    hintStyle: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ),
                SizedBox(height: 40),
                
                // Save changes button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final fullName = '${firstNameController.text} ${lastNameController.text}'.trim();
                      if (fullName.isNotEmpty) {
                        try {
                          await widget.viewModel.updateDisplayName(fullName);
                          // Show success message
                          StyledAlerts.showSnackBar(
                            context,
                            'Profile updated successfully',
                            type: AlertType.success,
                          );
                          Navigator.pop(context, true); // Return success
                        } catch (e) {
                          // Show error message
                          StyledAlerts.showSnackBar(
                            context,
                            'Error updating profile: ${_getReadableErrorMessage(e.toString())}',
                            type: AlertType.error,
                          );
                        }
                      } else {
                        // Show warning for empty name
                        StyledAlerts.showSnackBar(
                          context,
                          'Name cannot be empty',
                          type: AlertType.warning,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkTheme ? Colors.white : Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 20,
                        color: isDarkTheme ? Color(0xFF333333) : Colors.white,
                      ),
                    ),
                  ),
                ),
                // Extra space for keyboard
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Convert Firebase errors to user-friendly messages
  String _getReadableErrorMessage(String error) {
    if (error.contains('network-request-failed')) {
      return 'Network error, please check your internet connection';
    } else if (error.contains('requires-recent-login')) {
      return 'For security reasons, please log out and log in again before updating your profile';
    } else {
      return 'Failed to update profile. Please try again later.';
    }
  }
} 