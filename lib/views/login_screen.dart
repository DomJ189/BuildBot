import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_viewmodel.dart';
import 'sign_up_screen.dart'; // Import Sign-Up Screen
import 'forgot_password_screen.dart'; // Import Forgot Password Screen
import '../providers/theme_provider.dart'; // Import Theme Provider
import '../widgets/styled_alert.dart';


/// User login screen with email/password authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>(); // Form state key
  bool _obscurePassword = true; // Password visibility toggle

  @override
  Widget build(BuildContext context) {
    // Get current theme and theme provider
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;

    return ChangeNotifierProvider(
      // Create LoginViewModel instance
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            // Main scaffold with app background
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              // App bar with title
              backgroundColor: theme.appBarTheme.backgroundColor,
              title: Text('Login', 
                style: TextStyle(color: theme.appBarTheme.titleTextStyle?.color ?? theme.primaryTextTheme.titleLarge?.color),
              ),
            ),
            body: SingleChildScrollView(
              // Scrollable content to handle smaller screens
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    // App logo in a circular container
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.cardColor,
                      ),
                      padding: EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/images/BuildBotLogo.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
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
                            decoration: InputDecoration(  //Styling
                              // Email field styling
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
                              // Email validation rules
                              FormBuilderValidators.required(),
                              FormBuilderValidators.email(),
                            ]),
                          ),
                          SizedBox(height: 16),
                          
                          // Password input field with visibility toggle
                          FormBuilderTextField(
                            name: 'password',
                            obscureText: _obscurePassword,
                            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                            decoration: InputDecoration(
                              // Password field styling
                              labelText: 'Password',
                              labelStyle: TextStyle(color: theme.inputDecorationTheme.labelStyle?.color ?? theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.lock_outline, color: theme.iconTheme.color?.withOpacity(0.7)),
                              suffixIcon: IconButton(
                                // Toggle password visibility button
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
                          // Forgot password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              // Navigate to password recovery screen
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
                          
                          // Login button with loading indicator
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              // Handle login process with form validation
                              onPressed: viewModel.isLoading 
                                ? null 
                                : () async {
                                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                                      final email = _formKey.currentState?.fields['email']?.value;
                                      final password = _formKey.currentState?.fields['password']?.value;
                                      
                                      final success = await viewModel.login(email, password);
                                      
                                      if (success && mounted) {
                                        // Show success message and navigate to main screen
                                        StyledAlerts.showSnackBar(
                                          context, 
                                          'Logged in successfully!',
                                          type: AlertType.success,
                                        );
                                        Navigator.pushReplacementNamed(context, '/main');
                                      } else if (mounted) {
                                        // Show user-friendly error message
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
                                // Button styling
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
                          
                          // Sign up link for new users
                          TextButton(
                            onPressed: () {
                              // Navigate to sign up screen
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

  // Convert Firebase error codes to user-friendly messages
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
