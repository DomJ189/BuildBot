import 'dart:convert';
import 'package:http/http.dart' as http;
import 'youtube_service.dart';
import 'tech_news_service.dart';
import 'reddit_service.dart';
import 'gpu_recommendation_service.dart';
import 'dart:math' as math;
import '../models/youtube_video.dart';
import '../models/conversation_manager.dart';
import '../models/content_request_handler.dart';
import '../models/conversational_response_handler.dart';
import '../models/bot_model.dart';

// Handles communication with the Perplexity AI API for generating responses
class BotService {
  String apiKey; 
  final ConversationManager _conversation = ConversationManager();
  final YouTubeService _youtubeService;
  final TechNewsService _techNewsService;
  final RedditService _redditService;
  final GPURecommendationService _gpuService;

  // Constructor to initialise the BotService with the provided API key
  BotService(
    this.apiKey, {
    required String redditClientId,
    required String redditClientSecret,
    YouTubeService? youtubeService,
    TechNewsService? techNewsService,
    GPURecommendationService? gpuService,
  }) : 
    _youtubeService = youtubeService ?? YouTubeService(),
    _techNewsService = techNewsService ?? TechNewsService(),
    _redditService = RedditService(
      clientId: redditClientId,
      clientSecret: redditClientSecret,
    ),
    _gpuService = gpuService ?? GPURecommendationService() {
    _initialiseApiKey();
  }

  void _initialiseApiKey() {
    // Try to load API key from environment if not provided
    if (apiKey == 'your-api-key') {
      final envKey = const String.fromEnvironment('PERPLEXITY_API_KEY');
      if (envKey.isNotEmpty && envKey != 'your-api-key') {
        apiKey = envKey;
      }
    }
  }

  // Removes citation numbers in square brackets from text
  String _removeCitations(String text) {
    // Regular expression to match citation numbers like [1], [2], etc.
    final citationRegex = RegExp(r'\[\d+\]');
    return text.replaceAll(citationRegex, '');
  }
  
  // Clear conversation history (for starting a new chat)
  void clearConversationHistory() {
    _conversation.clear();
    print('Conversation history cleared');
  }

  // Initialise conversation history from external messages
  void initialiseConversationHistory(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) {
      print('Warning: Attempted to initialise conversation with empty message list');
      return;
    }
    
    print('Initialising conversation history with ${messages.length} messages');
    
    // Convert messages to the standard format before initialising
    final formattedMessages = messages.map((message) {
      // Check if message is already in the right format
      if (message.containsKey('role') && message.containsKey('content')) {
        return message;
      }
      
      // Convert from UI message format to API message format
      return {
        'role': message['sender'] == 'user' ? 'user' : 'assistant',
        'content': message['message'] ?? '',
      };
    }).toList();
    
    // Ensure messages have alternating roles (required by Perplexity API)
    final sanitisedMessages = _ensureAlternatingRoles(formattedMessages);
    
    // Initialise the conversation manager with sanitised messages
    _conversation.initialiseFrom(sanitisedMessages);
    
