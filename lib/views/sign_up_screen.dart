import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../viewmodels/sign_up_viewmodel.dart';
import '../providers/theme_provider.dart';

// Handles user registration functionality
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormBuilderState>(); // Key to manage form state
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  
  // Add focus nodes to detect when fields are focused
  final FocusNode _passwordFocusNode = FocusNode();
  bool _showPasswordRequirements = false;

  @override
  void initState() {
    super.initState();
    // Listen for focus changes on password field
    _passwordFocusNode.addListener(() {
      setState(() {
        _showPasswordRequirements = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => SignUpViewModel(),
      child: Consumer<SignUpViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              title: Text('Sign Up', style: TextStyle(color: theme.appBarTheme.titleTextStyle?.color ?? theme.primaryTextTheme.titleLarge?.color)),
              iconTheme: IconThemeData(color: theme.iconTheme.color),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  // You can add your logo here
                  SizedBox(height: 30),
                  FormBuilder(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          'Sign Up',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        // First Name Field
                        _buildTextField(
                          context: context,
                          name: 'firstName',
                          label: 'First Name',
                          icon: Icons.person_outline,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.minLength(2),
                          ]),
                        ),
                        SizedBox(height: 16),
                        
                        // Last Name Field
                        _buildTextField(
                          context: context,
                          name: 'lastName',
                          label: 'Last Name',
                          icon: Icons.person_outline,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.minLength(2),
                          ]),
                        ),
                        SizedBox(height: 16),
                        
                        // Email Field
                        _buildTextField(
                          context: context,
                          name: 'email',
                          label: 'Email address',
                          icon: Icons.email_outlined,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.email(),
                          ]),
                        ),
                        SizedBox(height: 16),
                        
                        // Password Field
                        _buildTextField(
                          context: context,
                          name: 'password',
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          focusNode: _passwordFocusNode,
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
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.minLength(6),
                            FormBuilderValidators.match(
                              RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$'),
                              errorText: 'Must include: A-Z, a-z, 0-9, special character',
                            ),
                          ]),
                        ),
                        
                        // Show password requirements only when password field is focused
                        if (_showPasswordRequirements)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Password must contain:',
                                    style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                                Text('• At least 6 characters',
                                    style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                                Text('• At least one uppercase letter (A-Z)',
                                    style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                                Text('• At least one lowercase letter (a-z)',
                                    style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                                Text('• At least one number (0-9)',
                                    style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                                Text('• At least one special character',
                                    style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                              ],
                            ),
                          ),
                        SizedBox(height: 16),
                        
                        // Confirm Password Field
                        _buildTextField(
                          context: context,
                          name: 'confirmPassword',
                          label: 'Confirm password',
                          icon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: theme.iconTheme.color?.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (val) {
                            // Get the password value
                            final password = _formKey.currentState?.fields['password']?.value;
                            // Compare with confirm password value
                            if (val != password) {
                              return 'Passwords must match';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        
                        // Terms and Conditions Checkbox
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                activeColor: theme.colorScheme.primary,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _agreedToTerms = value ?? false;
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, height: 1.5),
                                  children: [
                                    TextSpan(text: 'By signing up, you agree to our '),
                                    TextSpan(
                                      text: 'Terms of Use',
                                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _showTermsAndPrivacyDialog(context, initialTab: 0);
                                        },
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _showTermsAndPrivacyDialog(context, initialTab: 1);
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                        
                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: viewModel.isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                                    if (!_agreedToTerms) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Please agree to the Terms and Privacy Policy')),
                                      );
                                      return;
                                    }
                                    final email = _formKey.currentState?.fields['email']?.value;
                                    final password = _formKey.currentState?.fields['password']?.value;
                                    final firstName = _formKey.currentState?.fields['firstName']?.value;
                                    final lastName = _formKey.currentState?.fields['lastName']?.value;
                                    
                                    final success = await viewModel.signUp(
                                      email, 
                                      password, 
                                      firstName, 
                                      lastName
                                    );
                                    
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Account created successfully!')),
                                      );
                                      Navigator.pushReplacementNamed(context, '/login');
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(viewModel.errorMessage ?? 'Registration failed')),
                                      );
                                    }
                                  }
                                },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: viewModel.isLoading
                              ? CircularProgressIndicator(color: isDarkTheme ? Colors.white : Colors.black)
                              : Text(
                                  'Sign up',
                                  style: TextStyle(fontSize: 16, color: theme.colorScheme.onPrimary),
                                ),
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        // Contact and Login Links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text('Contact us', style: TextStyle(color: theme.colorScheme.secondary)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Log in', style: TextStyle(color: theme.colorScheme.primary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to build styled text fields
  Widget _buildTextField({
    required BuildContext context,
    required String name,
    required String label,
    required IconData icon,
    bool obscureText = false,
    FocusNode? focusNode,
    Widget? suffixIcon,
    required dynamic validator,
  }) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;

    return FormBuilderTextField(
      name: name,
      focusNode: focusNode,
      obscureText: obscureText,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.inputDecorationTheme.labelStyle?.color ?? theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: theme.iconTheme.color?.withOpacity(0.7)),
        suffixIcon: suffixIcon,
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
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
      validator: validator,
    );
  }

  void _showTermsAndPrivacyDialog(BuildContext context, {required int initialTab}) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DefaultTabController(
          length: 2,
          initialIndex: initialTab,
          child: Dialog(
            backgroundColor: theme.dialogBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: theme.appBarTheme.backgroundColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.close, color: theme.iconTheme.color),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              'Legal Information',
                              style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 48), // Balance the close button
                          ],
                        ),
                        TabBar(
                          tabs: [
                            Tab(text: 'Terms of Use'),
                            Tab(text: 'Privacy Policy'),
                          ],
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          indicatorColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Terms of Use Content
                        SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            _getTermsOfUseText(),
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                          ),
                        ),
                        // Privacy Policy Content
                        SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            _getPrivacyPolicyText(),
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
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
    );
  }

  String _getTermsOfUseText() {
    // Replace with the actual terms of use from your About Us section
    return """
Terms of Use for BuildBot

Last Updated: ${DateTime.now().toString().split(' ')[0]}

1. Acceptance of Terms
By accessing or using BuildBot, you agree to be bound by these Terms of Use.

2. Description of Service
BuildBot is a PC building assistant application that provides guidance and information related to computer hardware and configurations.

3. User Accounts
You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.

4. User Conduct
You agree not to use the service for any illegal or unauthorized purpose.

5. Intellectual Property
All content, features, and functionality of BuildBot are owned by us and are protected by copyright, trademark, and other intellectual property laws.

6. Disclaimer of Warranties
The service is provided "as is" without warranties of any kind.

7. Limitation of Liability
We shall not be liable for any indirect, incidental, special, consequential, or punitive damages.

8. Changes to Terms
We reserve the right to modify these terms at any time.

9. Governing Law
These terms shall be governed by the laws of the jurisdiction in which we operate.

10. Contact Information
For questions about these Terms, please contact us through the app.
""";
  }

  String _getPrivacyPolicyText() {
    // Replace with the actual privacy policy from your About Us section
    return """
Privacy Policy for BuildBot

Last Updated: ${DateTime.now().toString().split(' ')[0]}

1. Information We Collect
We collect information you provide directly to us, such as your name, email address, and chat history.

2. How We Use Your Information
We use the information we collect to provide, maintain, and improve our services, and to communicate with you.

3. Information Sharing
We do not share your personal information with third parties except as described in this policy.

4. Data Security
We take reasonable measures to help protect your personal information from loss, theft, misuse, and unauthorized access.

5. Your Choices
You can access, update, or delete your account information at any time through the app settings.

6. Children's Privacy
Our service is not directed to children under 13, and we do not knowingly collect personal information from children under 13.

7. Changes to This Policy
We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.

8. Contact Us
If you have any questions about this Privacy Policy, please contact us through the app.
""";
  }
}
