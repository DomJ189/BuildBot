import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';
import '../providers/theme_provider.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              final chatService = Provider.of<ChatService>(context, listen: false);
              chatService.setCurrentChat(null);
              Navigator.pushReplacementNamed(context, '/chat');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Chat>>(
        stream: chatService.getChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error loading chats'));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final chat = snapshot.data![index];
              return Dismissible(
                key: Key(chat.id),
                background: Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  chatService.deleteChat(chat.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chat deleted')),
                  );
                },
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      color: isDarkTheme ? Color(0xFF424242) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        height: 100,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: ListTile(
                            title: Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                chat.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkTheme ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            subtitle: Text(
                              chat.createdAt.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            onTap: () {
                              final chatService = Provider.of<ChatService>(context, listen: false);
                              chatService.setCurrentChat(chat);
                              Navigator.pushReplacementNamed(context, '/chat');
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 