import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataControlsScreen extends StatefulWidget {
  const DataControlsScreen({super.key});

  @override
  State<DataControlsScreen> createState() => _DataControlsScreenState();
}

class _DataControlsScreenState extends State<DataControlsScreen> {
  bool _saveHistory = true;
  String _autoDeletionPeriod = '30 days';
  
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
    final autoDeletionPeriod = prefs.getString('auto_deletion_period') ?? '30 days';
    
    setState(() {
      _saveHistory = saveHistory;
      _autoDeletionPeriod = autoDeletionPeriod;
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
                                    // TODO: Save this preference
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
                            _buildRadioOption('24 hours', isDarkTheme),
                            _buildRadioOption('15 days', isDarkTheme),
                            _buildRadioOption('30 days', isDarkTheme),
                            _buildRadioOption('60 days', isDarkTheme),
                            _buildRadioOption('90 days', isDarkTheme),
                            _buildRadioOption('Never delete', isDarkTheme),
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
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkTheme ? Colors.white : Colors.blue,
                foregroundColor: isDarkTheme ? Colors.black : Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // Save the preferences
                _savePreferences();
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Settings saved'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                
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
              // TODO: Save this preference
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
    chatService.setAutoDeletionPeriod(_autoDeletionPeriod);
  }
} 