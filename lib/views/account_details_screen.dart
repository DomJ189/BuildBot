import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'edit_profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// Allows users to view and manage their account details
class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Gets the current user
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.currentTheme.primaryColor),
          onPressed: () => Navigator.pop(context), // Goes back to the previous screen
        ),
        title: Text(
          'Account Details',
          style: themeProvider.currentTheme.textTheme.titleLarge,
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            _buildNameSection(context, user), // Builds the name section
            _buildDetailTile(
              icon: Icons.email_outlined,
              title: 'Email',
              value: user?.email ?? 'No email found', // Displays the user's email
              showButton: true,
              theme: themeProvider.currentTheme,
            ),
            _buildDetailTile(
              icon: Icons.lock_outline,
              title: 'Password',
              value: '••••••••', // Password is hidden
              showButton: true,
              theme: themeProvider.currentTheme,
            ),
            _buildDetailTile(
              icon: Icons.calendar_today,
              title: 'Account Created',
              value: user?.metadata.creationTime != null
                  ? DateFormat.yMMMd().format(user!.metadata.creationTime!) // Displays the account creation date
                  : 'Unknown date',
              showButton: false,
              theme: themeProvider.currentTheme,
            ),
          ],
        ),
      ),
    );
  }

  // Builds the name section
  Widget _buildNameSection(BuildContext context, User? user) {
    final names = user?.displayName?.split(' ') ?? ['', ''];
    final firstName = names.isNotEmpty ? names[0] : '';
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: themeProvider.currentTheme.colorScheme.secondary,
              child: Text(
                firstName.isNotEmpty ? firstName[0] : 'U', // Displays the first letter of the user's name
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      firstName,
                      style: TextStyle(
                        color: themeProvider.currentTheme.colorScheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (lastName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        lastName,
                        style: TextStyle(
                          color: themeProvider.currentTheme.colorScheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.currentTheme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Navigates to the edit profile screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Builds the detail tile for displaying account details
  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
    bool showButton = false,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      trailing: showButton
          ? TextButton(
              onPressed: () {
                // Add email/password change functionality here
              },
              child: Text(
                'Change',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
    );
  }
} 