import 'package:flutter/material.dart';
import 'account_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_selection_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// Displays user settings and preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    // Access the current theme from the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.appBarTheme.backgroundColor,
        automaticallyImplyLeading: false, // Disable back button
        title: Text(
          'Settings',
          style: themeProvider.currentTheme.textTheme.titleLarge,
        ),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Settings Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAccountDetailsButton(context), // Button to navigate to account details
                _SectionHeader(title: 'Preferences'), // Section header for preferences
                _buildSettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'App Appearance',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    // Navigate to theme selection screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ThemeSelectionScreen()),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.storage_outlined,
                  title: 'Data Controls',
                ),
                _SectionHeader(title: 'About'),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'About BuildBot',
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.logout_outlined,
                  title: 'Sign out',
                  titleColor: Colors.red,
                  onTap: () async {
                    try {
                      // Sign out the user from Firebase
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return; // Check if the widget is still mounted
                      Navigator.of(context).pushReplacementNamed('/'); // Navigate to the home screen
                    } catch (e) {
                      if (!mounted) return; // Check if the widget is still mounted
                      // Show error message if sign out fails
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds a settings tile with an icon, title, and optional subtitle
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = Colors.black,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ListTile(
      leading: Icon(icon, color: themeProvider.currentTheme.primaryColor),
      title: Text(
        title,
        style: themeProvider.currentTheme.textTheme.bodyMedium,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            )
          : null,
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap, // Handle tap event
    );
  }

  // Builds the button to navigate to account details
  Widget _buildAccountDetailsButton(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return ListTile(
      leading: Icon(Icons.person_outline, color: themeProvider.currentTheme.primaryColor),
      title: Text(
        'Account Details',
        style: TextStyle(
          color: themeProvider.currentTheme.textTheme.bodyMedium?.color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        // Navigate to account details screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AccountDetailsScreen()),
        );
      },
    );
  }
}

// SectionHeader: A widget to display section headers in the settings
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
} 