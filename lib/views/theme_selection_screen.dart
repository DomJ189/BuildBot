import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/theme_provider.dart';

// Allows users to select and apply themes
class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  late ThemeData _selectedTheme; // Variable to hold the selected theme

  @override
  void initState() {
    super.initState();
    // Initialize the selected theme from the provider
    _selectedTheme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
  }

  // Function to save the selected theme
  void _saveTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setTheme(_selectedTheme); // Update the theme in the provider
    Navigator.pop(context); // Go back to the previous screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.currentTheme.iconTheme.color),
          onPressed: () => Navigator.pop(context), // Go back to the previous screen
        ),
        title: Text(
          'Select Theme',
          style: themeProvider.currentTheme.textTheme.titleLarge,
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: themeProvider.currentTheme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildPreviewArea(themeProvider), // Build the preview area
                  const SizedBox(height: 32),
                  const Text(
                    'Choose a theme',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Theme Options
                  // Light Theme Option
                  _buildThemeOption(
                    context,
                    title: 'Light Theme',
                    isSelected: _selectedTheme == AppTheme.defaultTheme,
                    colors: AppTheme.defaultTheme,
                    onTap: () {
                      setState(() {
                        _selectedTheme = AppTheme.defaultTheme; // Update the selected theme
                      });
                    },
                  ),
                  // Dark Theme Option
                  _buildThemeOption(
                    context,
                    title: 'Dark Theme',
                    isSelected: _selectedTheme == AppTheme.darkTheme,
                    colors: AppTheme.darkTheme,
                    onTap: () {
                      setState(() {
                        _selectedTheme = AppTheme.darkTheme; // Update the selected theme
                      });
                    },
                  ),
                  // Professional Theme Option
                  _buildThemeOption(
                    context,
                    title: 'Professional Theme',
                    isSelected: _selectedTheme == AppTheme.professionalTheme,
                    colors: AppTheme.professionalTheme,
                    onTap: () {
                      setState(() {
                        _selectedTheme = AppTheme.professionalTheme; // Update the selected theme
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _saveTheme, // Save the selected theme
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.currentTheme.primaryColor,
                  foregroundColor: themeProvider.currentTheme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build the preview area for the selected theme
  Widget _buildPreviewArea(ThemeProvider themeProvider) {
    final isDarkTheme = _selectedTheme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkTheme ? Color(0xFF424242) : _selectedTheme.primaryColor,
          width: 2
        ),
      ),
      child: Column(
        children: [
          // Theme preview area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkTheme ? Colors.black : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Text(
                  'What can I help with?',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.add, 
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ],
            ),
          ),
          // Chat preview area
          Container(
            height: 200,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? Color(0xFF424242) : _selectedTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Hello!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? Color(0xFF1A1A1A) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'How can I assist you today?',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkTheme ? Color(0xFF2D2D2D) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Type a message...',
                          style: TextStyle(
                            color: isDarkTheme 
                                ? Colors.grey[400] 
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkTheme ? Colors.white : _selectedTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send,
                          size: 20,
                          color: isDarkTheme 
                              ? Color(0xFF2D2D2D) 
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the theme option card
  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required ThemeData colors,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    return Card(
      color: isDarkTheme 
          ? (isSelected ? Color(0xFF424242) : Color(0xFF2D2D2D))
          : (isSelected ? colors.primaryColor.withAlpha(26) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors == AppTheme.darkTheme 
                ? Color(0xFF1A1A1A)
                : colors.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle, 
                color: isDarkTheme ? Colors.white : colors.primaryColor,
              )
            : null,
        onTap: onTap, // Handle theme selection
      ),
    );
  }
} 