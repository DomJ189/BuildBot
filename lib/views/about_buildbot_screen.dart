import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutBuildBotScreen extends StatelessWidget {
  const AboutBuildBotScreen({super.key});

  // Launch URLs in the device's browser
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data from provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    return Scaffold(
      // Main screen with themed background
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        // App bar with back button
        backgroundColor: themeProvider.currentTheme.appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.currentTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About BuildBot',
          style: themeProvider.currentTheme.textTheme.titleLarge,
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        // Scrollable content with padding
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Version section
            Center(
              child: Column(
                children: [
                  Container(
                    // Circular container for app logo
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/BuildBotLogo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    // App name text
                    'BuildBot',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.currentTheme.textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(
                    // App version text
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            
            // App Description section
            _buildSectionTitle('About', themeProvider),
            SizedBox(height: 8),
            _buildParagraph(
              // First paragraph of app description
              'BuildBot is your personal PC building assistant, designed to help you with all aspects of computer building, maintenance, and troubleshooting.',
              themeProvider,
            ),
            SizedBox(height: 8),
            _buildParagraph(
              // Second paragraph of app description
              'Whether you\'re a beginner looking to build your first PC or an experienced builder seeking advice on component compatibility, BuildBot provides expert guidance in an easy-to-understand format.',
              themeProvider,
            ),
            SizedBox(height: 24),
            
            // Features section
            _buildSectionTitle('Key Features', themeProvider),
            SizedBox(height: 8),
            _buildFeatureItem('Component selection advice', themeProvider),
            _buildFeatureItem('Compatibility checking', themeProvider),
            _buildFeatureItem('Troubleshooting assistance', themeProvider),
            _buildFeatureItem('Performance optimisation tips', themeProvider),
            _buildFeatureItem('Budget-friendly recommendations', themeProvider),
            SizedBox(height: 24),
            
            // Technologies section
            _buildSectionTitle('Powered By', themeProvider),
            SizedBox(height: 8),
            _buildParagraph(
              // List of technologies used in the app
              'BuildBot leverages cutting-edge technologies including:\n'
              '• Perplexity AI - For intelligent, context-aware responses\n'
              '• Firebase - For secure cloud storage and user authentication\n'
              '• Flutter - For a beautiful cross-platform experience\n'
              '• Cloud Firestore - For real-time chat history synchronization',
              themeProvider,
            ),
            SizedBox(height: 24),
            
            // Contact & Support section
            _buildSectionTitle('Contact & Support', themeProvider),
            SizedBox(height: 8),
            InkWell(
              // Email support link with tap action
              onTap: () => _launchUrl('mailto:support@buildbot.com'),
              child: _buildContactItem(
                Icons.email_outlined,
                'Email Support',
                'support@buildbot.com',
                themeProvider,
              ),
            ),
            SizedBox(height: 24),
            
            // Legal information section
            _buildSectionTitle('Legal', themeProvider),
            SizedBox(height: 8),
            _buildTermsSection(themeProvider),
            SizedBox(height: 16),
            _buildPrivacySection(themeProvider),
            SizedBox(height: 24),
            
            // Copyright footer
            Center(
              child: Text(
                '© 2025 BuildBot. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Create a section title with consistent styling
  Widget _buildSectionTitle(String title, ThemeProvider themeProvider) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: themeProvider.currentTheme.textTheme.titleLarge?.color,
      ),
    );
  }

  // Create a paragraph with consistent styling
  Widget _buildParagraph(String text, ThemeProvider themeProvider) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: themeProvider.currentTheme.textTheme.bodyMedium?.color,
      ),
    );
  }

  // Create a feature list item with icon and text
  Widget _buildFeatureItem(String feature, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: themeProvider.currentTheme.primaryColor,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.currentTheme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Create a contact information item with icon and details
  Widget _buildContactItem(
    IconData icon,
    String title,
    String value,
    ThemeProvider themeProvider,
  ) {
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkTheme ? Color(0xFF2D2D2D) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: themeProvider.currentTheme.primaryColor,
            size: 24,
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.currentTheme.textTheme.titleMedium?.color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.currentTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Create the terms of service expandable section
  Widget _buildTermsSection(ThemeProvider themeProvider) {
    return ExpansionTile(
      title: Text(
        'Terms of Service',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeProvider.currentTheme.primaryColor,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTermItem(
                'Usage Agreement',
                'By using BuildBot, you agree to these terms and our privacy policy.',
                themeProvider,
              ),
              _buildTermItem(
                'User Content',
                'You retain ownership of your content. You grant us license to use your content to provide and improve our services.',
                themeProvider,
              ),
              _buildTermItem(
                'Service Changes',
                'We may modify or discontinue services at any time without liability.',
                themeProvider,
              ),
              _buildTermItem(
                'Acceptable Use',
                'You agree not to misuse our services or help anyone else do so.',
                themeProvider,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Create the privacy policy expandable section
  Widget _buildPrivacySection(ThemeProvider themeProvider) {
    return ExpansionTile(
      title: Text(
        'Privacy Policy',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeProvider.currentTheme.primaryColor,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTermItem(
                'Information Collection',
                'We collect information to provide better services to users.',
                themeProvider,
              ),
              _buildTermItem(
                'Information Usage',
                'We use collected information to provide, maintain, and improve our services.',
                themeProvider,
              ),
              _buildTermItem(
                'Information Sharing',
                'We do not share personal information with companies, organizations, or individuals outside of BuildBot except in limited circumstances.',
                themeProvider,
              ),
              _buildTermItem(
                'Information Security',
                'We work hard to protect our users from unauthorized access or unauthorized alteration, disclosure, or destruction of information.',
                themeProvider,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Create an individual term/policy item with title and description
  Widget _buildTermItem(String title, String content, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.currentTheme.textTheme.titleMedium?.color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.currentTheme.textTheme.bodyMedium?.color,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
} 