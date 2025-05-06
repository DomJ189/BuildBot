import 'dart:convert';
import 'package:http/http.dart' as http;
import 'youtube_service.dart';
import 'tech_news_service.dart';
import 'reddit_service.dart';
import 'gpu_recommendation_service.dart';
import 'dart:math' as math;
import '../models/reddit_post.dart';
import '../models/youtube_video.dart';
import '../models/conversation_manager.dart';
import '../models/content_request_handler.dart';
import '../models/conversational_response_handler.dart';
import '../models/bot_model.dart';
import '../models/gpu_model.dart';

// Handles communication with the Perplexity AI API for generating responses
class BotService {
  // Change from final to non-final to allow modification
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
    _initializeApiKey();
  }

  void _initializeApiKey() {
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
  }

  // Initialize conversation history from external messages
  void initialiseConversationHistory(List<Map<String, dynamic>> messages) {
    _conversation.initializeFrom(messages);
  }

  // Enhanced fetchResponse method to include tech news, Reddit troubleshooting, and GPU recommendations
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
      final url = Uri.parse('https://api.perplexity.ai/chat/completions');
    final body = jsonEncode({
      'model': 'sonar',
      'messages': [
        {'role': 'system', 'content': systemMessage},
        ...messages,
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
        return {
        'content': data['choices'][0]['message']['content'].toString().trim(),
        };
      } else {
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch response: ${response.statusCode} - ${response.body}');
    }
  }

  // Modify the getResponseWithVideos method to handle video requests differently
  Future<Map<String, dynamic>> getResponseWithVideos(String message, List<Map<String, dynamic>> messages) async {
    try {
      // Check if this is just a conversational response (like "thank you")
      final isConversational = ConversationalResponseHandler.isConversational(message);
      
      // Add user message to history
      _conversation.addMessage('user', message);
      
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
          response = "I apologize those videos weren't helpful. Here are some more specific videos that should better address your question:";
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

  // Try a better video search after negative feedback
  Future<List<YouTubeVideo>> _tryBetterVideoSearch(String message) async {
    // Extract the original topic that user is looking for
    final topic = _extractTopicFromConversation();
    
    if (topic.isEmpty) return [];
    
    // Create a more specific search query with tutorial keywords
    final searchQuery = BotModel.refineVideoSearchQuery(topic, ['tutorial', 'guide', 'detailed']);
    
    // Try searching for videos with this specific query
    try {
      return await _youtubeService.searchVideos(searchQuery);
    } catch (e) {
      print('Error searching for better videos: $e');
      return [];
    }
  }
} 