import 'package:flutter/material.dart';
import '../viewmodels/account_details_viewmodel.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'forgot_password_screen.dart'; // Import Forgot Password Screen

class ChangePasswordScreen extends StatelessWidget {
  final AccountDetailsViewModel viewModel;
  
  const ChangePasswordScreen({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
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
          'Change Password',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: _ChangePasswordForm(viewModel: viewModel),
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  final AccountDetailsViewModel viewModel;
  
  const _ChangePasswordForm({
    required this.viewModel,
  });

  @override
  _ChangePasswordFormState createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your current password and a new password:',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white70 : Colors.black87,
                  height: 1.5,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_isCurrentPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  filled: true,
                  fillColor: isDarkTheme ? Color(0xFF424242) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCurrentPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              // Forgot Password Link
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
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_isNewPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  filled: true,
                  fillColor: isDarkTheme ? Color(0xFF424242) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  filled: true,
                  fillColor: isDarkTheme ? Color(0xFF424242) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkTheme ? Colors.white : Colors.blue,
                    foregroundColor: isDarkTheme ? Color(0xFF333333) : Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() {
                        _isLoading = true;
                      });
                      
                      try {
                        await widget.viewModel.updatePassword(
                          _currentPasswordController.text,
                          _newPasswordController.text,
                        );
                        Navigator.pop(context, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Password updated successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating password: $e')),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    }
                  },
                  child: _isLoading 
                      ? SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(
                            color: isDarkTheme ? Color(0xFF333333) : Colors.white,
                            strokeWidth: 2
                          )
                        )
                      : Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 