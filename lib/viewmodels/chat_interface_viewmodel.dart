import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bot_service.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';
import '../models/reddit_post.dart';
import '../models/youtube_video.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/youtube_service.dart';

class ChatInterfaceViewModel extends ChangeNotifier {
  // Core message storage and service dependencies
  final List<Map<String, dynamic>> messages = []; // Stores all chat messages with metadata
  final BotService botService;                    // API calls to Perplexity
  final ChatService chatService;                  // Local/Firebase chat management
  String? currentChatId;                          // ID of the active chat
  String? currentChatTitle;                       // Title of the active chat
  bool isBotTyping = false;                       // Controls typing animation display
  bool isScrollToBottomButtonVisible = false;     // Controls scroll button visibility
  List<YouTubeVideo> currentVideos = [];          // YouTube videos for current response
  List<RedditPost> currentRedditPosts = [];        // Reddit posts for current response
  
  // Typing animation properties
  String currentTypingText = '';                  // Partial text shown during typing animation
  Timer? typingTimer;                             // Timer that controls typing animation speed
  String fullBotResponse = '';                    // Complete text being animated
  int currentCharIndex = 0;                       // Current position in typing animation
  double typingSpeed = 1.5;                       // Speed multiplier for typing animation
  
  // Edit functionality tracking
  int? editingMessageIndex;                       // Index of message being edited (null if none)
  
  // Constructor - initialises the ViewModel with dependencies and loads past chat if available
  ChatInterfaceViewModel({required this.chatService}) : 
      // Initialize BotService with API keys from environment variables
      botService = BotService(
        dotenv.env['PERPLEXITY_API_KEY'] ?? 'your-api-key',
        redditClientId: dotenv.env['REDDIT_CLIENT_ID'] ?? '',
        redditClientSecret: dotenv.env['REDDIT_CLIENT_SECRET'] ?? '',
      ) {
    // Load existing chat if available
    if (chatService.currentChat != null) {
      currentChatId = chatService.currentChat!.id;
      currentChatTitle = chatService.currentChat!.title;
      
      // Convert stored chat messages to in-memory format    
      for (var message in chatService.currentChat!.messages) {
        // Reconstruct YouTubeVideo objects from stored data
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
        
        // Reconstruct RedditPost objects from stored data
        List<RedditPost> redditPosts = [];
        if (message.containsKey('redditPosts') && message['redditPosts'] != null) {
          try {
            List<dynamic> postList = message['redditPosts'] as List<dynamic>;
            redditPosts = postList.map((p) {
              if (p is Map<String, dynamic>) {
                return RedditPost(
                  title: p['title'] ?? '',
                  selftext: p['selftext'] ?? '',
                  url: p['url'] ?? '',
                  score: p['score'] ?? 0,
                  subreddit: p['subreddit'] ?? '',
                  createdUtc: p['createdUtc'] ?? 0,
                  commentCount: p['commentCount'] ?? 0,
                  thumbnailUrl: p['thumbnailUrl'],
                  relevanceScore: p['relevanceScore']?.toDouble() ?? 0.0,
                );
              }
              return null;
            }).whereType<RedditPost>().toList();
          } catch (e) {
            print('Error loading saved Reddit posts: $e');
          }
        }
        
        // Add reconstructed message to in-memory list
        messages.add({
          'sender': message['sender'] ?? '',
          'message': message['message'] ?? '',
          'videos': videos,
          'redditPosts': redditPosts,
          'edited': message['edited'] ?? false,
          'regenerated': message['regenerated'] ?? false,
        });
      }
      
      // Initialise API service with conversation history for context
      final botMessages = messages.map((m) => {
        'role': m['sender'] == 'user' ? 'user' : 'assistant',
        'content': m['message'] ?? '',
      }).toList();
      
      botService.initialiseConversationHistory(botMessages);
    }
    
    // Load user preferences for typing speed
    loadTypingSpeed();
  }
  
  // --- MESSAGE EDITING FUNCTIONALITY ---
  
  // Begin editing a user message - sets the editing state
  void startEditingMessage(int index) {
    // Only allow editing user messages
    if (index >= 0 && index < messages.length && messages[index]['sender'] == 'user') {
      editingMessageIndex = index;
      notifyListeners();
    }
  }
  
  // Cancel the message editing process
  void cancelEditingMessage() {
    editingMessageIndex = null;
    notifyListeners();
  }
  
