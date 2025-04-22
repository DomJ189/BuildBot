import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';
import '../providers/theme_provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/chat_history_viewmodel.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    return ChangeNotifierProvider(
      create: (_) => ChatHistoryViewModel(chatService: chatService),
      child: Consumer<ChatHistoryViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
              elevation: 0,
              title: Text(
                viewModel.isSelectionMode ? '${viewModel.selectedChats.length} selected' : 'Chat History',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.currentTheme.textTheme.titleLarge?.color,
                ),
              ),
              actions: _buildAppBarActions(context, viewModel, themeProvider),
            ),
            body: viewModel.isLoading
                ? Center(child: CircularProgressIndicator())
                : viewModel.filteredChats.isEmpty
                    ? _buildEmptyState(context, themeProvider)
                    : _buildChatList(context, viewModel, themeProvider),
          );
        },
      ),
    );
  }
  
  List<Widget> _buildAppBarActions(BuildContext context, ChatHistoryViewModel viewModel, ThemeProvider themeProvider) {
    if (viewModel.isSelectionMode) {
      return [
        // Select all button
        IconButton(
          icon: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: themeProvider.currentTheme.textTheme.bodyLarge?.color ?? Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: viewModel.areAllChatsSelected
                ? Icon(
                    Icons.check,
                    size: 18,
                    color: themeProvider.currentTheme.primaryColor,
                  )
                : SizedBox(width: 18, height: 18),
          ),
          onPressed: viewModel.toggleSelectAll,
        ),
        // Pin selected button
        IconButton(
          icon: Icon(Icons.push_pin_outlined),
          onPressed: viewModel.pinSelectedChats,
        ),
        // Delete selected button
        IconButton(
          icon: Icon(Icons.delete_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Delete Chats'),
                content: Text('Are you sure you want to delete ${viewModel.selectedChats.length} chats?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      viewModel.deleteSelectedChats();
                      Navigator.pop(context);
                    },
                    child: Text('Delete'),
                  ),
                ],
              ),
            );
          },
        ),
        // Cancel selection mode
        IconButton(
          icon: Icon(Icons.close),
          onPressed: viewModel.cancelSelectionMode,
        ),
      ];
    } else {
      // Return an empty list when not in selection mode
      return [];
    }
  }
  
  Widget _buildEmptyState(BuildContext context, ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: themeProvider.currentTheme.textTheme.bodyLarge?.color?.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No chat history yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.currentTheme.textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start a new chat to see it here',
            style: TextStyle(
              color: themeProvider.currentTheme.textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('New Chat', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              // Navigate to the chat screen
              Navigator.pushReplacementNamed(context, '/chat');
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatList(BuildContext context, ChatHistoryViewModel viewModel, ThemeProvider themeProvider) {
    // Sort chats: pinned first, then by date
    final sortedChats = List<Chat>.from(viewModel.filteredChats)
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt); // Newest first
      });
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: sortedChats.length,
      itemBuilder: (context, index) {
        return _buildChatItem(context, viewModel, index, sortedChats[index]);
      },
    );
  }
  
  Widget _buildChatItem(BuildContext context, ChatHistoryViewModel viewModel, int index, Chat chat) {
    final isSelected = viewModel.selectedChats.contains(chat.id);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(chat.createdAt);
    
    // Wrap with Dismissible only if not pinned
    Widget chatCard = Card(
      color: isDarkTheme ? Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: isSelected
          ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDarkTheme ? Color(0xFF555555) : Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            )
          : CircleAvatar(
              radius: 12,
              backgroundColor: Colors.transparent,
              child: Icon(
                Icons.chat_bubble_outline,
                color: isDarkTheme ? Colors.white70 : Colors.blue,
                size: 20,
              ),
            ),
        title: Text(
          chat.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          formattedDate,
          style: TextStyle(
            color: isDarkTheme ? Colors.white70 : Colors.black54,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            color: chat.isPinned
                ? themeProvider.currentTheme.primaryColor
                : isDarkTheme 
                    ? Colors.white70 
                    : Colors.black54,
          ),
          onPressed: () {
            viewModel.togglePinChat(chat);
          },
        ),
        onTap: () {
          if (viewModel.isSelectionMode) {
            viewModel.toggleChatSelection(chat.id);
          } else {
            viewModel.selectChat(chat);
            Navigator.pushReplacementNamed(context, '/chat');
          }
        },
        onLongPress: () {
          if (!viewModel.isSelectionMode) {
            viewModel.startSelectionMode();
            viewModel.toggleChatSelection(chat.id);
          }
        },
      ),
    );
    
    // Only allow dismissible if not pinned
    if (!chat.isPinned) {
      return Dismissible(
        key: Key(chat.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20),
          margin: EdgeInsets.only(bottom: 12),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        onDismissed: (direction) {
          viewModel.deleteChat(chat.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  viewModel.undoDelete();
                },
              ),
            ),
          );
        },
        child: chatCard,
      );
    } else {
      // Return the card directly if pinned
      return chatCard;
    }
  }
}

// Search delegate for chat history
class ChatSearchDelegate extends SearchDelegate {
  final ChatHistoryViewModel viewModel;
  
  ChatSearchDelegate(this.viewModel);
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    viewModel.setSearchQuery(query);
    return _buildSearchResults(context);
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    viewModel.setSearchQuery(query);
    return _buildSearchResults(context);
  }
  
  Widget _buildSearchResults(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    if (viewModel.filteredChats.isEmpty) {
      return Center(
        child: Text(
          'No chats found',
          style: TextStyle(
            color: themeProvider.currentTheme.textTheme.bodyLarge?.color,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: viewModel.filteredChats.length,
      itemBuilder: (context, index) {
        final chat = viewModel.filteredChats[index];
        final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
        final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(chat.createdAt);
        
        return ListTile(
          title: Text(
            chat.title,
            style: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            formattedDate,
            style: TextStyle(
              color: isDarkTheme ? Colors.white70 : Colors.black54,
            ),
          ),
          onTap: () {
            viewModel.selectChat(chat);
            close(context, null);
            Navigator.pushReplacementNamed(context, '/chat');
          },
        );
      },
    );
  }
} 