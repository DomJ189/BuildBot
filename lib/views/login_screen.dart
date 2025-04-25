import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_viewmodel.dart';
import 'sign_up_screen.dart'; // Import Sign-Up Screen
import 'forgot_password_screen.dart'; // Import Forgot Password Screen
import '../providers/theme_provider.dart'; // Import Theme Provider
import '../widgets/styled_alert.dart';


/// User authentication screen that handles login to the application.Features email/password login with validation and navigation to related screens.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>(); // Key to manage form state
  bool _obscurePassword = true; // Controls password visibility toggle

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              title: Text('Login', 
                style: TextStyle(color: theme.appBarTheme.titleTextStyle?.color ?? theme.primaryTextTheme.titleLarge?.color),
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    // Logo placeholder
                    SizedBox(height: 40),
                    
                    // Form with email and password fields
                    FormBuilder(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email input field with validation
                          FormBuilderTextField(
                            name: 'email',
                            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                            decoration: InputDecoration(
                              labelText: 'Email address',
                              labelStyle: TextStyle(color: theme.inputDecorationTheme.labelStyle?.color ?? theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.email_outlined, color: theme.iconTheme.color?.withOpacity(0.7)),
                              filled: true,
                              fillColor: isDarkTheme ? Color(0xFF1A1A1A) : theme.inputDecorationTheme.fillColor ?? Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.email(),
                            ]),
                          ),
                          SizedBox(height: 16),
                          
                          // Password input field with toggle visibility
                          FormBuilderTextField(
                            name: 'password',
                            obscureText: _obscurePassword,
                            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: theme.inputDecorationTheme.labelStyle?.color ?? theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.lock_outline, color: theme.iconTheme.color?.withOpacity(0.7)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: theme.iconTheme.color?.withOpacity(0.7),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: isDarkTheme ? Color(0xFF1A1A1A) : theme.inputDecorationTheme.fillColor ?? Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                            validator: FormBuilderValidators.required(),
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
                                style: TextStyle(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Login button with loading state
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: viewModel.isLoading 
                                ? null 
                                : () async {
                                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                                      final email = _formKey.currentState?.fields['email']?.value;
                                      final password = _formKey.currentState?.fields['password']?.value;
                                      
                                      final success = await viewModel.login(email, password);
                                      
                                      if (success && mounted) {
                                        StyledAlerts.showSnackBar(
                                          context, 
                                          'Logged in successfully!',
                                          type: AlertType.success,
                                        );
                                        Navigator.pushReplacementNamed(context, '/main');
                                      } else if (mounted) {
                                        final errorMsg = _getReadableErrorMessage(viewModel.errorMessage ?? 'Login failed');
                                        StyledAlerts.showSnackBar(
                                          context, 
                                          errorMsg,
                                          type: AlertType.error,
                                        );
                                      }
                                    }
                                  },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: viewModel.isLoading
                                ? CircularProgressIndicator(color: isDarkTheme ? Colors.white : Colors.black)
                                : Text(
                                    'Log in',
                                    style: TextStyle(fontSize: 16, color: theme.primaryTextTheme.labelLarge?.color),
                                  ),
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Sign Up Link
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SignUpScreen()),
                              );
                            },
                            child: Text(
                              "Don't have an account? Sign up",
                              style: TextStyle(color: theme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to convert Firebase errors to user-friendly messages
  String _getReadableErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email address';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password, please try again';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email format. Please check your email.';
    } else if (error.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    }
    return error;
  }
}
