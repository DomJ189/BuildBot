import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../viewmodels/account_details_viewmodel.dart';
import 'package:intl/intl.dart';
import 'edit_profile_screen.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import '../widgets/styled_alert.dart';

// Allows users to view and manage their account details
class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AccountDetailsViewModel(),
      child: _AccountDetailsView(),
    );
  }
}

class _AccountDetailsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final viewModel = Provider.of<AccountDetailsViewModel>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    final displayName = viewModel.displayName;
    final email = viewModel.email;
    final creationDate = viewModel.creationDate;
    final formattedDate = DateFormat('MMM d, yyyy').format(creationDate);
    final initial = viewModel.initial;
    
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
          'Account Details',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkTheme ? Color(0xFF121212) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Profile picture and name
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile picture with initial
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDarkTheme ? Color(0xFF555555) : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        // User name
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Edit Profile button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.edit, color: Colors.white),
                        label: Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                currentName: displayName,
                                viewModel: viewModel,
                              ),
                            ),
                          );
                          
                          if (result == true) {
                            StyledAlerts.showSnackBar(
                              context,
                              'Profile updated successfully',
                              type: AlertType.success,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkTheme ? Color(0xFF333333) : Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Email section
              Text(
                'Email',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkTheme ? Colors.white54 : Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.email, color: isDarkTheme ? Colors.white : Colors.blue, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkTheme ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeEmailScreen(viewModel: viewModel),
                      ),
                    ),
                    child: Text(
                      'Change',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Password section
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkTheme ? Colors.white54 : Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.lock, color: isDarkTheme ? Colors.white : Colors.blue, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '••••••••',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangePasswordScreen(viewModel: viewModel),
                      ),
                    ),
                    child: Text(
                      'Change',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Account Created section
              Text(
                'Account Created',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkTheme ? Colors.white54 : Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: isDarkTheme ? Colors.white : Colors.blue, size: 28),
                  SizedBox(width: 16),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 40),
              
              // Delete Account button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.delete_forever, color: Colors.white),
                  label: Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeleteAccountScreen(viewModel: viewModel),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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