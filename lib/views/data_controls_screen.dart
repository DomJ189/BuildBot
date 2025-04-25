import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/styled_alert.dart';

class DataControlsScreen extends StatefulWidget {
  const DataControlsScreen({super.key});

  @override
  State<DataControlsScreen> createState() => _DataControlsScreenState();
}

class _DataControlsScreenState extends State<DataControlsScreen> {
  bool _saveHistory = true;
  String _autoDeletionPeriod = 'Never delete';
  // Track original values to check for changes
  String _originalAutoDeletionPeriod = 'Never delete';
  bool _originalSaveHistory = true;
  
  @override
  void initState() {
    super.initState();
    // Load saved preferences here
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    // Load saved preferences
    final saveHistory = await chatService.isChatSavingEnabled();
    final prefs = await SharedPreferences.getInstance();
    
    // Ensure the auto-deletion period is 'Never delete' by default
    String autoDeletionPeriod;
    if (!prefs.containsKey('auto_deletion_period')) {
      autoDeletionPeriod = 'Never delete';
      await prefs.setString('auto_deletion_period', autoDeletionPeriod);
    } else {
      autoDeletionPeriod = prefs.getString('auto_deletion_period') ?? 'Never delete';
    }
    
    setState(() {
      _saveHistory = saveHistory;
      _originalSaveHistory = saveHistory;
      _autoDeletionPeriod = autoDeletionPeriod;
      _originalAutoDeletionPeriod = autoDeletionPeriod;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
 
    
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
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
                    
                    // Chat History section
                    Text(
                      'Chat History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Save Chat History toggle
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
                                  value: _saveHistory,
                                  onChanged: (value) {
                                    setState(() {
                                      _saveHistory = value;
                                    });
                                    // No longer saving immediately - will be saved when user taps Save Settings
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
                    
                    // Auto-deletion Period section
                    Text(
                      'Auto-deletion Period',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Auto-deletion options
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
                            _buildRadioOption('Never delete', isDarkTheme),
                            _buildRadioOption('24 hours', isDarkTheme),
                            _buildRadioOption('15 days', isDarkTheme),
                            _buildRadioOption('30 days', isDarkTheme),
                            _buildRadioOption('60 days', isDarkTheme),
                            _buildRadioOption('90 days', isDarkTheme),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Add save button at the bottom
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
                  onPressed: () {
                    // Save the preferences
                    _savePreferences();
                    
                    // Show confirmation with the appropriate message
                    String message;
                    AlertType alertType = AlertType.success;
                    
                    if (_autoDeletionPeriod != _originalAutoDeletionPeriod || _saveHistory != _originalSaveHistory) {
                      if (_autoDeletionPeriod != _originalAutoDeletionPeriod) {
                        if (_autoDeletionPeriod == 'Never delete') {
                          message = 'Auto-deletion disabled. Chats will be kept indefinitely.';
                        } else {
                          message = 'Chats will be automatically deleted $_autoDeletionPeriod after creation';
                        }
                      } else {
                        message = 'Settings saved';
                      }
                      
                      StyledAlerts.showSnackBar(
                        context,
                        message,
                        type: alertType,
                      );
                    } else {
                      StyledAlerts.showSnackBar(
                        context,
                        'No changes made',
                        type: AlertType.info,
                      );
                    }
                    
                    // Navigate back
                    Navigator.pop(context);
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
  }
  
  Widget _buildRadioOption(String value, bool isDarkTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: _autoDeletionPeriod,
            onChanged: (newValue) {
              setState(() {
                _autoDeletionPeriod = newValue!;
              });
              // No longer saving immediately - will be saved when user taps Save Settings
            },
            activeColor: isDarkTheme ? Colors.white : Colors.blue,
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _savePreferences() async {
    // Implement actual saving logic
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    // Save settings to the chat service
    chatService.setChatSavingEnabled(_saveHistory);
    
    // Save auto-deletion period to shared preferences and update ChatService
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auto_deletion_period', _autoDeletionPeriod);
    
    // Trigger an immediate execution of auto-deletion with the new period
    chatService.setAutoDeletionPeriod(_autoDeletionPeriod);
    
    // Update original values to match current values
    _originalSaveHistory = _saveHistory;
    _originalAutoDeletionPeriod = _autoDeletionPeriod;
  }
} 