import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/chat_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'dart:async';
import '../viewmodels/chat_interface_viewmodel.dart';
import '../widgets/youtube_video_player.dart';
import '../services/youtube_service.dart';

class ChatInterface extends StatefulWidget {
  const ChatInterface({super.key});

  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatInterfaceViewModel _viewModel;
  
  // Add a new controller for editing messages
  final TextEditingController _editController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Add scroll listener to show/hide scroll to bottom button
    _scrollController.addListener(_scrollListener);
  }
  
  void _scrollListener() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    _viewModel.setScrollButtonVisibility(maxScroll - currentScroll > 200);
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose(); // Dispose of edit controller
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    return ChangeNotifierProvider(
      create: (_) => ChatInterfaceViewModel(chatService: chatService),
      child: Consumer<ChatInterfaceViewModel>(
        builder: (context, viewModel, child) {
          _viewModel = viewModel;
          
          return Scaffold(
            backgroundColor: isDarkTheme ? Colors.black : Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  // Empty state or messages
                  Expanded(
                    child: viewModel.messages.isEmpty
                        ? _buildEmptyState(context, themeProvider)
                        : Stack(
                            children: [
                              _buildChatMessages(context, viewModel, themeProvider),
                              
                              // New Chat floating button
                              Positioned(
                                top: 8,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: ElevatedButton.icon(
                                    icon: Icon(
                                      Icons.add, 
                                      color: isDarkTheme ? Color(0xFF333333) : Colors.white,
                                    ),
                                    label: Text(
                                      'New Chat', 
                                      style: TextStyle(
                                        color: isDarkTheme ? Color(0xFF333333) : Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDarkTheme ? Colors.white : Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      elevation: 4,
                                    ),
                                    onPressed: () {
                                      viewModel.clearChat();
                                    },
                                  ),
                                ),
                              ),
                              
                              // Scroll to bottom button
                              if (viewModel.isScrollToBottomButtonVisible)
                                Positioned(
                                  right: 16,
                                  bottom: 16,
                                  child: FloatingActionButton(
                                    mini: true,
                                    backgroundColor: Colors.white,
                                    elevation: 4,
                                    onPressed: _scrollToBottom,
                                    child: Icon(
                                      Icons.arrow_downward,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  
                  // Input area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkTheme ? Color(0xFF333333) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: TextField(
                                controller: _controller,
                                style: TextStyle(
                                  color: isDarkTheme ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: TextStyle(
                                    color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                minLines: 1,
                                maxLines: 5,
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    viewModel.sendMessage(value);
                                    _controller.clear();
                                    
                                    // Scroll to bottom after sending message
                                    Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
                                  }
                                },
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDarkTheme ? Colors.white : Colors.blue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_forward,
                                color: isDarkTheme ? Colors.black : Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                if (_controller.text.trim().isNotEmpty) {
                                  viewModel.sendMessage(_controller.text);
                                  _controller.clear();
                                  
                                  // Scroll to bottom after sending message
                                  Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
                                }
                              },
                              padding: EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context, ThemeProvider themeProvider) {
    return Column(
      children: [
        SizedBox(height: 60), // Add space at the top
        Text(
          'What can I help with?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: themeProvider.currentTheme.textTheme.titleLarge?.color,
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Ask me anything about PC building, hardware, or tech support.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.currentTheme.textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildChatMessages(BuildContext context, ChatInterfaceViewModel viewModel, ThemeProvider themeProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(left: 16, right: 16, top: 64, bottom: 8),
      itemCount: viewModel.messages.length + 1, // +1 for typing indicator
      itemBuilder: (context, index) {
        // Show typing indicator
        if (viewModel.isBotTyping && index == viewModel.messages.length) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBotMessage(
                viewModel.editingMessageIndex != null 
                    ? "Regenerating response..." 
                    : viewModel.currentTypingText,
                themeProvider,
                isTyping: true,
              ),
              // Show videos during typing if available
              if (viewModel.currentVideos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Video Suggestions:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...viewModel.currentVideos.map((video) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: YouTubeVideoPlayer(video: video),
                        )
                      ).toList(),
                    ],
                  ),
                ),
            ],
          );
        }
        
        // Show regular messages
        if (index < viewModel.messages.length) {
          final message = viewModel.messages[index];
          final isUser = message['sender'] == 'user';
          
          // Check if this message is being edited
          final isEditing = viewModel.editingMessageIndex == index;
          
          if (isUser) {
            return _buildUserMessage(
              message['message'] ?? '', 
              themeProvider, 
              edited: message['edited'] == true
            );
          } else {
            // For bot messages, check if there are videos
            final videosList = message['videos'] as List<dynamic>?;
            final hasVideos = videosList != null && videosList.isNotEmpty;
            
            // Check if this is likely a response to a conversational message
            final isConversational = _isLikelyConversationalResponse(message['message'] ?? '');
            
            // Check if the previous message was the one showing videos
            bool previousMessageHadVideos = false;
            if (index > 0) {
              final prevMessage = viewModel.messages[index - 1];
              final prevVideosList = prevMessage['videos'] as List<dynamic>?;
              previousMessageHadVideos = prevVideosList != null && prevVideosList.isNotEmpty;
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBotMessage(
                  message['message'] ?? '', 
                  themeProvider,
                  regenerated: message['regenerated'] == true
                ),
                // Show videos if available and not a conversational response after videos
                if (hasVideos && !(isConversational && previousMessageHadVideos))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Video Suggestions:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...videosList!.map((video) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: YouTubeVideoPlayer(video: video as YouTubeVideo),
                          )
                        ).toList(),
                      ],
                    ),
                  ),
              ],
            );
          }
        }
        
        return SizedBox.shrink();
      },
    );
  }
  
  Widget _buildUserMessage(String message, ThemeProvider themeProvider, {bool edited = false}) {
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    // Check if this message is being edited
    final isBeingEdited = _viewModel.messages.indexWhere(
      (m) => m['sender'] == 'user' && m['message'] == message
    ) == _viewModel.editingMessageIndex;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Edit button for user messages
              GestureDetector(
                onTap: () {
                  // Show edit dialog
                  _showEditDialog(message);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: isBeingEdited 
                        ? (isDarkTheme ? Colors.white : Colors.blue)
                        : (isDarkTheme ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkTheme ? Colors.white : Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                    border: isBeingEdited 
                        ? Border.all(
                            color: isDarkTheme ? Colors.blue : Colors.white,
                            width: 2.0,
                          )
                        : null,
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isDarkTheme ? Colors.black : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Show edited indicator if message was edited
          if (edited)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, right: 4.0),
              child: Text(
                'edited',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Add a method to show edit dialog
  void _showEditDialog(String message) {
    // Find the index of this message in the viewModel
    final index = _viewModel.messages.indexWhere(
      (m) => m['sender'] == 'user' && m['message'] == message
    );
    
    if (index == -1) return;
    
    // Start editing mode in the view model
    _viewModel.startEditingMessage(index);
    
    // Set up edit controller
    _editController.text = message;
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editing this message will regenerate the bot\'s response.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _editController,
                decoration: InputDecoration(
                  hintText: 'Edit your message...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Cancel editing
                _viewModel.cancelEditingMessage();
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update the message and regenerate response
                _viewModel.updateMessage(_editController.text);
                Navigator.of(context).pop();
                
                // Scroll to show updated response
                Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildBotMessage(String message, ThemeProvider themeProvider, {bool isTyping = false, bool regenerated = false}) {
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: regenerated ? 2 : 8, right: 64),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeProvider.currentTheme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: message,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: themeProvider.currentTheme.textTheme.bodyLarge?.color,
                    ),
                    h1: TextStyle(
                      color: themeProvider.currentTheme.textTheme.titleLarge?.color,
                    ),
                    h2: TextStyle(
                      color: themeProvider.currentTheme.textTheme.titleMedium?.color,
                    ),
                    code: TextStyle(
                      backgroundColor: themeProvider.currentTheme.brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[100],
                      color: Colors.blue,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: themeProvider.currentTheme.brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (isTyping)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(themeProvider, 0),
                        _buildTypingDot(themeProvider, 1),
                        _buildTypingDot(themeProvider, 2),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Show regenerated indicator if message was regenerated
          if (regenerated)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
              child: Text(
                'regenerated',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTypingDot(ThemeProvider themeProvider, int index) {
    return AnimatedBuilder(
      animation: AlwaysStoppedAnimation(0),
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          height: 8,
          width: 8,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
  
  // Helper to check if a message is likely conversational
  bool _isLikelyConversationalResponse(String message) {
    final conversationalPhrases = [
      'you\'re welcome', 'welcome', 'glad to help', 'happy to assist',
      'is there anything else', 'let me know if you have', 'feel free',
      'anything else you', 'anything i can help', 'any other questions',
      'goodbye', 'good day', 'take care', 'have a great'
    ];
    
    final lowerMessage = message.toLowerCase();
    
    // Check if the message contains any conversational phrases
    return conversationalPhrases.any((phrase) => lowerMessage.contains(phrase));
  }
}

