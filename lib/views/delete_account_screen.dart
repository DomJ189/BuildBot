import 'package:flutter/material.dart';
import '../viewmodels/account_details_viewmodel.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'forgot_password_screen.dart'; // Import Forgot Password Screen
import '../widgets/styled_alert.dart';

// Screen for permanently deleting user accounts with password confirmation
class DeleteAccountScreen extends StatelessWidget {
  final AccountDetailsViewModel viewModel;
  
  const DeleteAccountScreen({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    // Access theme settings
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkTheme ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkTheme ? Colors.white : Colors.black,
            size: 30,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delete Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
      ),
      // Display delete account form
      body: _DeleteAccountForm(viewModel: viewModel),
    );
  }
}

// Form that handles account deletion process
class _DeleteAccountForm extends StatefulWidget {
  final AccountDetailsViewModel viewModel;
  
  const _DeleteAccountForm({
    required this.viewModel,
  });

  @override
  _DeleteAccountFormState createState() => _DeleteAccountFormState();
}

class _DeleteAccountFormState extends State<_DeleteAccountForm> {
  // Controller for password field
  final _passwordController = TextEditingController();
  // State variables for UI controls
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    // Clean up resources
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme settings
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning text about account deletion
            Text(
              'This action will permanently delete your account and all your chat history. To confirm, please enter your password:',
              style: TextStyle(
                fontSize: 16,
                color: isDarkTheme ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            
            // Password input field
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                filled: true,
                fillColor: isDarkTheme ? Color(0xFF424242) : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                // Password visibility toggle
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            
            // Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                  );
                },
                child: Text(
                  "Forgot password?",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Delete account button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : () async {
                  // Validate password is entered
                  if (_passwordController.text.isEmpty) {
                    StyledAlerts.showSnackBar(
                      context,
                      'Please enter your password',
                      type: AlertType.warning,
                    );
                    return;
                  }
                  
                  setState(() {
                    _isLoading = true;
                  });
                  
                  try {
                    // Show confirmation dialogue
                    final confirmed = await StyledAlerts.showConfirmationDialog(
                      context: context,
                      title: 'Confirm Account Deletion',
                      message: 'This action cannot be undone. All your data will be permanently deleted. Are you sure you want to continue?',
                      confirmText: 'Delete Account',
                      cancelText: 'Cancel',
                    );
                    
                    if (!confirmed) {
                      setState(() {
                        _isLoading = false;
                      });
                      return;
                    }
                    
                    // Authenticate user before deletion
                    await widget.viewModel.reauthenticateUser(_passwordController.text);
                    await widget.viewModel.deleteAccount();
                    
                    // Return to login page after deletion
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    StyledAlerts.showSnackBar(
                      context,
                      'Account deleted successfully',
                      type: AlertType.success,
                    );
                  } catch (e) {
                    setState(() {
                      _isLoading = false;
                    });
                    // Show a user-friendly error message
                    final errorMsg = _getReadableErrorMessage(e.toString());
                    StyledAlerts.showSnackBar(
                      context,
                      errorMsg,
                      type: AlertType.error,
                    );
                  }
                },
                child: _isLoading 
                    ? SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2
                        )
                      )
                    : Text('Delete Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Converts Firebase errors to user-friendly messages
  String _getReadableErrorMessage(String error) {
    if (error.contains('wrong-password')) {
      return 'Incorrect password, please check and try again';
    } else if (error.contains('requires-recent-login')) {
      return 'For security reasons, please log out and log in again before deleting your account';
    } else if (error.contains('network-request-failed')) {
      return 'Network error, please check your internet connection';
    } else {
      return 'Failed to delete account. Please try again later.';
    }
  }
} 