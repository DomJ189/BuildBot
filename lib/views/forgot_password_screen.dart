import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../providers/theme_provider.dart';

// ForgotPasswordScreen: Handles user password reset request
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>(); // Key to manage form state
  final _viewModel = ForgotPasswordViewModel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ForgotPasswordViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              title: Text('Forgot Password', 
                style: TextStyle(color: theme.appBarTheme.titleTextStyle?.color ?? theme.primaryTextTheme.titleLarge?.color),
              ),
              iconTheme: IconThemeData(color: theme.iconTheme.color),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    // You can add your logo here
                    SizedBox(height: 40),
                    Text(
                      'Reset Your Password',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Enter your email address below and we\'ll send you instructions to reset your password.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    FormBuilder(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
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
                          SizedBox(height: 32),
                          
                          // Send Reset Email Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: viewModel.isLoading 
                                ? null 
                                : () async {
                                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                                      final email = _formKey.currentState?.fields['email']?.value;
                                      
                                      final success = await viewModel.sendPasswordResetEmail(email);
                                      
                                      if (success && mounted) {
                                        // Show a more detailed message
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: isDarkTheme ? Color(0xFF1A1A1A) : theme.dialogBackgroundColor,
                                            title: Text(
                                              'Reset Email Sent',
                                              style: TextStyle(color: theme.textTheme.titleLarge?.color),
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'We\'ve sent an email to $email with instructions to reset your password.',
                                                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  'Please check your email and follow the link to reset your password.',
                                                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.pop(context); // Return to login screen
                                                },
                                                child: Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(viewModel.errorMessage ?? 'Failed to send reset email')),
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
                                    'Send Reset Link',
                                    style: TextStyle(fontSize: 16, color: theme.primaryTextTheme.labelLarge?.color),
                                  ),
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Error message display
                          if (viewModel.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                viewModel.errorMessage!,
                                style: TextStyle(color: theme.colorScheme.error),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          
                          // Back to Login Link
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Back to Login",
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
} 