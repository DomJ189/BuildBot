import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../views/account_details_screen.dart';
import '../views/theme_selection_screen.dart';
import '../views/data_controls_screen.dart';
import '../views/about_buildbot_screen.dart';


/// App settings screen that provides access to user preferences,account management, and application information.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Forces UI to update when settings change
  void _refreshScreen() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          children: [
            // Settings header with title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.currentTheme.textTheme.titleLarge?.color,
                ),
              ),
            ),
            
            // Account management section
            _buildSettingItem(
              context,
              icon: Icons.person_outline,
              iconColor: Colors.blue,
              title: 'Account Details',
              showArrow: true,
              onTap: () {
                // Navigate to account details
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountDetailsScreen()),
                );
              },
            ),
            
            // Preferences section header
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
              child: Text(
                'Preferences',
                style: TextStyle(
                  fontSize: 18,
                  color: themeProvider.currentTheme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                ),
              ),
            ),
            
            // Theme selection option
            _buildSettingItem(
              context,
              icon: Icons.palette_outlined,
              iconColor: Colors.blue,
              title: 'App Appearance',
              showArrow: true,
              onTap: () {
                // Navigate to theme selection screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ThemeSelectionScreen()),
                );
              },
            ),
            
            // Bot Typing Speed
            _buildSettingItem(
              context,
              icon: Icons.speed,
              iconColor: Colors.blue,
              title: 'Bot Typing Speed',
              subtitle: _getTypingSpeedText(chatService.typingSpeed),
              showArrow: true,
              onTap: () {
                _showTypingSpeedDialog(context, chatService, _refreshScreen);
              },
            ),
            
            // Data retention and privacy controls
            _buildSettingItem(
              context,
              icon: Icons.storage_outlined,
              iconColor: Colors.blue,
              title: 'Data Controls',
              subtitle: 'Manage chat history retention',
              showArrow: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DataControlsScreen()),
                );
              },
            ),
            
            // About section header
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
              child: Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  color: themeProvider.currentTheme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                ),
              ),
            ),
            
            // About BuildBot
            _buildSettingItem(
              context,
              icon: Icons.info_outline,
              iconColor: Colors.blue,
              title: 'About BuildBot',
              showArrow: true,
              onTap: () {
                // Navigate to the About BuildBot screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutBuildBotScreen()),
                );
              },
            ),
            
            // Sign out
            _buildSettingItem(
              context,
              icon: Icons.logout,
              iconColor: Colors.red,
              title: 'Sign out',
              isSignOut: true,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Builds a consistent settings list item with optional icon, arrow, and subtitle
  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    bool showArrow = false,
    VoidCallback? onTap,
    bool isSignOut = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.currentTheme.brightness == Brightness.dark;
    
    // Keep original color for sign out, use white for others in dark mode
    final effectiveIconColor = isSignOut ? iconColor : (isDarkMode ? Colors.white : iconColor);
    
    return ListTile(
      leading: Icon(
        icon,
        color: effectiveIconColor,
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          // Keep red for sign out, use white/black for others
          color: isSignOut ? Colors.red : (isDarkMode ? Colors.white : Colors.black87),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: themeProvider.currentTheme.brightness == Brightness.dark ? Colors.white70 : Colors.black54,
              ),
            )
          : null,
      trailing: showArrow
          ? Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: themeProvider.currentTheme.brightness == Brightness.dark ? Colors.white54 : Colors.black54,
            )
          : null,
      onTap: onTap,
    );
  }
  
  /// Converts typing speed value to human-readable text
  String _getTypingSpeedText(double? speed) {
    if (speed == null) return 'Medium';
    
    if (speed <= 0.5) return 'Slow';
    if (speed >= 2.5) return 'Fast';
    return 'Medium';
  }
  
  /// Shows dialog to adjust bot typing animation speed
  void _showTypingSpeedDialog(BuildContext context, ChatService chatService, VoidCallback onSettingsChanged) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.currentTheme.brightness == Brightness.dark;
    
    double selectedSpeed = chatService.typingSpeed ?? 1.5;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? Color(0xFF333333) : Colors.white,
              title: Text(
                'Bot Typing Speed',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Adjust how fast the bot responses appear during typing animation.',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Slow',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Fast',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: selectedSpeed,
                    min: 0.5,
                    max: 2.5,
                    divisions: 2,
                    activeColor: isDarkMode ? Colors.white : Colors.blue,
                    inactiveColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    onChanged: (value) {
                      setState(() {
                        selectedSpeed = value;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    _getTypingSpeedText(selectedSpeed),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.white : Colors.blue,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  ),
                  child: Text('Save'),
                  onPressed: () async {
                    chatService.setTypingSpeed(selectedSpeed);
                    Navigator.of(context).pop();
                    onSettingsChanged();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
} 