import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../views/account_details_screen.dart';
import '../views/theme_selection_screen.dart';
import '../views/data_controls_screen.dart';
import '../views/about_buildbot_screen.dart';


// Displays user settings and preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Add this to force a rebuild when needed
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
            // Settings title
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
            
            // Account section
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
            
            // App Appearance
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
            
            // Data Controls
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
                // Navigate to the About BuildBot screen instead of showing a dialog
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

  String _getTypingSpeedText(double typingSpeed) {
    if (typingSpeed < 1.0) {
      return 'Slow';
    } else if (typingSpeed > 2.0) {
      return 'Fast';
    } else {
      return 'Medium';
    }
  }

  void _showTypingSpeedDialog(
    BuildContext context, 
    ChatService chatService,
    VoidCallback onRefresh
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.currentTheme.brightness == Brightness.dark;
    
    // Store the initially selected speed to restore if canceled
    final initialSpeed = _getTypingSpeedText(chatService.typingSpeed);
    // Create a temporary variable to track the selected speed
    String selectedSpeed = initialSpeed;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDarkMode ? Color(0xFF212121) : Colors.white,
          title: Text(
            'Set Bot Typing Speed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSpeedOptionWithState(context, 'Slow', selectedSpeed, (speed) {
                setState(() => selectedSpeed = speed);
              }, isDarkMode),
              _buildSpeedOptionWithState(context, 'Medium', selectedSpeed, (speed) {
                setState(() => selectedSpeed = speed);
              }, isDarkMode),
              _buildSpeedOptionWithState(context, 'Fast', selectedSpeed, (speed) {
                setState(() => selectedSpeed = speed);
              }, isDarkMode),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Restore original speed if canceled
                if (selectedSpeed != initialSpeed) {
                  chatService.setTypingSpeed(
                    initialSpeed == 'Slow' ? 0.5 : initialSpeed == 'Fast' ? 3.0 : 1.5
                  );
                }
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.white : Colors.blue,
                foregroundColor: isDarkMode ? Color(0xFF333333) : Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                // Apply the selected speed
                chatService.setTypingSpeed(
                  selectedSpeed == 'Slow' ? 0.5 : selectedSpeed == 'Fast' ? 3.0 : 1.5
                );
                Navigator.pop(context);
                onRefresh(); // Call the refresh callback
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedOptionWithState(
    BuildContext context, 
    String speed, 
    String selectedSpeed,
    Function(String) onSelect,
    bool isDarkMode
  ) {
    final isSelected = selectedSpeed == speed;
    
    return InkWell(
      onTap: () => onSelect(speed),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? Color(0xFF424242) : Colors.grey[300]) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          speed,
          style: TextStyle(
            fontSize: 18,
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
} 