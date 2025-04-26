import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/theme_provider.dart';
import '../viewmodels/theme_selection_viewmodel.dart';
import '../widgets/styled_alert.dart';

/// Screen for selecting and applying app themes
class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get theme provider for styling
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return ChangeNotifierProvider(
      // Create view model with current theme
      create: (_) => ThemeSelectionViewModel(themeProvider.currentTheme),
      child: Consumer<ThemeSelectionViewModel>(
        builder: (context, viewModel, child) {
          // Get current app theme
          final currentTheme = themeProvider.currentTheme;
          
          return Scaffold(
            backgroundColor: currentTheme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: currentTheme.appBarTheme.backgroundColor,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: currentTheme.iconTheme.color),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Select Theme',
                style: currentTheme.textTheme.titleLarge,
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
                        // Preview section header
                        Text(
                          'Preview',
                          style: currentTheme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildPreviewArea(viewModel), // Build the preview area with selected theme
                        const SizedBox(height: 32),
                        // Theme selection header
                        Text(
                          'Choose a theme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: currentTheme.textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Light theme option
                        _buildThemeOption(
                          context,
                          title: 'Light Theme',
                          isSelected: viewModel.isThemeSelected(AppTheme.defaultTheme),
                          colors: AppTheme.defaultTheme,
                          currentTheme: currentTheme,
                          onTap: () {
                            viewModel.setSelectedTheme(AppTheme.defaultTheme);
                          },
                        ),
                        // Dark theme option
                        _buildThemeOption(
                          context,
                          title: 'Dark Theme',
                          isSelected: viewModel.isThemeSelected(AppTheme.darkTheme),
                          colors: AppTheme.darkTheme,
                          currentTheme: currentTheme,
                          onTap: () {
                            viewModel.setSelectedTheme(AppTheme.darkTheme);
                          },
                        ),
                        const SizedBox(height: 32),
                        // Save button to apply theme
                        ElevatedButton(
                          onPressed: () async {
                            // Save selected theme
                            await viewModel.saveSelectedTheme();
                            // Apply the theme
                            themeProvider.setTheme(viewModel.selectedTheme);
                            if (context.mounted) {
                              Navigator.pop(context);
                              StyledAlerts.showSnackBar(
                                context,
                                'Theme updated successfully',
                                type: AlertType.success,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentTheme.primaryColor,
                            foregroundColor: currentTheme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds a preview of the chat interface with selected theme
  Widget _buildPreviewArea(ThemeSelectionViewModel viewModel) {
    final isDarkTheme = viewModel.selectedTheme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkTheme ? Color(0xFF424242) : viewModel.selectedTheme.primaryColor,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // New chat button preview
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: viewModel.selectedTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: viewModel.selectedTheme.colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'New Chat',
                        style: TextStyle(
                          color: viewModel.selectedTheme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Mock chat conversation
          Container(
            height: 200,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // User message bubble
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? Color(0xFF424242) : viewModel.selectedTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Hello!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Bot response bubble
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
                // Message input field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkTheme ? Color(0xFF2D2D2D) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
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
                      // Send button
                      Container(
                        width: 40,
                        height: 40,
                        margin: EdgeInsets.only(left: 16),
                        decoration: BoxDecoration(
                          color: isDarkTheme ? Colors.white : viewModel.selectedTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
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

  /// Builds a selectable theme option card
  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required ThemeData colors,
    required ThemeData currentTheme,
    required VoidCallback onTap,
  }) {
    final isDarkTheme = currentTheme.brightness == Brightness.dark;
    
    return Card(
      // Background color based on selection state
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
            color: currentTheme.textTheme.bodyLarge?.color ?? (isDarkTheme ? Colors.white : Colors.black),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        // Theme color preview
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
        // Show checkmark if selected
        trailing: isSelected
            ? Icon(
                Icons.check_circle, 
                color: isDarkTheme ? Colors.white : colors.primaryColor,
              )
            : null,
        onTap: onTap, // Handle selection
      ),
    );
  }
} 