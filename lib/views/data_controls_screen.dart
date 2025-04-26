import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../viewmodels/data_controls_viewmodel.dart';
import '../widgets/styled_alert.dart';

// Screen for managing data retention settings
class DataControlsScreen extends StatefulWidget {
  const DataControlsScreen({super.key});

  @override
  State<DataControlsScreen> createState() => _DataControlsScreenState();
}

class _DataControlsScreenState extends State<DataControlsScreen> {
  // Track if any settings changed for UI feedback
  bool get hasChanges => _viewModel != null && 
      (_originalSaveChatHistory != _viewModel!.saveChatHistory ||
       _originalDeletionPeriod != _viewModel!.deletionPeriod);
  
  // Original values for comparison
  bool _originalSaveChatHistory = true;
  String _originalDeletionPeriod = '30';
  
  // ViewModel reference
  DataControlsViewModel? _viewModel;
  
  // Flag to track if original values have been set
  bool _hasSetOriginalValues = false;
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    return ChangeNotifierProvider(
      create: (_) => DataControlsViewModel(),
      child: Consumer<DataControlsViewModel>(
        builder: (context, viewModel, child) {
          // Store reference to viewModel for hasChanges calculation
          _viewModel = viewModel;
          
          // Update reference values only once when data is first loaded
          if (!viewModel.isLoading && !_hasSetOriginalValues) {
            _originalSaveChatHistory = viewModel.saveChatHistory;
            _originalDeletionPeriod = viewModel.deletionPeriod;
            _hasSetOriginalValues = true;
            
            // Debug values
            print('Original values set - Save history: $_originalSaveChatHistory, Deletion period: $_originalDeletionPeriod');
          }
          
          // Debug current values vs original
          if (!viewModel.isLoading) {
            print('Current values - Save history: ${viewModel.saveChatHistory}, Deletion period: ${viewModel.deletionPeriod}');
            print('Has changes: $hasChanges');
          }
          
          return Scaffold(
            backgroundColor: isDarkTheme ? Colors.black : Colors.white,
            appBar: AppBar(
              backgroundColor: isDarkTheme ? Colors.black : Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDarkTheme ? Colors.white : Colors.blue,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Data Controls',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
            ),
            body: viewModel.isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Information banner
                            Container(
                              decoration: BoxDecoration(
                                color: isDarkTheme ? Color(0xFF1E1E1E) : Color(0xFFE6F4FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: isDarkTheme ? Colors.white : Colors.blue,
                                    size: 32,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Control how your chat data is stored and managed.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: isDarkTheme ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: 32),
                            
                            // Chat history section header
                            Text(
                              'Chat History',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkTheme ? Colors.white : Colors.black,
                              ),
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Save chat history toggle section
                            Card(
                              color: isDarkTheme ? Color(0xFF1E1E1E) : Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Save Chat History',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkTheme ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'When turned off, chats will not be saved after you close them',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkTheme ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Switch(
                                          value: viewModel.saveChatHistory,
                                          onChanged: (value) {
                                            viewModel.setSaveChatHistory(value);
                                          },
                                          activeColor: isDarkTheme ? Colors.white : Colors.blue,
                                          activeTrackColor: isDarkTheme ? Colors.white.withOpacity(0.5) : Colors.blue.withOpacity(0.5),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            SizedBox(height: 32),
                            
                            // Auto-deletion section header
                            Text(
                              'Auto-deletion Period',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkTheme ? Colors.white : Colors.black,
                              ),
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Auto-deletion options card
                            Card(
                              color: isDarkTheme ? Color(0xFF1E1E1E) : Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Automatically delete chats after:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: isDarkTheme ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    _buildRadioOption('Never', isDarkTheme, viewModel),
                                    _buildRadioOption('1', isDarkTheme, viewModel),
                                    _buildRadioOption('15', isDarkTheme, viewModel),
                                    _buildRadioOption('30', isDarkTheme, viewModel),
                                    _buildRadioOption('60', isDarkTheme, viewModel),
                                    _buildRadioOption('90', isDarkTheme, viewModel),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Save settings button
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkTheme ? Colors.white : Colors.blue,
                            foregroundColor: isDarkTheme ? Colors.black : Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isDarkTheme ? 0 : 2,
                          ),
                          onPressed: () async {
                            // Save settings using view model
                            await viewModel.savePreferences();
                            
                            // Show confirmation message
                            String message;
                            AlertType alertType;
                            
                            if (hasChanges) {
                              if (viewModel.deletionPeriod != _originalDeletionPeriod) {
                                if (viewModel.deletionPeriod == 'Never') {
                                  message = 'Auto-deletion disabled. Chats will be kept indefinitely.';
                                } else {
                                  message = 'Chats will be automatically deleted after ${viewModel.deletionPeriod} days';
                                }
                                alertType = AlertType.success;
                              } else {
                                message = 'Settings saved';
                                alertType = AlertType.success;
                              }
                            } else {
                              message = 'No changes made';
                              alertType = AlertType.info;
                            }
                            
                            if (context.mounted) {
                              StyledAlerts.showSnackBar(
                                context,
                                message,
                                type: alertType,
                              );
                              
                              // Update original values after saving
                              _originalSaveChatHistory = viewModel.saveChatHistory;
                              _originalDeletionPeriod = viewModel.deletionPeriod;
                              
                              // Return to previous screen
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            'Save Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          );
        },
      ),
    );
  }
  
  // Build a radio option for time selection
  Widget _buildRadioOption(String value, bool isDarkTheme, DataControlsViewModel viewModel) {
    // Format display text with days for better readability
    String displayText = value == 'Never' 
      ? 'Never delete' 
      : value == '1' 
        ? '24 hours'
        : '$value days';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: viewModel.deletionPeriod,
            onChanged: (newValue) {
              if (newValue != null) {
                viewModel.setDeletionPeriod(newValue);
              }
            },
            activeColor: isDarkTheme ? Colors.white : Colors.blue,
          ),
          SizedBox(width: 8),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 18,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
} 