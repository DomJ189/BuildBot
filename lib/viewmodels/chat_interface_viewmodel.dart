import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bot_service.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';
import '../models/reddit_post_preview.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/youtube_service.dart';

class ChatInterfaceViewModel extends ChangeNotifier {
  final List<Map<String, dynamic>> messages = [];
  final BotService botService;
  final ChatService chatService;
  String? currentChatId;
  String? currentChatTitle;
  bool isBotTyping = false;
  bool isScrollToBottomButtonVisible = false;
  List<YouTubeVideo> currentVideos = [];
  List<RedditPostPreview> currentRedditPosts = [];
  
  // Typing animation properties
  String currentTypingText = '';
  Timer? typingTimer;
  String fullBotResponse = '';
  int currentCharIndex = 0;
  String typingSpeed = 'Medium';
  
  // New property to track which message is being edited
  int? editingMessageIndex;
  
  ChatInterfaceViewModel({required this.chatService}) : 
      // Initialize with API key from .env file
      botService = BotService(
        dotenv.env['PERPLEXITY_API_KEY'] ?? 'your-api-key',
        redditClientId: dotenv.env['REDDIT_CLIENT_ID'] ?? '',
        redditClientSecret: dotenv.env['REDDIT_CLIENT_SECRET'] ?? '',
      ) {
    // Initialize with current chat if available
    if (chatService.currentChat != null) {
      currentChatId = chatService.currentChat!.id;
      currentChatTitle = chatService.currentChat!.title;
      
      // Convert old format messages to new format    
      for (var message in chatService.currentChat!.messages) {
        // Convert saved video data back to YouTubeVideo objects
        List<YouTubeVideo> videos = [];
        if (message.containsKey('videos') && message['videos'] != null) {
          try {
            List<dynamic> videoList = message['videos'] as List<dynamic>;
            videos = videoList.map((v) {
              if (v is Map<String, dynamic>) {
                return YouTubeVideo(
                  id: v['id'] ?? '',
                  title: v['title'] ?? '',
                  thumbnailUrl: v['thumbnailUrl'] ?? '',
                  channelTitle: v['channelTitle'] ?? '',
                  publishedAt: v.containsKey('publishedAt') ? 
                      DateTime.parse(v['publishedAt']) : 
                      DateTime.now(),
                );
              }
              return null;
            }).whereType<YouTubeVideo>().toList();
          } catch (e) {
            print('Error loading saved videos: $e');
          }
        }
        
        // Convert saved Reddit post data back to RedditPostPreview objects
        List<RedditPostPreview> redditPosts = [];
        if (message.containsKey('redditPosts') && message['redditPosts'] != null) {
          try {
            List<dynamic> postList = message['redditPosts'] as List<dynamic>;
            redditPosts = postList.map((p) {
              if (p is Map<String, dynamic>) {
                return RedditPostPreview(
                  title: p['title'] ?? '',
                  subreddit: p['subreddit'] ?? '',
                  url: p['url'] ?? '',
                  score: p['score'] ?? 0,
                  commentCount: p['commentCount'] ?? 0,
                  thumbnailUrl: p['thumbnailUrl'],
                  relevanceScore: p['relevanceScore']?.toDouble() ?? 0.0,
                );
              }
              return null;
            }).whereType<RedditPostPreview>().toList();
          } catch (e) {
            print('Error loading saved Reddit posts: $e');
          }
        }
        
        messages.add({
          'sender': message['sender'] ?? '',
          'message': message['message'] ?? '',
          'videos': videos,
          'redditPosts': redditPosts,
          'edited': message['edited'] ?? false,
          'regenerated': message['regenerated'] ?? false,
        });
      }
      
      // Initialize bot service with conversation history
      final botMessages = messages.map((m) => {
        'role': m['sender'] == 'user' ? 'user' : 'assistant',
        'content': m['message'] ?? '',
      }).toList();
      
      botService.initializeConversationHistory(botMessages);
    }
    
    // Load typing speed preference
    loadTypingSpeed();
  }
  
  // New methods for message editing functionality
  
  // Start editing a message
  void startEditingMessage(int index) {
    // Only allow editing user messages
    if (index >= 0 && index < messages.length && messages[index]['sender'] == 'user') {
      editingMessageIndex = index;
      notifyListeners();
    }
  }
  
