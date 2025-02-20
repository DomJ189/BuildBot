import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'views/login_screen.dart'; // Import the Login Screen
import 'views/chat_interface.dart'; // Import the Chat Interface
import 'views/chat_history_screen.dart'; // Import the Chat History Screen
import 'views/settings_screen.dart'; 
import 'package:provider/provider.dart';
import 'services/chat_service.dart';
import 'providers/theme_provider.dart';

// Entry point of the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // initialise environment file
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
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

  // Get the index of the current route
  int getIndex(String? name) {
    switch (name) {
      case '/chat': return 0;
      case '/history': return 1;
      case '/settings': return 2;
      default: return 0; // Default route
    }
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


