import 'package:flutter/material.dart';
import '../viewmodels/account_details_viewmodel.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'forgot_password_screen.dart';
import '../widgets/styled_alert.dart';

class ChangeEmailScreen extends StatelessWidget {
  final AccountDetailsViewModel viewModel;
  
  const ChangeEmailScreen({
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
          'Change Email',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: _ChangeEmailForm(viewModel: viewModel),
    );
  }
}

class _ChangeEmailForm extends StatefulWidget {
  final AccountDetailsViewModel viewModel;
  
  const _ChangeEmailForm({
    required this.viewModel,
  });

  @override
  _ChangeEmailFormState createState() => _ChangeEmailFormState();
}

class _ChangeEmailFormState extends State<_ChangeEmailForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your new email address and your current password:',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white70 : Colors.black87,
                  height: 1.5,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'New Email',
                  filled: true,
                  fillColor: isDarkTheme ? Color(0xFF424242) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
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
              SizedBox(height: 16),
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
                        await widget.viewModel.updateEmail(
                          _emailController.text,
                          _passwordController.text,
                        );
                        Navigator.pop(context, true);
                        StyledAlerts.showSnackBar(
                          context,
                          'Email updated successfully',
                          type: AlertType.success,
                        );
                      } catch (e) {
                        StyledAlerts.showSnackBar(
                          context,
                          e.toString(),
                          type: AlertType.error,
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
                      : Text('Update Email'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 