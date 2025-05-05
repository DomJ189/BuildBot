import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/chat_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'dart:async';
import '../viewmodels/chat_interface_viewmodel.dart';
import '../widgets/youtube_video_player.dart';
import '../widgets/reddit_link_card.dart';
import '../models/reddit_post.dart';
import '../models/youtube_video.dart';

/// Main chat interface screen where users interact with the AI assistant.Displays messages, handles user input, and renders media content.
class ChatInterface extends StatefulWidget {
  const ChatInterface({super.key});

  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> with TickerProviderStateMixin {
  // Text input controllers
  final TextEditingController _controller = TextEditingController();     // For new messages
  final TextEditingController _editController = TextEditingController(); // For editing messages
  
  // Scroll controller to manage chat scrolling behaviour
  final ScrollController _scrollController = ScrollController();
  
  // Reference to the view model that manages chat state and logic
  late ChatInterfaceViewModel _viewModel;
  
  // Animation properties for typing indicator dots
  late AnimationController _dotAnimationController;
  int _activeDotIndex = 0; // Tracks which dot is currently active in animation
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for the typing indicator dots
    _dotAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          // Cycle through the three dots (0, 1, 2)
          _activeDotIndex = (_activeDotIndex + 1) % 3;
        });
        // Reset and continue animation
        _dotAnimationController.reset();
        _dotAnimationController.forward();
      }
    });
    
    // Start the typing animation immediately
    _dotAnimationController.forward();
    
    // Configure scroll detection to show/hide scroll button
    _scrollController.addListener(_scrollListener);
  }
  
  // Determines when to show the scroll-to-bottom button based on scroll position
  void _scrollListener() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Show button when user has scrolled up more than 200 pixels from bottom
    _viewModel.setScrollButtonVisibility(maxScroll - currentScroll > 200);
  }
  
  // Scrolls the chat to the bottom with animation
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  // Clean up resources when the widget is disposed
  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _dotAnimationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Access theme information for styling
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    // Create ViewModel and listen for changes with Consumer
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
                  // Main chat area - shows empty state or message list
                  Expanded(
                    child: viewModel.messages.isEmpty
                        ? _buildEmptyState(context, themeProvider)
                        : Stack(
                            children: [
                              _buildChatMessages(context, viewModel, themeProvider),
                              
                              // "New Chat" button positioned at top center
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
                              
                              // Scroll-to-bottom button (visible when scrolled up)
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
                  
                  // Message input area at bottom of screen
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkTheme ? Color(0xFF333333) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Text input field
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
                                    
                                    // Scroll to bottom after sending
                                    Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
                                  }
                                },
                              ),
                            ),
                          ),
                          // Send message button
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
                                  
                                  // Scroll to bottom after sending
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
  
  // Widget displayed when there are no messages in the chat
  Widget _buildEmptyState(BuildContext context, ThemeProvider themeProvider) {
    return Column(
      children: [
        SizedBox(height: 60), // Spacing at top
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
  
  // Builds the scrollable list of chat messages
  Widget _buildChatMessages(BuildContext context, ChatInterfaceViewModel viewModel, ThemeProvider themeProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(left: 16, right: 16, top: 64, bottom: 8),
      // Add an extra item for the typing indicator when bot is typing
      itemCount: viewModel.messages.length + (viewModel.isBotTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Show typing indicator at the end when bot is typing
        if (viewModel.isBotTyping && index == viewModel.messages.length) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show bot typing message or regeneration status
              _buildBotMessage(
                viewModel.editingMessageIndex != null 
                    ? "Regenerating response..." 
                    : (viewModel.currentTypingText.isNotEmpty 
                        ? viewModel.currentTypingText 
                        : ""),
                themeProvider,
                isTyping: true,
                messageIndex: -1, // Not a saved message yet
              ),
              // Show YouTube videos during typing if available
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
              // Show Reddit posts during typing if available
              if (viewModel.currentRedditPosts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Relevant Reddit Discussions:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...viewModel.currentRedditPosts.map((post) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: RedditLinkCard(post: post),
                        )
                      ).toList(),
                    ],
                  ),
                ),
            ],
          );
        }
        
        // Render normal chat messages (user or bot)
        if (index < viewModel.messages.length) {
          final message = viewModel.messages[index];
          final isUser = message['sender'] == 'user';
          
          // Check if this message is being edited
          final isEditing = viewModel.editingMessageIndex == index;
          
          // Render different bubble styles for user vs bot
          if (isUser) {
            return _buildUserMessage(
              message['message'] ?? '', 
              themeProvider, 
              edited: message['edited'] == true
            );
          } else {
            // Process bot-specific message content
            final videosList = message['videos'] as List<dynamic>?;
            final hasVideos = videosList != null && videosList.isNotEmpty;
            
            final redditPostsList = message['redditPosts'] as List<dynamic>?;
            final hasRedditPosts = redditPostsList != null && redditPostsList.isNotEmpty;
            
            // Check if this is likely a simple response like "you're welcome"
            final isConversational = _isLikelyConversationalResponse(message['message'] ?? '');
            
            // Check if the previous message already showed media to avoid duplicate media in conversational responses
            bool previousMessageHadVideos = false;
            bool previousMessageHadRedditPosts = false;
            if (index > 0) {
              final prevMessage = viewModel.messages[index - 1];
              final prevVideosList = prevMessage['videos'] as List<dynamic>?;
              previousMessageHadVideos = prevVideosList != null && prevVideosList.isNotEmpty;
              
              final prevRedditPostsList = prevMessage['redditPosts'] as List<dynamic>?;
              previousMessageHadRedditPosts = prevRedditPostsList != null && prevRedditPostsList.isNotEmpty;
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bot message bubble
                _buildBotMessage(
                  message['message'] ?? '', 
                  themeProvider,
                  regenerated: message['regenerated'] == true,
                  messageIndex: index,
                ),
                
                // Show videos if available and not a conversational follow-up
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
                
                // Show Reddit posts if available and not a conversational follow-up
                if (hasRedditPosts && !(isConversational && previousMessageHadRedditPosts))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Relevant Reddit Discussions:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...redditPostsList!.map((post) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: RedditLinkCard(post: post as RedditPost),
                          )
                        ).toList(),
                      ],
                    ),
                  ),
              ],
            );
          }
        }
        
        return SizedBox.shrink(); // Fallback for invalid indices
      },
    );
  }
  
  // Builds a user message bubble with edit option
  Widget _buildUserMessage(String message, ThemeProvider themeProvider, {bool edited = false}) {
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    // Check if this message is currently being edited
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Edit button for user messages
              GestureDetector(
                onTap: () {
                  // Show edit dialogue when tapped
                  _showEditDialogue(message);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    // Highlight icon when message is being edited
                    color: isBeingEdited 
                        ? (isDarkTheme ? Colors.white : Colors.blue)
                        : (isDarkTheme ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ),
              // Message bubble with text
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkTheme ? Colors.white : Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                    // Add highlight border when being edited
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
              // User avatar with initial
              SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDarkTheme ? Color(0xFF555555) : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _viewModel.userInitial,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // "edited" label shown for edited messages
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
  
  // Shows a dialogue to edit a user message
  void _showEditDialogue(String message) {
    // Find the index of the message to edit
    final messageIndex = _viewModel.messages.indexWhere(
      (m) => m['sender'] == 'user' && m['message'] == message
    );
    
    if (messageIndex < 0) return; // Message not found
    
    // Initialize edit controller with current message text
    _editController.text = message;
    
    // Update ViewModel editing state
    _viewModel.startEditingMessage(messageIndex);
    
    // Show the edit dialogue
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDarkTheme ? Color(0xFF333333) : Colors.white,
          title: Text(
            'Edit Message',
            style: TextStyle(
              color: themeProvider.currentTheme.textTheme.titleLarge?.color,
            ),
          ),
          content: TextField(
            controller: _editController,
            autofocus: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Edit your message',
              hintStyle: TextStyle(
                color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            style: TextStyle(
              color: themeProvider.currentTheme.textTheme.bodyLarge?.color,
            ),
            maxLines: 5,
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                // Cancel editing without saving changes
                _viewModel.cancelEditingMessage();
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            // Update button
            TextButton(
              onPressed: () {
                // Save changes and regenerate bot response
                _viewModel.updateMessage(_editController.text);
                Navigator.of(context).pop();
                
                // Scroll to show updated content
                Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
  
  // Builds a bot message bubble with optional typing indicator
  Widget _buildBotMessage(String message, ThemeProvider themeProvider, {
    bool isTyping = false,  // Whether this is the typing indicator
    bool regenerated = false, // Whether this message was regenerated
    int messageIndex = -1,  // Index in the messages list (-1 for typing indicator)
  }) {
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bot avatar with logo
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkTheme ? Colors.blue[700] : Colors.blue[300],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/BuildBotLogo.png',
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 8),
              // Message bubble with content
              Flexible(
                child: Container(
                  margin: EdgeInsets.only(bottom: regenerated ? 2 : 8),
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
                      // Render message content with Markdown
                      if (message.isNotEmpty)
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
                      // Show typing animation if this is the typing indicator
                      if (isTyping)
                        Padding(
                          padding: EdgeInsets.only(top: message.isNotEmpty ? 8.0 : 0.0),
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
              ),
              // Regenerate button for sent messages (not typing indicator)
              if (!isTyping && messageIndex >= 0)
                Builder(
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.refresh,
                          size: 18.0,
                          color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: () {
                          // Trigger regeneration of this response
                          final viewModel = Provider.of<ChatInterfaceViewModel>(context, listen: false);
                          viewModel.regenerateMessage(messageIndex);
                          
                          // Scroll to show typing indicator
                          Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
                        },
                        tooltip: 'Regenerate response',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        splashRadius: 16,
                      ),
                    );
                  }
                ),
            ],
          ),
          // "regenerated" label shown for regenerated messages
          if (regenerated)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 48.0),
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
  
  // Builds an animated typing indicator dot
  Widget _buildTypingDot(ThemeProvider themeProvider, int index) {
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    // Determine dot color based on theme and active state
    final dotColor = isDarkTheme 
        ? Colors.white.withOpacity(index == _activeDotIndex ? 1.0 : 0.3)
        : Colors.black.withOpacity(index == _activeDotIndex ? 1.0 : 0.3);
    
    return AnimatedBuilder(
      animation: _dotAnimationController,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          height: 8,
          width: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
  
  // Determines if a bot message is a simple reply like "You're welcome"
  bool _isLikelyConversationalResponse(String message) {
    // List of phrases that indicate a simple conversational response
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

