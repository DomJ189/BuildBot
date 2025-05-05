import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'firebase_options.dart'; // Import the Firebase options
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

// Application entry point with async initialisation
void main() async {
  // Ensure Flutter bindings are initialised
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Initialise Firebase with error handling for duplicate initialisation
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print('Firebase already initialised');
    } else {
      rethrow;
    }
  }
  
  // Get API credentials from environment variables
  final redditClientId = dotenv.env['REDDIT_CLIENT_ID'] ?? '';
  final redditClientSecret = dotenv.env['REDDIT_CLIENT_SECRET'] ?? '';
  final perplexityApiKey = dotenv.env['PERPLEXITY_API_KEY'] ?? '';
  
  // Initialise application services
  final chatService = ChatService();
  final botService = BotService(
    perplexityApiKey,
    redditClientId: redditClientId,
    redditClientSecret: redditClientSecret,
  );
  final dataRetentionService = DataRetentionService(); // Create DataRetentionService
  
  // Load user preferences for typing speed
  await chatService.loadTypingSpeedPreference();
  
  // Initialise auto-deletion monitoring
   chatService.initialiseAutoDeletion();
  
  // Apply data retention policy on startup
  dataRetentionService.applyDataRetentionPolicy();
  
  // Monitor user authentication state
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      // Create view model for authenticated user
      final viewModel = AccountDetailsViewModel();
      await viewModel.checkAndMigrateUserData();
      
      // Set default auto-deletion period
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auto_deletion_period', 'Never delete');
      print('Set auto-deletion period to "Never delete"');
      
      // Initialise chat history for current user
      await chatService.initialiseChatHistory();
      
      // Apply data retention policy
      dataRetentionService.applyDataRetentionPolicy();
      
      // Run auto-deletion check for old chats
      chatService.runAutoDeletionCheck();
      
      print('User logged in: ${user.email}');
      print('Chat history initialised and auto-deletion checks running');
    }
  });
  
  // Run the application with providers for dependency injection
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

// Wrapper widget that contains main app screens and navigation
class MainWrapper extends StatefulWidget {
  final int currentIndex;

  const MainWrapper({super.key, this.currentIndex = 0});

  @override
  _MainWrapperState createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // List of main app screens
  final List<Widget> _screens = [
    ChatInterface(),
    ChatHistoryScreen(),
    SettingsScreen()
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display current screen based on navigation index
      body: _screens[_currentIndex],
      // Bottom navigation bar for app-wide navigation
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

// Helper to determine tab index from route name
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