  // Cancel editing
  void cancelEditingMessage() {
    editingMessageIndex = null;
    notifyListeners();
  }
  
  // Update a message and regenerate bot response
  Future<void> updateMessage(String updatedMessage) async {
    if (editingMessageIndex == null || editingMessageIndex! >= messages.length) {
      return;
    }
    
    final oldMessage = messages[editingMessageIndex!]['message'] as String;
    
    // If the message hasn't changed, just cancel editing
    if (oldMessage == updatedMessage) {
      cancelEditingMessage();
      return;
    }
    
    // Update the user message and mark it as edited
    messages[editingMessageIndex!]['message'] = updatedMessage;
    messages[editingMessageIndex!]['edited'] = true;
    
    // Find the next bot message after this user message
    int nextBotIndex = -1;
    for (int i = editingMessageIndex! + 1; i < messages.length; i++) {
      if (messages[i]['sender'] == 'bot') {
        nextBotIndex = i;
        break;
      }
    }
    
    // Keep track of edited index before resetting
    final editedIndex = editingMessageIndex;
    
    // Reset editing state but keep typing state active
    editingMessageIndex = null;
    
    // If there's a corresponding bot message, regenerate it
    if (nextBotIndex != -1) {
      // Remove the bot message that will be regenerated
      final botMessage = messages.removeAt(nextBotIndex);
      
      // Clear previous typing data and set bot typing state
      isBotTyping = true;
      currentTypingText = '';  // Ensure no previous text is displayed while regenerating
      currentVideos = [];      // Clear any previous videos
      currentRedditPosts = []; // Clear any previous Reddit posts
      notifyListeners();
      
      try {
        // Include ALL messages up to but not including the bot message that will be regenerated
        // This ensures proper context is maintained for the bot response
        final botMessages = messages.map((m) => {
          'role': m['sender'] == 'user' ? 'user' : 'assistant',
          'content': m['message'] ?? '',
        }).toList();
        
        // Get response from bot service with videos
        final response = await botService.getResponseWithVideos(updatedMessage, botMessages);
        
        // Process videos from response
        List<YouTubeVideo> videos = [];
        if (response.containsKey('videos')) {
          try {
            final videoList = response['videos'] as List<dynamic>;
            if (videoList.isNotEmpty) {
              videos = videoList.map((v) => v as YouTubeVideo).toList();
            }
          } catch (e) {
            print('Error processing videos: $e');
          }
        }
        
        // Process Reddit posts from response
        List<RedditPostPreview> redditPosts = [];
        if (response.containsKey('redditPosts')) {
          try {
            final postsList = response['redditPosts'] as List<dynamic>;
            if (postsList.isNotEmpty) {
              redditPosts = postsList.whereType<RedditPostPreview>().toList();
            }
          } catch (e) {
            print('Error processing Reddit posts: $e');
          }
        }
        
        // Add the regenerated bot message at the appropriate position
        messages.insert(editedIndex! + 1, {
          'sender': 'bot',
          'message': response['text'],
          'videos': videos,
          'redditPosts': redditPosts,
          'regenerated': true, // Mark as regenerated
        });
        
        // Remove any subsequent messages as they're now invalid
        if (editedIndex! + 2 < messages.length) {
          messages.removeRange(editedIndex! + 2, messages.length);
        }
        
        // Finish typing
        isBotTyping = false;
        
        // Update conversation history in bot service with all current messages
        final updatedBotMessages = messages.map((m) => {
          'role': m['sender'] == 'user' ? 'user' : 'assistant',
          'content': m['message'] ?? '',
        }).toList();
        botService.initializeConversationHistory(updatedBotMessages);
        
        // Save chat
        _saveCurrentChat();
        
        notifyListeners();
      } catch (e) {
        // Handle error
        print('Error updating message: $e');
        isBotTyping = false;
        
        // If there was an error, add back the original message
        if (editedIndex! + 1 <= messages.length) {
          messages.insert(editedIndex! + 1, botMessage);
        }
        
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }
  
  int getTypingInterval() {
    switch (typingSpeed) {
      case 'Slow': return 60;
      case 'Fast': return 15;
      case 'Medium': 
      default: return 30;
    }
  }
  
  int getCharsPerUpdate() {
    switch (typingSpeed) {
      case 'Slow': return 3;
      case 'Fast': return 10;
      case 'Medium': 
      default: return 5;
    }
  }
  
  void setTypingSpeed(String speed) {
    typingSpeed = speed;
    notifyListeners();
  }
  
  Future<void> saveTypingSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('typing_speed', typingSpeed);
  }
  
  Future<void> loadTypingSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    typingSpeed = prefs.getString('typing_speed') ?? 'Medium';
    notifyListeners();
  }
  