    // Double-check that conversation has been properly initialised
    if (_conversation.messages.isEmpty) {
      print('Error: Conversation manager failed to initialise messages');
    } else {
      print('Successfully initialised conversation with ${_conversation.messages.length} messages');
    }
  }
  
  // Ensure conversation history has properly alternating roles (user->assistant->user->assistant)
  List<Map<String, dynamic>> _ensureAlternatingRoles(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return [];
    
    final result = <Map<String, dynamic>>[];
    String lastRole = '';
    
    for (var message in messages) {
      final role = message['role'] as String;
      final content = message['content'] as String;
      
      // Skip empty messages
      if (content.trim().isEmpty) continue;
      
      // If this is the first message or the role is different from the last one, add it
      if (lastRole.isEmpty || role != lastRole) {
        result.add(message);
        lastRole = role;
      } 
      // If we have consecutive messages with the same role, merge them
      else if (role == lastRole && result.isNotEmpty) {
        final lastMessage = result.last;
        final combinedContent = '${lastMessage['content']}\n\n${message['content']}';
        result[result.length - 1] = {
          'role': role,
          'content': combinedContent
        };
        print('Merged consecutive $role messages for API compatibility');
      }
    }
    
    // API requires alternating user and assistant messages
    // Check if the sequence follows proper alternation and fix if needed
    if (result.length >= 2) {
      List<Map<String, dynamic>> fixedResult = [];
      String expectedRole = 'user'; // Conversation typically starts with user
      
      // Add the first message, ensuring it's from the user
      if (result[0]['role'] == 'user') {
        fixedResult.add(result[0]);
        expectedRole = 'assistant';
      } else {
        // If the first message is from the assistant, prepend a placeholder user message
        print('Adding placeholder user message at the start to maintain alternating roles');
        fixedResult.add({
          'role': 'user',
          'content': 'Hello'
        });
        fixedResult.add(result[0]);
        expectedRole = 'user';
      }
      
      // Process the rest of the messages
      for (int i = 1; i < result.length; i++) {
        final role = result[i]['role'] as String;
        
        // If the role matches what's expected, add it normally
        if (role == expectedRole) {
          fixedResult.add(result[i]);
          expectedRole = expectedRole == 'user' ? 'assistant' : 'user';
        } 
        // If this role is the same as the previous role, skip it (already handled through merging)
        else if (role == fixedResult.last['role']) {
          continue;
        }
        // If we have multiple assistant messages in a row, insert a placeholder user message
        else if (role == 'assistant' && expectedRole == 'user') {
          print('Adding placeholder user message to maintain alternating roles');
          fixedResult.add({
            'role': 'user',
            'content': 'Please continue.'
          });
          fixedResult.add(result[i]);
          expectedRole = 'user';
        }
        // If we have multiple user messages in a row, insert a placeholder assistant message
        else if (role == 'user' && expectedRole == 'assistant') {
          print('Adding placeholder assistant message to maintain alternating roles');
          fixedResult.add({
            'role': 'assistant', 
            'content': 'I understand. Please tell me more.'
          });
          fixedResult.add(result[i]);
          expectedRole = 'assistant';
        }
      }
      
      print('Fixed conversation history from ${result.length} to ${fixedResult.length} messages');
      return fixedResult;
    }
    
    return result;
  }

  // Fetch response from Perplexity API
  Future<Map<String, dynamic>> fetchResponse(String prompt) async {
    try {
      _conversation.addMessage('user', prompt);
      
      final additionalContext = await _buildAdditionalContext(prompt);
      final redditPosts = await _fetchRedditPostsIfNeeded(prompt);
      
      final response = await _callPerplexityApi(
        systemMessage: BotModel.buildSystemMessage(additionalContext),
        messages: _conversation.messages,
      );
      
      final content = BotModel.removeCitations(response['content'] ?? '');
      _conversation.addMessage('assistant', content);
      
      return {
        'text': BotModel.formatRedditPostsMessage(content, redditPosts, prompt),
        'videos': <YouTubeVideo>[],
        'redditPosts': redditPosts,
      };
    } catch (e) {
      print('Error in fetchResponse: $e');
      throw Exception('Failed to fetch response: $e');
    }
  }

  // Build additional context for the Perplexity API
  Future<String> _buildAdditionalContext(String prompt) async {
    String context = '';
    
    if (BotModel.isGPURecommendationQuery(prompt)) {
        final gpuInfo = await _getGPURecommendations(prompt);
        if (gpuInfo.isNotEmpty) {
        context += '\n\n$gpuInfo';
        }
      }
      
    if (BotModel.shouldFetchTechNews(prompt)) {
        final news = await _techNewsService.getLatestTechNews();
        if (news.isNotEmpty) {
        context += '\n\nRecent Tech News:\n';
          for (var article in news.take(3)) {
          context += '- [${article.title}](${article.url}) (${article.source})\n';
        }
      }
    }
    
    return context;
  }

  Future<List<dynamic>> _fetchRedditPostsIfNeeded(String prompt) async {
    if (BotModel.shouldFetchRedditPosts(prompt)) {
      try {
        return await _redditService.searchRedditForTroubleshooting(prompt);
      } catch (e) {
        print('Error fetching Reddit posts: $e');
      }
    }
    return [];
  }

  Future<Map<String, String>> _callPerplexityApi({
    required String systemMessage,
    required List<Map<String, dynamic>> messages,
  }) async {
      // First ensure message sequence is valid (alternating user/assistant)
      List<Map<String, dynamic>> validatedMessages = _ensureAlternatingRoles(messages);
      
      // Log how many messages we're sending to the API
      print('Sending ${validatedMessages.length} messages to Perplexity API after validation');
      
      // Format the first few messages for debugging
      if (validatedMessages.isNotEmpty) {
        print('First message: ${validatedMessages.first['role']} - ${(validatedMessages.first['content'] as String).substring(0, math.min(50, (validatedMessages.first['content'] as String).length))}...');
        if (validatedMessages.length > 1) {
          print('Last message: ${validatedMessages.last['role']} - ${(validatedMessages.last['content'] as String).substring(0, math.min(50, (validatedMessages.last['content'] as String).length))}...');
        }
      }
      
      final url = Uri.parse('https://api.perplexity.ai/chat/completions');
      final body = jsonEncode({
        'model': 'sonar',
        'messages': [
          {'role': 'system', 'content': systemMessage},
          ...validatedMessages,
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      });

      final response = await http.post(
        url,
        headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString().trim();
        print('Received response from API (${content.length} chars)');
        return {
          'content': content,
        };
      } else {
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch response: ${response.statusCode} - ${response.body}');
    }
  }

  // Validate that messages follow the alternating pattern required by the API
  void _validateMessageSequence(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) {
      print('Warning: Empty message list sent to API');
      return;
    }
    
    bool isValid = true;
    String lastRole = '';
    
    for (int i = 0; i < messages.length; i++) {
      final role = messages[i]['role'] as String;
      
      if (i > 0) {
        // After the first message, roles should alternate
        if (role == lastRole) {
          print('Error: Message at index $i has the same role ($role) as the previous message');
          isValid = false;
          break;
        }
      }
      
      lastRole = role;
    }
    
    if (!isValid) {
      print('WARNING: Message sequence does not follow alternating pattern. API may return an error.');
      // Print message roles for debugging
      for (int i = 0; i < messages.length; i++) {
        print('Message $i: ${messages[i]['role']}');
      }
    } else {
      print('Message sequence validation passed: roles are properly alternating');
    }
  }

  // Modify the getResponseWithVideos method to handle video requests differently
  Future<Map<String, dynamic>> getResponseWithVideos(String message, List<Map<String, dynamic>> messages) async {
    try {
      // If messages are provided, reinitialise the conversation context
      if (messages.isNotEmpty) {
        // Check if the last message in the viewmodel is the same as what we're about to add
        final lastMessage = messages.last;
        bool isDuplicateMessage = false;
        
        if (lastMessage['role'] == 'user' || lastMessage['sender'] == 'user') {
          final lastContent = lastMessage['content'] ?? lastMessage['message'] ?? '';
          // If the last message is from the user and has the same content, flag as duplicate
          if (lastContent.trim() == message.trim()) {
            print('Detected duplicate user message. Will not add again to conversation.');
            isDuplicateMessage = true;
          }
        }
        
        // Initialise conversation from viewmodel messages
        print('Refreshing conversation context with ${messages.length} messages from viewmodel');
        initialiseConversationHistory(messages);
        
        // Only add the user message if it's not a duplicate of the last message
        if (!isDuplicateMessage) {
      // Add user message to history
          _conversation.addMessage('user', message);
          print('Added user message to conversation');
        }
      } else {
        // If no messages provided, just start with this message
        _conversation.addMessage('user', message);
        print('Starting new conversation with user message');
      }
      
      // Log the conversation context
      print('Processing message with ${_conversation.messages.length} messages in context');
      print('Conversation has ${_conversation.messages.length} messages');
      
      // Check if this is just a conversational response (like "thank you")
      final isConversational = ConversationalResponseHandler.isConversational(message);
      
      // Check for Reddit-related queries
      List<dynamic> redditPosts = await _fetchRedditPostsIfNeeded(message);
      
      // Check if user is giving negative feedback about videos
      final isNegativeFeedback = ContentRequestHandler.isNegativeFeedback(message);
      
      // If the user says videos weren't helpful, try to get better videos
      if (isNegativeFeedback) {
        List<YouTubeVideo> betterVideos = await _tryBetterVideoSearch(message);
        
        String response;
        if (betterVideos.isEmpty) {
          response = "I'm sorry those videos weren't helpful. Unfortunately, I couldn't find other relevant videos on this topic.";
        } else {
          response = "I apologise those videos weren't helpful. Here are some more specific videos that should better address your question:";
        }
        
        // Add bot response to history
        _conversation.addMessage('assistant', response);
        
        return {
          'text': BotModel.formatRedditPostsMessage(response, redditPosts, message),
          'videos': betterVideos,
          'redditPosts': redditPosts,
        };
      }
      
      // If this is just a conversational message (like "thank you"), 
      // respond appropriately without showing videos
      if (isConversational) {
        final conversationalResponse = ConversationalResponseHandler.generateResponse(message);
        
        // Add bot response to history
        _conversation.addMessage('assistant', conversationalResponse);
        
        return {
          'text': BotModel.formatRedditPostsMessage(conversationalResponse, redditPosts, message),
          'videos': <YouTubeVideo>[],
          'redditPosts': redditPosts,
        };
      }
      
      // Check for direct video requests like "show me video reviews of it"
      bool isExplicitVideoRequest = ContentRequestHandler.isDirectVideoRequest(message);
      
      // Check if this is specifically a Reddit post request
      bool isExplicitRedditRequest = ContentRequestHandler.isDirectRedditRequest(message);
      
      // Handle specific Reddit post requests
      if (isExplicitRedditRequest) {
        // Extract topic from message
        String searchTopic = message.replaceAll(RegExp(r'(?:show me|find|get) (?:some )?(reddit|posts|threads)', caseSensitive: false), '').trim();
        
        // If no specific topic is found, try to extract from the message
        if (searchTopic.isEmpty || searchTopic.length < 5) {
          searchTopic = BotModel.extractTopicFromMessage(message);
        }
        
        // Fetch Reddit posts for this specific topic
        List<dynamic> explicitRedditPosts = [];
        try {
          if (searchTopic.isNotEmpty) {
            explicitRedditPosts = await _redditService.searchRedditForTroubleshooting(searchTopic);
          }
        } catch (e) {
          print('Error searching for Reddit posts: $e');
        }
        
        // Generate a response about the Reddit posts
        String redditResponse;
        if (explicitRedditPosts.isEmpty) {
          redditResponse = "I couldn't find any relevant Reddit discussions for that topic. Is there something else you'd like to know?";
        } else {
          redditResponse = "Here are some Reddit discussions that might help with information about $searchTopic:";
        }
        
        // Add bot response to history
        _conversation.addMessage('assistant', redditResponse);
        
        return {
          'text': BotModel.formatRedditPostsMessage(redditResponse, explicitRedditPosts, message),
          'videos': <YouTubeVideo>[],
          'redditPosts': explicitRedditPosts,
        };
      }
      
      // Extract video search topic from message or previous conversation
      if (isExplicitVideoRequest) {
        // Extract topic from message or previous conversation
        String videoSearchTopic = BotModel.extractTopicFromMessage(message);
        if (videoSearchTopic.isEmpty) {
          videoSearchTopic = _extractReferenceTopicFromMessage(message);
        }
        
        // Perform video search with appropriate query
        List<YouTubeVideo> videos = [];
        try {
          if (videoSearchTopic.isNotEmpty) {
            videos = await _youtubeService.searchVideos(videoSearchTopic);
          }
        } catch (e) {
          print('Error searching for videos: $e');
        }
        
        // Generate a response about the videos
        String videoResponse;
        if (videos.isEmpty) {
          videoResponse = "I couldn't find any relevant videos for that topic. Is there something else you'd like to know?";
          } else {
          videoResponse = "Here are some videos that might help with information about $videoSearchTopic:";
        }
        
        // Add bot response to history
        _conversation.addMessage('assistant', videoResponse);
        
        return {
          'text': BotModel.formatRedditPostsMessage(videoResponse, redditPosts, message),
          'videos': videos,
          'redditPosts': redditPosts,
        };
      }
      
      // For regular messages, get response from the AI
      final additionalContext = await _buildAdditionalContext(message);
      
      // Send a POST request to the Perplexity API
      final response = await _callPerplexityApi(
        systemMessage: BotModel.buildSystemMessage(additionalContext),
        messages: _conversation.messages,
      );
      
      final content = response['content'] ?? '';
      
      // Add response to conversation history
      _conversation.addMessage('assistant', content);
      
      // Create a response without videos initially
        return {
        'text': BotModel.formatRedditPostsMessage(BotModel.removeCitations(content), redditPosts, message),
          'videos': <YouTubeVideo>[],
          'redditPosts': redditPosts,
        };
    } catch (e) {
      // Log any exceptions that occur during the fetch process
      print('Error in getResponseWithVideos: $e');
      throw Exception('Failed to fetch response: $e'); // Rethrow the exception for further handling
    }
  }

  // Update this method signature
  Future<String> getResponse(String message, List<Map<String, dynamic>> messages) async {
    final response = await getResponseWithVideos(message, messages);
    return response['text'];
  }

  // Method to get GPU recommendations
  Future<String> _getGPURecommendations(String message) async {
    try {
      // Extract budget information from the message
      double budget = _extractBudgetFromMessage(message);
      
      if (budget > 0) {
        // Budget was found, get recommendations for that budget
        final recommendations = await _gpuService.getRecommendationsForBudget(budget);
        
        if (recommendations.isNotEmpty) {
          String result = '### GPU Recommendations Under \$$budget\n\n';
          
          for (var i = 0; i < recommendations.length; i++) {
            final gpu = recommendations[i];
            result += '${i + 1}. **${gpu.name}** - \$${gpu.price.toStringAsFixed(0)}\n';
            result += '   - Performance score: ${gpu.benchmark}\n';
            result += '   - Value score: ${gpu.value}\n';
            result += '   - VRAM: ${gpu.vram}\n';
            result += '   - Power: ${gpu.wattage}\n';
            result += '   - [More details](${gpu.url})\n\n';
          }
          
          return result;
        }
      }
      
      // Check for similar GPU requests
      final similarMatch = RegExp(r'(?:similar to|like|compared to|vs|versus|compare)\s+((?:rtx|gtx|rx)\s+\d{4}(?:\s+\w+)?)', caseSensitive: false).firstMatch(message.toLowerCase());
      
      if (similarMatch != null) {
        final gpuModel = similarMatch.group(1) ?? '';
        
        if (gpuModel.isNotEmpty) {
          final similarGpus = await _gpuService.findSimilarGPUs(gpuModel);
          
          if (similarGpus.isNotEmpty) {
            String result = '### GPUs Similar to $gpuModel\n\n';
            
            for (var i = 0; i < similarGpus.length; i++) {
              final gpu = similarGpus[i];
              result += '${i + 1}. **${gpu.name}** - \$${gpu.price.toStringAsFixed(0)}\n';
              result += '   - Performance score: ${gpu.benchmark}\n';
              result += '   - Value score: ${gpu.value}\n';
              result += '   - VRAM: ${gpu.vram}\n';
              result += '   - Power: ${gpu.wattage}\n';
              result += '   - [More details](${gpu.url})\n\n';
            }
            
            return result;
          }
        }
      }
      
      // Default: get best value GPUs
        final topGpus = await _gpuService.fetchBestValueGPUs();
        if (topGpus.isNotEmpty) {
          final bestGpus = topGpus.take(3).toList();
          
          String result = '### Current Best Value GPUs\n\n';
          
          for (var i = 0; i < bestGpus.length; i++) {
            final gpu = bestGpus[i];
            result += '${i + 1}. **${gpu.name}** - \$${gpu.price.toStringAsFixed(0)}\n';
            result += '   - Performance score: ${gpu.benchmark}\n';
            result += '   - Value score: ${gpu.value}\n';
            result += '   - VRAM: ${gpu.vram}\n';
            result += '   - Power: ${gpu.wattage}\n';
            result += '   - [More details](${gpu.url})\n\n';
          }
          
          return result;
      }
      
      return '';
    } catch (e) {
      print('Error generating GPU recommendations: $e');
      return '';
    }
  }

  // Helper to extract budget from a message
  double _extractBudgetFromMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Check various patterns for budget queries
    final budgetPatterns = [
      // Standard budget patterns
      RegExp(r'(?:under|less than|below|max|budget of|budget|for|around|about)\s*\$?(\d+)', caseSensitive: false),
      // Follow-up patterns like "what about $500" or "what about under $500"
      RegExp(r'(?:what|how)?\s*about\s+(?:under\s+)?\$?(\d+)', caseSensitive: false),
      // Direct amount patterns like "under $500" or "$500"
      RegExp(r'under\s+\$?(\d+)', caseSensitive: false),
      RegExp(r'(?:^|\s)\$?(\d+)(?:\s|$)', caseSensitive: false)
    ];
    
    // Try each pattern
    for (final pattern in budgetPatterns) {
      final match = pattern.firstMatch(lowerMessage);
      if (match != null) {
        final budgetStr = match.group(1) ?? '';
        final parsedBudget = double.tryParse(budgetStr) ?? 0.0;
        if (parsedBudget > 0) {
          return parsedBudget;
        }
      }
    }
    
    return 0.0;
  }

  // Extract topic from a reference like "show me videos about it" where "it" refers to a previous topic
  String _extractReferenceTopicFromMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Check if message contains reference words
    final containsReference = ['it', 'that', 'them', 'this', 'those', 'these']
        .any((ref) => lowerMessage.contains(ref));
    
    if (containsReference) {
      return _extractTopicFromConversation();
    }
    
    return '';
  }

  // Extract a topic from a conversation for video search
  String _extractTopicFromConversation() {
    // Start from most recent messages and go backward
    for (int i = _conversation.messages.length - 1; i >= 0; i--) {
      final message = _conversation.messages[i];
      if (message['role'] == 'user') {
        final content = message['content'].toString();
        
        // Skip very short messages that are likely follow-ups
        if (content.split(' ').length <= 3) {
          continue;
        }
        
        // Skip direct video requests
        if (ContentRequestHandler.isDirectVideoRequest(content) || 
            ContentRequestHandler.isRequestingVideos(content) ||
            ContentRequestHandler.isRequestingMoreVideos(content)) {
          continue;
        }
        
        // Extract meaningful content from the message
        return BotModel.extractTopicFromMessage(content);
      }
    }
    return '';
  }

  // Method to try to find better videos when user says current ones aren't helpful
  Future<List<YouTubeVideo>> _tryBetterVideoSearch(String feedbackMessage) async {
    try {
      // Extract topic from conversation context
      String searchTopic = '';
      
      // Look at the last few messages to find what we were talking about
      final recentMessages = _conversation.messages.reversed.take(4).toList().reversed.toList();
      
      // First try to find a specific request in the feedback
      final directRequest = BotModel.extractTopicFromMessage(feedbackMessage);
      if (directRequest.isNotEmpty) {
        searchTopic = directRequest;
        print('Found direct request in feedback: $searchTopic');
      } 
      // If no direct request, look at previous messages
      else if (recentMessages.length >= 2) {
        // Look for user messages that might contain the original topic
        for (int i = 0; i < recentMessages.length - 1; i++) {
          if (recentMessages[i]['role'] == 'user') {
            final potentialTopic = BotModel.extractTopicFromMessage(recentMessages[i]['content']);
            if (potentialTopic.isNotEmpty) {
              searchTopic = potentialTopic;
              print('Found topic in previous message: $searchTopic');
              break;
            }
          }
        }
      }
      
      // If we still don't have a topic, use a more specific query with the most recent user message
      if (searchTopic.isEmpty && recentMessages.isNotEmpty) {
        for (int i = recentMessages.length - 1; i >= 0; i--) {
          if (recentMessages[i]['role'] == 'user' && 
              !ContentRequestHandler.isNegativeFeedback(recentMessages[i]['content'])) {
            searchTopic = recentMessages[i]['content'];
            print('Using full recent message as topic: ${searchTopic.substring(0, math.min(50, searchTopic.length))}...');
            break;
          }
        }
      }
      
      // If we still don't have a valid search topic, return empty list
      if (searchTopic.isEmpty) {
        print('Could not determine search topic for better videos');
        return [];
      }
      
      // Make the search more specific by adding tutorial-related keywords
      final enhancedQuery = BotModel.refineVideoSearchQuery(searchTopic, ['tutorial', 'guide', 'how to']);
      print('Searching for better videos with query: $enhancedQuery');
      
      // Search for videos with the enhanced query
      return await _youtubeService.searchVideos(enhancedQuery);
    } catch (e) {
      print('Error finding better videos: $e');
      return [];
    }
  }
} 