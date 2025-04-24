import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'views/login_screen.dart'; // Import the Login Screen
import 'views/chat_interface.dart'; // Import the Chat Interface
import 'views/chat_history_screen.dart'; // Import the Chat History Screen
import 'views/settings_screen.dart'; 
import 'package:provider/provider.dart';
import 'services/chat_service.dart';
import 'services/bot_service.dart';
import 'providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'viewmodels/account_details_viewmodel.dart';
import 'services/data_retention_service.dart'; // Import DataRetentionService
import 'package:shared_preferences/shared_preferences.dart';

// Entry point of the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load environment variables
  await Firebase.initializeApp(); // Initialize Firebase
  
  // Get API credentials from environment variables
  final redditClientId = dotenv.env['REDDIT_CLIENT_ID'] ?? '';
  final redditClientSecret = dotenv.env['REDDIT_CLIENT_SECRET'] ?? '';
  final perplexityApiKey = dotenv.env['PERPLEXITY_API_KEY'] ?? '';
  
  // Initialize services
  final chatService = ChatService();
  final botService = BotService(
    perplexityApiKey,
    redditClientId: redditClientId,
    redditClientSecret: redditClientSecret,
  );
  final dataRetentionService = DataRetentionService(); // Create DataRetentionService
  
  await chatService.loadTypingSpeedPreference();
  
  // Initialize auto-deletion
  chatService.initializeAutoDeletion();
  
  // Also apply data retention policy once at startup
  dataRetentionService.applyDataRetentionPolicy();
  
  // Listen for auth state changes
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      // User is signed in
      final viewModel = AccountDetailsViewModel();
      await viewModel.checkAndMigrateUserData();
      
      // Set default auto-deletion to "Never delete" for all users
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auto_deletion_period', 'Never delete');
      print('Set auto-deletion period to "Never delete"');
      
      // Initialize chat history for the logged-in user
      await chatService.initializeChatHistory();
      
      // Apply data retention policy when user logs in
      dataRetentionService.applyDataRetentionPolicy();
      
      // Explicitly run auto-deletion for any chats older than the setting
      chatService.runAutoDeletionCheck();
      
      print('User logged in: ${user.email}');
      print('Chat history initialized and auto-deletion checks running');
    }
  });
  
  runApp(
    MultiProvider(
      providers: [
        Provider<ChatService>(create: (_) => chatService),
        Provider<BotService>(create: (_) => botService),
        Provider<DataRetentionService>(create: (_) => dataRetentionService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'BuildBot',
            theme: Provider.of<ThemeProvider>(context).currentTheme,
            initialRoute: '/',
            routes: {
              '/': (context) => LoginScreen(),
              '/main': (context) => MainWrapper(),
            },
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => MainWrapper(currentIndex: getIndex(settings.name)),
              );
            },
          );
        },
      ),
    ),
  );
}

// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ChatService>(create: (_) => ChatService()), //Provider for the chat service
        ChangeNotifierProvider(create: (_) => ThemeProvider()), //Provider for the theme provider
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'BuildBot',
            theme: Provider.of<ThemeProvider>(context).currentTheme, // Set the theme for the app
            initialRoute: '/', // Initial route for the app
            routes: {
              '/': (context) => LoginScreen(), // Login Screen
              '/main': (context) => MainWrapper(), // Main Wrapper
            },
            onGenerateRoute: (settings) {
              // Handle all other routes
              return MaterialPageRoute(
                builder: (context) => MainWrapper(currentIndex: getIndex(settings.name)),
              );
            },
          );
        },
      ),
    );
  }
}

// Create a new MainWrapper widget
class MainWrapper extends StatefulWidget {
  final int currentIndex;

  const MainWrapper({super.key, this.currentIndex = 0});

  @override
  _MainWrapperState createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    ChatInterface(),
    ChatHistoryScreen(),
    SettingsScreen() // Replace Placeholder with SettingsScreen
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// Add this function to determine the index based on route name
int getIndex(String? routeName) {
  switch (routeName) {
    case '/chat':
      return 0;
    case '/history':
      return 1;
    case '/settings':
      return 2;
    default:
      return 0; // Default to chat tab
  }
}


