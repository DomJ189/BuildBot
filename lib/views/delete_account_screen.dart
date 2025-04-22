import 'package:flutter/material.dart';
import '../viewmodels/account_details_viewmodel.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'forgot_password_screen.dart'; // Import Forgot Password Screen

class DeleteAccountScreen extends StatelessWidget {
  final AccountDetailsViewModel viewModel;
  
  const DeleteAccountScreen({
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
          'Delete Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: _DeleteAccountForm(viewModel: viewModel),
    );
  }
}

class _DeleteAccountForm extends StatefulWidget {
  final AccountDetailsViewModel viewModel;
  
  const _DeleteAccountForm({
    required this.viewModel,
  });

  @override
  _DeleteAccountFormState createState() => _DeleteAccountFormState();
}

class _DeleteAccountFormState extends State<_DeleteAccountForm> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action will permanently delete your account and all your chat history. To confirm, please enter your password:',
              style: TextStyle(
                fontSize: 16,
                color: isDarkTheme ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 24),
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
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),
            SizedBox(height: 16),
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
                  if (_passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter your password')),
                    );
                    return;
                  }
                  
                  setState(() {
                    _isLoading = true;
                  });
                  
                  try {
                    // Re-authenticate user before deleting
                    await widget.viewModel.reauthenticateUser(_passwordController.text);
                    await widget.viewModel.deleteAccount();
                    
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Account deleted successfully')),
                    );
                  } catch (e) {
                    setState(() {
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
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
} 