  void setScrollButtonVisibility(bool visible) {
    isScrollToBottomButtonVisible = visible;
    notifyListeners();
  }
  
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Add user message to the list
    messages.add({
      'sender': 'user', 
      'message': message,
      'videos': <YouTubeVideo>[],
      'redditPosts': <RedditPostPreview>[],
    });
    notifyListeners();
    
    // Clear previous typing data and set bot typing state
    isBotTyping = true;
    currentTypingText = '';  // Ensure no previous text is displayed while waiting
    currentVideos = [];      // Clear any previous videos
    currentRedditPosts = []; // Clear any previous reddit posts
    notifyListeners();
    
    try {
      // Create or update chat
      if (currentChatId == null) {
        final chat = await chatService.createChat(_generateChatTitle(message));
        currentChatId = chat.id;
        currentChatTitle = chat.title;
      }
      
      // Convert ALL previous messages to format expected by BotService
      // This ensures the bot has complete conversation history for context
      final botMessages = messages.map((m) => {
        'role': m['sender'] == 'user' ? 'user' : 'assistant',
        'content': m['message'] ?? '',
      }).toList();
      
      // Get response from bot service
      final response = await botService.getResponseWithVideos(message, botMessages);
      
      // Process videos from response if using getResponseWithVideos
      List<YouTubeVideo> videos = [];
      if (response.containsKey('videos')) {
        try {
          // Explicitly convert dynamic list to YouTubeVideo list
          final videoList = response['videos'] as List<dynamic>;
          if (videoList.isNotEmpty) {
            videos = videoList.map((v) => v as YouTubeVideo).toList();
          }
        } catch (e) {
          print('Error processing videos: $e');
        }
      }
      
      // Process Reddit posts from response
      List<RedditPostPreview> redditPosts = [];
      if (response.containsKey('redditPosts')) {
        try {
          final postsList = response['redditPosts'] as List<dynamic>;
          if (postsList.isNotEmpty) {
            try {
              for (var i = 0; i < postsList.length; i++) {
                try {
                  final post = postsList[i];
                  if (post is RedditPostPreview) {
                    redditPosts.add(post);
                  } else {
                    print('Post at index $i is not a RedditPostPreview: ${post.runtimeType}');
                  }
                } catch (postError) {
                  print('Error processing individual Reddit post at index $i: $postError');
                }
              }
            } catch (e) {
              print('Error iterating through Reddit posts: $e');
            }
            
            if (redditPosts.isEmpty && postsList.isNotEmpty) {
              print('Failed to process any Reddit posts despite having ${postsList.length} items');
            }
          }
        } catch (e) {
          print('Error processing Reddit posts: $e');
          print('RedditPosts content: ${response['redditPosts']}');
        }
      }
      
      // Check if this is likely a conversational response
      bool isConversationalResponse = _isLikelyConversationalResponse(message);
      
      // Don't show previously shown videos for conversational responses
      if (isConversationalResponse) {
        videos = [];
        redditPosts = [];
      }
      
      // Start typing animation with videos and Reddit posts
      startTypingAnimation(response['text'], videos, redditPosts);
      
      // Save chat to service
      _saveCurrentChat();
    } catch (e) {
      // Handle error
      isBotTyping = false;
      messages.add({
        'sender': 'bot', 
        'message': 'Sorry, I encountered an error: $e',
        'videos': <YouTubeVideo>[],
        'redditPosts': <RedditPostPreview>[],
      });
      notifyListeners();
      
      // Save chat even if there was an error
      _saveCurrentChat();
    }
  }
  
  // Helper method to check if a message is likely a simple conversational response
  bool _isLikelyConversationalResponse(String message) {
    final conversationalPhrases = [
      'thank you', 'thanks', 'ok', 'okay', 'got it', 'understood', 'great',
      'good', 'perfect', 'excellent', 'awesome', 'nice', 'cool', 'sounds good',
      'appreciate it', 'that\'s helpful', 'that helps', 'i see', 'alright',
      'all right', 'sure', 'fine', 'bye', 'goodbye', 'see you', 'talk later',
      'have a good day', 'great job', 'well done', 'amazing'
    ];
    
    final lowerMessage = message.toLowerCase().trim();
    
    // Check if the message consists only of conversational phrases
    return conversationalPhrases.any((phrase) => 
      lowerMessage == phrase || 
      lowerMessage.startsWith('$phrase.') || 
      lowerMessage.startsWith('$phrase!') ||
      lowerMessage.startsWith('$phrase,')
    );
  }
  
  void startTypingAnimation(String response, List<YouTubeVideo> videos, List<RedditPostPreview> redditPosts) {
    // Reset all typing-related variables to ensure previous response doesn't show
    fullBotResponse = response;
    currentCharIndex = 0;
    currentTypingText = '';  // Clear the current typing text
    currentVideos = videos.isNotEmpty ? videos : [];
    currentRedditPosts = redditPosts.isNotEmpty ? redditPosts : [];
    
    // Cancel any existing timer
    typingTimer?.cancel();
    
    // Start new timer for typing animation
    typingTimer = Timer.periodic(Duration(milliseconds: getTypingInterval()), (timer) {
      if (currentCharIndex < fullBotResponse.length) {
        // Calculate how many characters to add in this update
        final charsToAdd = getCharsPerUpdate();
        final endIndex = (currentCharIndex + charsToAdd) < fullBotResponse.length 
            ? currentCharIndex + charsToAdd 
            : fullBotResponse.length;
            
        // Add characters to the current typing text
        currentTypingText += fullBotResponse.substring(currentCharIndex, endIndex);
        currentCharIndex = endIndex;
        
        notifyListeners();
      } else {
        // Animation complete
        timer.cancel();
        isBotTyping = false;
        
        // Add the complete message to the list
        messages.add({
          'sender': 'bot', 
          'message': fullBotResponse,
          'videos': currentVideos,
          'redditPosts': currentRedditPosts,
        });
        
        // Save the updated chat
        _saveCurrentChat();
        
        notifyListeners();
      }
    });
  }
  
  void _saveCurrentChat() {
    if (currentChatId != null && currentChatTitle != null) {
      // Convert messages to the format expected by Chat model
      final chatMessages = messages.map((m) => {
        'sender': m['sender'] ?? '',
        'message': m['message'] ?? '',
        // Store video data as serializable objects
        'videos': (m['videos'] as List<dynamic>?)?.map((video) {
          if (video is YouTubeVideo) {
            return {
              'id': video.id,
              'title': video.title,
              'thumbnailUrl': video.thumbnailUrl,
              'channelTitle': video.channelTitle,
              'publishedAt': video.publishedAt.toIso8601String(),
            };
          }
          return null;
        }).whereType<Map<String, dynamic>>().toList() ?? [],
        // Store Reddit post data as serializable objects
        'redditPosts': (m['redditPosts'] as List<dynamic>?)?.map((post) {
          if (post is RedditPostPreview) {
            return {
              'title': post.title,
              'subreddit': post.subreddit,
              'url': post.url,
              'score': post.score,
              'commentCount': post.commentCount,
              'thumbnailUrl': post.thumbnailUrl,
            };
          }
          return null;
        }).whereType<Map<String, dynamic>>().toList() ?? [],
        // Add an edited flag for messages that were edited
        'edited': m.containsKey('edited') ? m['edited'] : false,
      }).toList();

      final chat = Chat(
        id: currentChatId!,
        title: currentChatTitle!,
        createdAt: DateTime.now(),
        messages: chatMessages,
      );
      
      chatService.setCurrentChat(chat);
    }
  }
  
  String _generateChatTitle(String message) {
    // Generate a title based on the first message
    if (message.length <= 20) return message;
    return '${message.substring(0, 20)}...';
  }
  
  void clearChat() {
    messages.clear();
    currentChatId = null;
    currentChatTitle = null;
    currentVideos = [];
    currentRedditPosts = [];
    chatService.setCurrentChat(null);
    notifyListeners();
  }
  
  @override
  void dispose() {
    typingTimer?.cancel();
    super.dispose();
  }
  
  // User information
  String get userInitial {
    final displayName = chatService.currentUserDisplayName;
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }
  
  // Add regenerateMessage method
  Future<void> regenerateMessage(int botMessageIndex) async {
    if (botMessageIndex < 0 || botMessageIndex >= messages.length) {
      return;
    }

    // Only regenerate bot messages
    if (messages[botMessageIndex]['sender'] != 'bot') {
      return;
    }

    // Find the previous user message that triggered this bot response
    int previousUserIndex = -1;
    for (int i = botMessageIndex - 1; i >= 0; i--) {
      if (messages[i]['sender'] == 'user') {
        previousUserIndex = i;
        break;
      }
    }

    if (previousUserIndex == -1) {
      return; // No user message found to regenerate from
    }

    // Store the current message index before removing it
    final currentBotMessageIndex = botMessageIndex;
    
    // Remove the bot message that will be regenerated
    final botMessage = messages.removeAt(botMessageIndex);
    
    // Clear previous typing data and set bot typing state
    isBotTyping = true;
    currentTypingText = '';  // Ensure no previous text is displayed while regenerating
    currentVideos = [];      // Clear any previous videos
    currentRedditPosts = []; // Clear any previous Reddit posts
    notifyListeners();
    
    try {
      // Get the user message that triggered this response
      final userMessage = messages[previousUserIndex]['message'] as String;
      
      // Include ALL messages up to the bot message for complete context
      // This ensures the bot has the full conversation history for better context preservation
      final botMessages = messages.map((m) => {
        'role': m['sender'] == 'user' ? 'user' : 'assistant',
        'content': m['message'] ?? '',
      }).toList();
      
      // Get new response from bot service with videos
      final response = await botService.getResponseWithVideos(userMessage, botMessages);
      
      // Process videos from response
      List<YouTubeVideo> videos = [];
      if (response.containsKey('videos')) {
        try {
          final videoList = response['videos'] as List<dynamic>;
          if (videoList.isNotEmpty) {
            videos = videoList.map((v) => v as YouTubeVideo).toList();
          }
        } catch (e) {
          print('Error processing videos: $e');
        }
      }
      
      // Process Reddit posts from response
      List<RedditPostPreview> redditPosts = [];
      if (response.containsKey('redditPosts')) {
        try {
          final postsList = response['redditPosts'] as List<dynamic>;
          if (postsList.isNotEmpty) {
            redditPosts = postsList.whereType<RedditPostPreview>().toList();
          }
        } catch (e) {
          print('Error processing Reddit posts: $e');
        }
      }
      
      // Add the regenerated bot message back to the list
      messages.insert(previousUserIndex + 1, {
        'sender': 'bot',
        'message': response['text'],
        'videos': videos,
        'redditPosts': redditPosts,
        'regenerated': true, // Mark as regenerated
      });
      
      // Remove any subsequent messages as they're now invalid
      if (previousUserIndex + 2 < messages.length) {
        messages.removeRange(previousUserIndex + 2, messages.length);
      }
      
      // Finish typing
      isBotTyping = false;
      
      // Update conversation history in bot service with all current messages
      final updatedBotMessages = messages.map((m) => {
        'role': m['sender'] == 'user' ? 'user' : 'assistant',
        'content': m['message'] ?? '',
      }).toList();
      botService.initializeConversationHistory(updatedBotMessages);
      
      // Save chat
      _saveCurrentChat();
      
      notifyListeners();
    } catch (e) {
      // Handle error
      print('Error regenerating message: $e');
      isBotTyping = false;
      
      // If there was an error, add back the original message
      if (currentBotMessageIndex <= messages.length) {
        messages.insert(currentBotMessageIndex, botMessage);
      }
      
      notifyListeners();
    }
  }
} 