  // Update a message and regenerate the corresponding bot response
  Future<void> updateMessage(String updatedMessage) async {
    if (editingMessageIndex == null || editingMessageIndex! >= messages.length) {
      return;
    }
    
    final oldMessage = messages[editingMessageIndex!]['message'] as String;
    
    // Skip processing if message content hasn't changed
    if (oldMessage == updatedMessage) {
      cancelEditingMessage();
      return;
    }
    
    // Update the user message and mark it as edited
    messages[editingMessageIndex!]['message'] = updatedMessage;
    messages[editingMessageIndex!]['edited'] = true;
    
    // Find the next bot message that needs to be regenerated
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
      
      // Reset UI state for new response
      isBotTyping = true;
      currentTypingText = '';  
      currentVideos = [];      
      currentRedditPosts = []; 
      notifyListeners();
      
      try {
        // Prepare conversation history for the API
        final botMessages = messages.map((m) => {
          'role': m['sender'] == 'user' ? 'user' : 'assistant',
          'content': m['message'] ?? '',
        }).toList();
        
        // Get new response from the API
        final response = await botService.getResponseWithVideos(updatedMessage, botMessages);
        
        // Process videos from the response
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
        
        // Process Reddit posts from the response
        List<RedditPost> redditPosts = [];
        if (response.containsKey('redditPosts')) {
          try {
            final postsList = response['redditPosts'] as List<dynamic>;
            if (postsList.isNotEmpty) {
              redditPosts = postsList.whereType<RedditPost>().toList();
            }
          } catch (e) {
            print('Error processing Reddit posts: $e');
          }
        }
        
        // Add the regenerated bot message back to the chat
        messages.insert(editedIndex! + 1, {
          'sender': 'bot',
          'message': response['text'],
          'videos': videos,
          'redditPosts': redditPosts,
          'regenerated': true, // Mark as regenerated
        });
        
        // Remove any subsequent messages as they're now out of context
        if (editedIndex! + 2 < messages.length) {
          messages.removeRange(editedIndex! + 2, messages.length);
        }
        
        // Update UI state
        isBotTyping = false;
        
        // Update API context with new conversation
        final updatedBotMessages = messages.map((m) => {
          'role': m['sender'] == 'user' ? 'user' : 'assistant',
          'content': m['message'] ?? '',
        }).toList();
        botService.initialiseConversationHistory(updatedBotMessages);
        
        // Save changes to storage
        _saveCurrentChat();
        
        notifyListeners();
      } catch (e) {
        // Handle errors during regeneration
        print('Error updating message: $e');
        isBotTyping = false;
        
        // If there was an error, restore the original bot message
        if (editedIndex! + 1 <= messages.length) {
          messages.insert(editedIndex! + 1, botMessage);
        }
        
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }
  
  // --- TYPING ANIMATION CONFIGURATION ---
  
  // Calculate delay between typing animation updates based on speed setting
  int getTypingInterval() {
    // Return milliseconds between typing animation updates
    switch (typingSpeed) {
      case 0.5: return 60;  // Slow
      case 2.5: return 15;  // Fast
      case 1.5:             // Medium
      default: return 30;   // Default to medium
    }
  }
  
  // Calculate how many characters to add per typing update
  int getCharsPerUpdate() {
    // Return number of characters to add each typing animation step
    switch (typingSpeed) {
      case 0.5: return 3;   // Slow
      case 2.5: return 10;  // Fast
      case 1.5:             // Medium
      default: return 5;    // Default to medium
    }
  }
  
  // Update typing speed preference
  void setTypingSpeed(double speed) {
    typingSpeed = speed;
    saveTypingSpeed();
    notifyListeners();
  }
  
  // Save typing speed to persistent storage
  Future<void> saveTypingSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('typing_speed', typingSpeed);
  }
  
  // Load typing speed from persistent storage
  Future<void> loadTypingSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    typingSpeed = prefs.getDouble('typing_speed') ?? 1.5;
    notifyListeners();
  }
  
  // --- UI CONTROLS ---
  
  // Control visibility of the scroll-to-bottom button
  void setScrollButtonVisibility(bool visible) {
    isScrollToBottomButtonVisible = visible;
    notifyListeners();
  }
  
  // --- CORE MESSAGING FUNCTIONALITY ---
  
  // Process a new user message and get AI response
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Add user message to the chat
    messages.add({
      'sender': 'user', 
      'message': message,
      'videos': <YouTubeVideo>[],
      'redditPosts': <RedditPost>[],
    });
    notifyListeners();
    
    // Reset UI state for new response
    isBotTyping = true;
    currentTypingText = '';
    currentVideos = [];
    currentRedditPosts = [];
    notifyListeners();
    
    try {
      // Create new chat or use existing one
      if (currentChatId == null) {
        final chat = await chatService.createChat(_generateChatTitle(message));
        currentChatId = chat.id;
        currentChatTitle = chat.title;
      }
      
      // Prepare conversation history for API
      final botMessages = messages.map((m) => {
        'role': m['sender'] == 'user' ? 'user' : 'assistant',
        'content': m['message'] ?? '',
      }).toList();
      
      // Get AI response with enhanced content
      final response = await botService.getResponseWithVideos(message, botMessages);
      
      // Process videos from the response
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
      
      // Process Reddit posts from the response
      List<RedditPost> redditPosts = [];
      if (response.containsKey('redditPosts')) {
        try {
          final postsList = response['redditPosts'] as List<dynamic>;
          if (postsList.isNotEmpty) {
            try {
              for (var i = 0; i < postsList.length; i++) {
                try {
                  final post = postsList[i];
                  if (post is RedditPost) {
                    redditPosts.add(post);
                  } else {
                    print('Post at index $i is not a RedditPost: ${post.runtimeType}');
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
      
      // Skip videos for simple replies like "thank you"
      bool isConversationalResponse = _isLikelyConversationalResponse(message);
      if (isConversationalResponse) {
        videos = [];
        redditPosts = [];
      }
      
      // Begin typing animation with the response content
      startTypingAnimation(response['text'], videos, redditPosts);
      
      // Save chat to persistent storage
      _saveCurrentChat();
    } catch (e) {
      // Handle error in getting AI response
      isBotTyping = false;
      messages.add({
        'sender': 'bot', 
        'message': 'Sorry, I encountered an error: $e',
        'videos': <YouTubeVideo>[],
        'redditPosts': <RedditPost>[],
      });
      notifyListeners();
      
      // Save chat even if there was an error
      _saveCurrentChat();
    }
  }
  
  // Determines if a message is a simple conversational response
  bool _isLikelyConversationalResponse(String message) {
    // List of common phrases that don't need enhanced content
    final conversationalPhrases = [
      'thank you', 'thanks', 'ok', 'okay', 'got it', 'understood', 'great',
      'good', 'perfect', 'excellent', 'awesome', 'nice', 'cool', 'sounds good',
      'appreciate it', 'that\'s helpful', 'that helps', 'i see', 'alright',
      'all right', 'sure', 'fine', 'bye', 'goodbye', 'see you', 'talk later',
      'have a good day', 'great job', 'well done', 'amazing'
    ];
    
    final lowerMessage = message.toLowerCase().trim();
    
    // Check if the message matches any conversational phrase pattern
    return conversationalPhrases.any((phrase) => 
      lowerMessage == phrase || 
      lowerMessage.startsWith('$phrase.') || 
      lowerMessage.startsWith('$phrase!') ||
      lowerMessage.startsWith('$phrase,')
    );
  }
  
  // Start the typing animation for bot response
  void startTypingAnimation(String response, List<YouTubeVideo> videos, List<RedditPost> redditPosts) {
    // Initialize animation state
    fullBotResponse = response;
    currentCharIndex = 0;
    currentTypingText = '';
    currentVideos = videos.isNotEmpty ? videos : [];
    currentRedditPosts = redditPosts.isNotEmpty ? redditPosts : [];
    
    // Cancel any existing animation
    typingTimer?.cancel();
    
    // Start new animation timer
    typingTimer = Timer.periodic(Duration(milliseconds: getTypingInterval()), (timer) {
      if (currentCharIndex < fullBotResponse.length) {
        // Add the next chunk of text
        final charsToAdd = getCharsPerUpdate();
        final endIndex = (currentCharIndex + charsToAdd) < fullBotResponse.length 
            ? currentCharIndex + charsToAdd 
            : fullBotResponse.length;
            
        currentTypingText += fullBotResponse.substring(currentCharIndex, endIndex);
        currentCharIndex = endIndex;
        
        notifyListeners();
      } else {
        // Animation complete
        timer.cancel();
        isBotTyping = false;
        
        // Add the complete message to chat
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
  
  // Save current chat to persistent storage
  void _saveCurrentChat() {
    if (currentChatId != null && currentChatTitle != null) {
      // Convert in-memory message format to storage format
      final chatMessages = messages.map((m) => {
        'sender': m['sender'] ?? '',
        'message': m['message'] ?? '',
        // Convert videos to serializable format
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
        // Convert Reddit posts to serializable format
        'redditPosts': (m['redditPosts'] as List<dynamic>?)?.map((post) {
          if (post is RedditPost) {
            return post.toMap();
          }
          return null;
        }).whereType<Map<String, dynamic>>().toList() ?? [],
        // Preserve edit status
        'edited': m.containsKey('edited') ? m['edited'] : false,
      }).toList();

      // Create Chat object for storage
      final chat = Chat(
        id: currentChatId!,
        title: currentChatTitle!,
        createdAt: DateTime.now(),
        messages: chatMessages,
      );
      
      chatService.setCurrentChat(chat);
    }
  }
  
  // Generate a title for new chats based on first message
  String _generateChatTitle(String message) {
    if (message.length <= 20) return message;
    return '${message.substring(0, 20)}...';
  }
  
  // Reset the chat to empty state
  void clearChat() {
    messages.clear();
    currentChatId = null;
    currentChatTitle = null;
    currentVideos = [];
    currentRedditPosts = [];
    chatService.setCurrentChat(null);
    notifyListeners();
  }
  
  // Clean up resources when ViewModel is no longer needed
  @override
  void dispose() {
    typingTimer?.cancel();
    super.dispose();
  }
  
  // Get user initial for avatar display
  String get userInitial {
    final displayName = chatService.currentUserDisplayName;
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }
  
  // --- REGENERATION FUNCTIONALITY ---
  
  // Regenerate a bot message with fresh API call
  Future<void> regenerateMessage(int botMessageIndex) async {
    if (botMessageIndex < 0 || botMessageIndex >= messages.length) {
      return;
    }

    // Only regenerate bot messages
    if (messages[botMessageIndex]['sender'] != 'bot') {
      return;
    }

    // Find the user message that triggered this response
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

    // Store the current index before removing the message
    final currentBotMessageIndex = botMessageIndex;
    
    // Remove the bot message that will be regenerated
    final botMessage = messages.removeAt(botMessageIndex);
    
    // Reset UI state for new response
    isBotTyping = true;
    currentTypingText = '';
    currentVideos = [];
    currentRedditPosts = [];
    notifyListeners();
    
    try {
      // Get the original user message that prompted this response
      final userMessage = messages[previousUserIndex]['message'] as String;
      
      // Prepare conversation history for API
      final botMessages = messages.map((m) => {
        'role': m['sender'] == 'user' ? 'user' : 'assistant',
        'content': m['message'] ?? '',
      }).toList();
      
      // Get new response from API
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
      List<RedditPost> redditPosts = [];
      if (response.containsKey('redditPosts')) {
        try {
          final postsList = response['redditPosts'] as List<dynamic>;
          if (postsList.isNotEmpty) {
            redditPosts = postsList.whereType<RedditPost>().toList();
          }
        } catch (e) {
          print('Error processing Reddit posts: $e');
        }
      }
      
      // Add regenerated message to chat
      messages.insert(previousUserIndex + 1, {
        'sender': 'bot',
        'message': response['text'],
        'videos': videos,
        'redditPosts': redditPosts,
        'regenerated': true, // Mark as regenerated
      });
      
      // Remove any subsequent messages as they're now out of context
      if (previousUserIndex + 2 < messages.length) {
        messages.removeRange(previousUserIndex + 2, messages.length);
      }
      
      // Update UI state
      isBotTyping = false;
      
      // Update API context with new conversation
      final updatedBotMessages = messages.map((m) => {
        'role': m['sender'] == 'user' ? 'user' : 'assistant',
        'content': m['message'] ?? '',
      }).toList();
      botService.initialiseConversationHistory(updatedBotMessages);
      
      // Save changes to storage
      _saveCurrentChat();
      
      notifyListeners();
    } catch (e) {
      // Handle errors during regeneration
      print('Error regenerating message: $e');
      isBotTyping = false;
      
      // If there was an error, restore the original message
      if (currentBotMessageIndex <= messages.length) {
        messages.insert(currentBotMessageIndex, botMessage);
      }
      
      notifyListeners();
    }
  }
} 