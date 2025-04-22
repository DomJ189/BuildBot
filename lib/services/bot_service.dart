import 'dart:convert';
import 'package:http/http.dart' as http;
import 'youtube_service.dart';
import 'dart:math' as Math;

// Handles communication with the Perplexity AI API for generating responses
class BotService {
  // Change from final to non-final to allow modification
  String apiKey; 
  final List<Map<String, dynamic>> _conversationHistory = []; // Stores conversation history
  final YouTubeService _youtubeService = YouTubeService();

  // Constructor to initialize the BotService with the provided API key
  BotService(this.apiKey) {
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
    _conversationHistory.clear();
  }

  // Fetches a response from the Perplexity AI API based on the provided prompt
  Future<String> fetchResponse(String prompt) async {
    try {
      // Add user message to history
      _conversationHistory.add({'role': 'user', 'content': prompt});
      
      // Define the URL for the Perplexity API endpoint
      final url = Uri.parse('https://api.perplexity.ai/chat/completions');
      
      // Create message array with system message and conversation history
      final messages = [
        {
          'role': 'system',
          'content': 'You are a helpful PC-building maintenance and configuration assistant. Provide responses in markdown format. Maintain context from previous messages in the conversation.' 
        },
        // Add all conversation history
        ..._conversationHistory,
      ];
      
      // Send a POST request to the Perplexity API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Specify the content type
          'Authorization': 'Bearer $apiKey', // Include the API key in the authorization header
        },
        body: jsonEncode({
          'model': 'sonar', // Updated to a valid Perplexity model
          'messages': messages,
          'temperature': 0.7, // Controls the randomness of the output
          'max_tokens': 1000, // Maximum number of tokens in the response
        }),
      );

      // Check if the response status is OK (200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); // Decode the JSON response
        final content = data['choices'][0]['message']['content'].toString().trim(); // Extract the assistant's response
        
        // Add bot response to history
        _conversationHistory.add({'role': 'assistant', 'content': content});
        
        // Limit history length to prevent token overflow (keep last 10 messages)
        if (_conversationHistory.length > 10) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 10);
        }
        
        return _removeCitations(content); // Remove citations and return
      } else {
        // Log error details if the response is not successful
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Log any exceptions that occur during the fetch process
      print('Error in fetchResponse: $e');
      throw Exception('Failed to fetch response: $e'); // Rethrow the exception for further handling
    }
  }

  // Add this method to the BotService class
  void addToConversationHistory(String role, String content) {
    _conversationHistory.add({'role': role, 'content': content});
  }

  // Add this method to detect when a user is asking for video suggestions
  bool _isAskingForVideos(String message) {
    final videoRequestPhrases = [
      'yes', 'sure', 'please', 'show me', 'i would like', 'video', 
      'tutorial', 'demonstration', 'show', 'recommend', 'suggest',
      'yes please'
    ];
    
    final lowerMessage = message.toLowerCase().trim();
    
    // Check if this is a simple affirmative response
    final simpleAffirmative = ['yes', 'yes please', 'sure', 'ok', 'okay', 'please'];
    final isSimpleResponse = simpleAffirmative.contains(lowerMessage);
    
    // Either it contains video request phrases or is a simple affirmative
    return videoRequestPhrases.any((phrase) => lowerMessage.contains(phrase)) || isSimpleResponse;
  }

  // Add this method to detect when a user is asking for more videos
  bool _isAskingForMoreVideos(String message) {
    final moreVideosRequestPhrases = [
      'more videos', 'additional videos', 'other videos', 'different videos',
      'show more', 'another video', 'got more', 'have more', 'anything else',
      'other options', 'other tutorials'
    ];
    
    final lowerMessage = message.toLowerCase();
    return moreVideosRequestPhrases.any((phrase) => lowerMessage.contains(phrase));
  }

  // Check if the message is directly asking for videos (not just a response to a suggestion)
  bool _isDirectVideoRequest(String message) {
    final directVideoRequestPhrases = [
      'show me videos', 'suggest videos', 'videos about', 'videos for', 'videos on',
      'video tutorial', 'tutorials on', 'suggest some videos', 'recommend videos',
      'can you show', 'show video', 'find videos', 'show me some'
    ];
    
    final lowerMessage = message.toLowerCase();
    return directVideoRequestPhrases.any((phrase) => lowerMessage.contains(phrase));
  }

  // Add this method to detect when a message is just conversational (like "thank you")
  bool _isConversationalResponse(String message) {
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

  // Add this method to detect when user says videos aren't helpful
  bool _isNegativeFeedbackOnVideos(String message) {
    final negativeFeedbackPhrases = [
      "those videos don't help", 
      "these videos don't help",
      "not helpful", 
      "doesn't help", 
      "not what i'm looking for",
      "wrong videos",
      "unrelated videos",
      "irrelevant",
      "not about",
      "not related",
      "not on topic"
    ];
    
    final lowerMessage = message.toLowerCase().trim();
    return negativeFeedbackPhrases.any((phrase) => lowerMessage.contains(phrase));
  }
  
  // Add a method to search for more appropriate videos after negative feedback
  Future<List<YouTubeVideo>> _tryBetterVideoSearch(String message) async {
    // Extract the original topic that user is looking for
    final topic = _extractTopicFromConversation();
    
    // Make a more specific query by extracting key words and adding specificity
    final lowerTopic = topic.toLowerCase();
    
    // Add relevant video-focused keywords based on topic patterns
    String searchQuery = topic;
    
    // Extract important words from the topic, minimum 3 chars
    final queryWords = lowerTopic.split(' ')
        .where((word) => word.length > 3)
        .toList();
    
    if (queryWords.isNotEmpty) {
      // Create a more explicit tutorial-focused query
      searchQuery = "${queryWords.join(' ')} tutorial guide";
    }
    
    // Try searching for videos with this specific query
    try {
      // Use a more direct query with tutorial keywords
      return await _youtubeService.searchVideos(searchQuery);
    } catch (e) {
      print('Error searching for better videos: $e');
      return [];
    }
  }

  // Modify the getResponseWithVideos method to handle video requests differently
  Future<Map<String, dynamic>> getResponseWithVideos(String message, List<Map<String, dynamic>> messages) async {
    try {
      // Check if this is just a conversational response (like "thank you")
      final isConversational = _isConversationalResponse(message);
      
      // Add user message to history
      if (_conversationHistory.isEmpty || 
          _conversationHistory.last['role'] != 'user' || 
          _conversationHistory.last['content'] != message) {
        
        // If the last message was also from the user, replace it
        if (_conversationHistory.isNotEmpty && _conversationHistory.last['role'] == 'user') {
          _conversationHistory.removeLast();
        }
        
        _conversationHistory.add({'role': 'user', 'content': message});
      }
      
      // Check if user is giving negative feedback about videos
      final isNegativeFeedback = _isNegativeFeedbackOnVideos(message);
      
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
        _conversationHistory.add({'role': 'assistant', 'content': response});
        
        return {
          'text': response,
          'videos': betterVideos,
        };
      }
      
      // If this is just a conversational message (like "thank you"), 
      // respond appropriately without showing videos
      if (isConversational) {
        final conversationalResponse = _generateConversationalResponse(message);
        
        // Add bot response to history
        _conversationHistory.add({'role': 'assistant', 'content': conversationalResponse});
        
        return {
          'text': conversationalResponse,
          'videos': <YouTubeVideo>[],
        };
      }
      
      // Check for direct video requests like "show me video reviews of it"
      bool isExplicitVideoRequest = _isDirectVideoRequest(message);
      
      // Extract video search topic from message or previous conversation
      String videoSearchTopic;
      if (isExplicitVideoRequest) {
        // If requesting videos about a previously discussed topic ("show me reviews of it")
        // Extract topic from previous message that's being referenced
        String extractedTopic = _extractReferenceTopicFromMessage(message);
        if (extractedTopic.isNotEmpty) {
          videoSearchTopic = extractedTopic;
        } else {
          // Extract the topic directly from the message if possible
          videoSearchTopic = _extractTopicFromMessage(message);
        }
        
        // Perform video search with appropriate query
        List<YouTubeVideo> videos = [];
        try {
          // Clean up search query and make it more specific
          String searchQuery = _refineVideoSearchQuery(videoSearchTopic, message);
          videos = await _youtubeService.searchVideos(searchQuery);
          print('Fetched ${videos.length} videos for query: $searchQuery');
        } catch (e) {
          print('Error fetching videos: $e');
        }
        
        // Create a response with videos
        String videoResponse;
        if (videos.isEmpty) {
          videoResponse = "I couldn't find any relevant videos on this topic.";
        } else {
          videoResponse = "Here are some video reviews that should help:";
        }
        
        // Add bot response to history
        _conversationHistory.add({'role': 'assistant', 'content': videoResponse});
        
        return {
          'text': videoResponse,
          'videos': videos,
        };
      }
      
      // Check for more videos request
      bool isMoreVideosRequest = _isAskingForMoreVideos(message);
      
      // Check if this is a direct video request or a response to a video suggestion
      bool isResponseToSuggestion = false;
      
      if (_conversationHistory.length >= 2 && !isExplicitVideoRequest) {
        String previousBotMessage = '';
        for (int i = _conversationHistory.length - 2; i >= 0; i--) {
          if (_conversationHistory[i]['role'] == 'assistant') {
            previousBotMessage = _conversationHistory[i]['content'] ?? '';
            break;
          }
        }
        isResponseToSuggestion = _isAskingForVideos(message) && _containsVideoSuggestion(previousBotMessage);
      }
      
      // Handle direct video requests or responses to video suggestions
      if (isMoreVideosRequest || isResponseToSuggestion) {
        // Generate a search query based on the previous conversation
        final topic = _extractTopicFromConversation();
        String videoQuery;
        
        if (isMoreVideosRequest) {
          // For more videos request, try to use a different but related query
          videoQuery = _generateAlternativeVideoSearchQuery(topic);
        } else {
          videoQuery = _generateVideoSearchQuery(topic);
        }
        
        List<YouTubeVideo> videos = [];
        try {
          videos = await _youtubeService.searchVideos(videoQuery);
          print('Fetched ${videos.length} videos for query: $videoQuery');
        } catch (e) {
          print('Error fetching videos: $e');
        }
        
        // Create a response with videos
        String videoResponse;
        if (videos.isEmpty) {
          videoResponse = "I couldn't find any relevant videos on this topic.";
        } else if (isMoreVideosRequest) {
          videoResponse = "Absolutely! Here are some more videos on the topic:";
        } else if (isExplicitVideoRequest) {
          // Check if this is a comparison query
          if (_isComparisonQuery(topic)) {
            videoResponse = "Here are some videos comparing these components:";
          } else {
            videoResponse = "Here are some video tutorials related to your request:";
          }
        } else {
          videoResponse = "Here are some video tutorials that might help with ${topic.substring(0, topic.length > 50 ? 50 : topic.length)}:";
        }
        
        // Add bot response to history
        _conversationHistory.add({'role': 'assistant', 'content': videoResponse});
        
        return {
          'text': videoResponse,
          'videos': videos,
        };
      }
      
      // Regular response flow for non-video requests
      // Define the URL for the Perplexity API endpoint
      final url = Uri.parse('https://api.perplexity.ai/chat/completions');
      
      // Create message array with system message and conversation history
      final apiMessages = [
        {
          'role': 'system',
          'content': 'You are a helpful PC-building maintenance and configuration assistant. '
              'Provide responses in markdown format. Maintain context from previous messages in the conversation. '
              'When appropriate, proactively ask if the user would like to see video tutorials or demonstrations '
              'related to their question. For example, after explaining how to install Windows, you might say '
              '"Would you like me to suggest some video tutorials that demonstrate this process?" or '
              '"I can recommend some videos that show this in action if you\'d like to see a visual demonstration."'
        },
        // Add all conversation history
        ..._conversationHistory,
      ];
      
      // Send a POST request to the Perplexity API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Specify the content type
          'Authorization': 'Bearer $apiKey', // Include the API key in the authorization header
        },
        body: jsonEncode({
          'model': 'sonar', // Updated to a valid Perplexity model
          'messages': apiMessages,
          'temperature': 0.7, // Controls the randomness of the output
          'max_tokens': 1000, // Maximum number of tokens in the response
        }),
      );

      // Check if the response status is OK (200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); // Decode the JSON response
        final content = data['choices'][0]['message']['content'].toString().trim(); // Extract the assistant's response
        
        // Add bot response to history
        _conversationHistory.add({'role': 'assistant', 'content': content});
        
        // Limit history length to prevent token overflow (keep last 10 messages)
        if (_conversationHistory.length > 10) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 10);
        }
        
        // Determine if we should suggest videos based on the message content
        bool shouldSuggestVideos = _shouldSuggestVideos(content);
        
        String processedContent = content;
        
        // Check if we've already suggested videos in the last few messages
        bool alreadySuggestedVideos = false;
        int checkCount = Math.min(5, _conversationHistory.length);
        for (int i = 0; i < checkCount; i++) {
          if (_conversationHistory.length > i && 
              _conversationHistory[_conversationHistory.length - 1 - i]['role'] == 'assistant' &&
              _containsVideoSuggestion(_conversationHistory[_conversationHistory.length - 1 - i]['content'] ?? '')) {
            alreadySuggestedVideos = true;
            break;
          }
        }
        
        // Only add video suggestion if:
        // 1. We think videos would be helpful
        // 2. The content doesn't already contain a video suggestion
        // 3. We haven't recently suggested videos
        // 4. The content doesn't already contain recommendations for videos
        if (shouldSuggestVideos && 
            !_containsVideoSuggestion(processedContent) && 
            !alreadySuggestedVideos &&
            !_containsVideoRecommendation(processedContent)) {
          processedContent += "\n\nWould you like me to suggest some video tutorials that demonstrate this in more detail?";
        }
        
        // Important change: Don't include videos in the initial response
        return {
          'text': _removeCitations(processedContent),
          'videos': <YouTubeVideo>[],
        };
      } else {
        // Log error details if the response is not successful
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch response: ${response.statusCode} - ${response.body}');
      }
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

  // Update this method in BotService
  void initializeConversationHistory(List<Map<String, dynamic>> messages) {
    _conversationHistory.clear();
    
    // Make sure messages alternate between user and assistant
    String lastRole = "";
    for (var message in messages) {
      String role = message['sender'] == 'user' ? 'user' : 'assistant';
      
      // Skip consecutive messages with the same role
      if (role == lastRole) {
        continue;
      }
      
      _conversationHistory.add({
        'role': role,
        'content': message['message'] ?? '',
      });
      
      lastRole = role;
    }
    
    // Ensure the conversation history ends with a user message
    if (_conversationHistory.isNotEmpty && 
        _conversationHistory.last['role'] == 'assistant') {
      _conversationHistory.removeLast();
    }
  }
  
  // Helper method to determine if we should suggest videos
  bool _shouldSuggestVideos(String message) {
    // Keywords that might indicate the user wants to see a demonstration
    final videoKeywords = [
      'how to', 'tutorial', 'guide', 'show me', 'demonstrate', 'video',
      'watch', 'build', 'install', 'setup', 'assemble', 'put together',
      'demonstration', 'example', 'explain'
    ];
    
    final lowerMessage = message.toLowerCase();
    
    // Check if any of the keywords are in the message
    return videoKeywords.any((keyword) => lowerMessage.contains(keyword));
  }
  
  // Helper method to generate a good YouTube search query
  String _generateVideoSearchQuery(String message) {
    // Extract key terms from the message
    final lowerMessage = message.toLowerCase();
    
    // First check for generic hardware component comparison
    final hardwareComponents = _extractHardwareComponents(lowerMessage);
    
    // If we have detected multiple hardware components for comparison
    if (hardwareComponents.length >= 2) {
      // Use more generic comparison query format
      return '${hardwareComponents.join(' vs ')} comparison review';
    }
    
    // Check for comparison intent using more general comparison phrases
    final comparisonMatches = RegExp(r'(compare|comparison|difference|versus|vs|or|between)\s+(\w+(\s+\w+){0,3})\s+(and|vs|versus|or|with|to)\s+(\w+(\s+\w+){0,3})').allMatches(lowerMessage);
    if (comparisonMatches.isNotEmpty) {
      // Extract the full comparison phrase
      final match = comparisonMatches.first;
      if (match.groupCount >= 5) {
        final component1 = match.group(2)?.trim() ?? '';
        final component2 = match.group(5)?.trim() ?? '';
        if (component1.isNotEmpty && component2.isNotEmpty) {
          return '$component1 vs $component2 comparison';
        }
      }
      
      return '${comparisonMatches.first.group(0)} comparison';
    }
    
    // PC building specific terms to look for
    final pcTerms = [
      'pc build', 'computer build', 'gaming pc', 'workstation',
      'motherboard', 'cpu', 'gpu', 'graphics card', 'ram', 'memory',
      'storage', 'ssd', 'hdd', 'power supply', 'psu', 'cooling', 'case',
      'cable management', 'overclocking', 'bios', 'windows', 'linux',
      'hackintosh', 'water cooling', 'air cooling', 'rgb', 'budget',
      'high-end', 'mid-range', 'troubleshooting', 'rtx', 'nvidia',
      'amd', 'intel', 'radeon', 'geforce', 'ryzen'
    ];
    
    // Find matching PC terms in the message
    final matchingTerms = pcTerms.where((term) => lowerMessage.contains(term)).toList();
    
    // If we found specific PC terms, use them to create a more targeted query
    if (matchingTerms.isNotEmpty) {
      return '${matchingTerms.join(' ')} tutorial';
    }
    
    // If no specific terms found, use a more general query based on the message
    // Remove common words and limit length
    final words = message.split(' ')
        .where((word) => word.length > 3)  // Only words longer than 3 chars
        .take(6)  // Take at most 6 words
        .join(' ');
    
    return 'pc building tutorial $words';
  }
  
  // Generate an alternative query for "more videos" requests
  String _generateAlternativeVideoSearchQuery(String message) {
    final lowerMessage = message.toLowerCase();
    
    // First check for generic hardware component comparison
    final hardwareComponents = _extractHardwareComponents(lowerMessage);
    
    // If we have detected multiple hardware components for comparison
    if (hardwareComponents.length >= 2) {
      // Use alternative comparison format for variety
      return '${hardwareComponents.join(' vs ')} performance benchmark';
    }
    
    // Check for comparison intent using more general comparison phrases
    final comparisonMatches = RegExp(r'(compare|comparison|difference|versus|vs|or|between)\s+(\w+(\s+\w+){0,3})\s+(and|vs|versus|or|with|to)\s+(\w+(\s+\w+){0,3})').allMatches(lowerMessage);
    if (comparisonMatches.isNotEmpty) {
      // Extract the full comparison phrase
      final match = comparisonMatches.first;
      if (match.groupCount >= 5) {
        final component1 = match.group(2)?.trim() ?? '';
        final component2 = match.group(5)?.trim() ?? '';
        if (component1.isNotEmpty && component2.isNotEmpty) {
          return '$component1 vs $component2 performance review';
        }
      }
      
      return '${comparisonMatches.first.group(0)} real world test';
    }
    
    // Extract most specific terms
    final pcTerms = [
      'rtx', 'gpu', 'graphics card', 'cpu', 'processor', 'motherboard',
      'ram', 'memory', 'storage', 'ssd', 'hdd', 'power supply', 'psu',
      'cooling', 'case', 'cabinet', 'chassis', 'fan', 'heatsink', 'aio',
      'water cooler', 'monitor', 'display', 'keyboard', 'mouse',
      'headphones', 'speakers', 'microphone', 'webcam',
      'gaming pc', 'workstation', 'desktop', 'laptop', 'keyboard',
      'mouse', 'gamepad', 'controller', 'console', 'ryzen', 'intel',
      'nvidia', 'amd', 'corsair', 'asus', 'msi', 'gigabyte', 'evga',
      'nzxt', 'cooler master', 'fractal design', 'thermaltake',
      'seasonic', 'be quiet', 'crucial', 'kingston', 'samsung',
      'western digital', 'seagate', 'toshiba'
    ];
    
    // Find matching terms
    for (final term in pcTerms) {
      if (lowerMessage.contains(term)) {
        return '$term detailed review guide';
      }
    }
    
    // Default alternative query - add "detailed guide" instead of "tutorial"
    final baseQuery = _generateVideoSearchQuery(message);
    return baseQuery.replaceAll('tutorial', 'detailed guide');
  }

  // Extract hardware components from a message for comparison
  List<String> _extractHardwareComponents(String message) {
    final List<String> components = [];
    final lowerMessage = message.toLowerCase();
    
    // Common hardware component categories and their synonyms
    final componentCategories = {
      'gpu': ['gpu', 'graphics card', 'graphics processor', 'video card', 'rtx', 'gtx', 'rx'],
      'cpu': ['cpu', 'processor', 'ryzen', 'intel', 'core', 'threadripper', 'x3d'],
      'motherboard': ['motherboard', 'mobo', 'mainboard'],
      'ram': ['ram', 'memory', 'ddr4', 'ddr5'],
      'storage': ['storage', 'ssd', 'hdd', 'nvme', 'm.2', 'hard drive'],
      'psu': ['psu', 'power supply'],
      'case': ['case', 'pc case', 'computer case', 'chassis', 'cabinet'],
      'cooling': ['cooler', 'cooling', 'fan', 'heatsink', 'radiator', 'aio'],
      'monitor': ['monitor', 'display', 'screen'],
      'peripheral': ['keyboard', 'mouse', 'headset', 'speakers', 'microphone']
    };
    
    // Step 1: Try to find specific component mentions first (like "RTX 3080")
    // Common hardware model patterns (number+letters)
    final specificModels = RegExp(r'\b([a-zA-Z]+[-\s]?\d+\s?[a-zA-Z]*\d*|[a-zA-Z]*\d+\s?[a-zA-Z]+\d*)\b')
        .allMatches(lowerMessage)
        .map((m) => m.group(0)!)
        .toList();
    
    components.addAll(specificModels);
    
    // Step 2: If we have fewer than 2 specific components, look for component categories
    if (components.length < 2) {
      for (final entry in componentCategories.entries) {
        for (final term in entry.value) {
          if (lowerMessage.contains(term) && !components.contains(entry.key)) {
            components.add(entry.key);
            break;
          }
        }
        
        // Stop once we have at least 2 components
        if (components.length >= 2) break;
      }
    }
    
    // Return unique components, with a maximum of 2 to keep searches focused
    return components.take(2).toList();
  }

  // In the _formatVideoResponse method or where you format the response
  String _formatVideoResponse(List<YouTubeVideo> videos) {
    if (videos.isEmpty) return "";
    
    StringBuffer response = StringBuffer();
    
    for (int i = 0; i < videos.length; i++) {
      final video = videos[i];
      response.writeln("${i+1}. ${video.title}");
      response.writeln("   by ${video.channelTitle}");
      if (i < videos.length - 1) {
        response.writeln("");
      }
    }
    
    return response.toString();
  }

  // Add helper method to check if content already has a video suggestion
  bool _containsVideoSuggestion(String content) {
    final videoSuggestionPhrases = [
      'would you like to see',
      'would you like me to suggest',
      'i can recommend some videos',
      'would you like video tutorials',
      'want to see a video',
      'visual demonstration',
      'here are some video tutorials',
      'would you like some guidance',
      'would you be interested in',
      'would you like me to recommend',
      'perhaps you\'d like to see',
      'would you like me to show you'
    ];
    
    final lowerContent = content.toLowerCase();
    return videoSuggestionPhrases.any((phrase) => lowerContent.contains(phrase));
  }
  
  // Add helper method to check if content already contains specific video recommendations
  bool _containsVideoRecommendation(String content) {
    final videoRecommendationPhrases = [
      'here are some video',
      'i can also suggest some video',
      'perhaps you\'d be interested in video',
      'i could suggest video',
      'i can recommend video',
      'some video tutorials that demonstrate',
      'video tutorials that show',
      'recommend some videos',
      'recommend video tutorials',
      'suggest some videos',
      'suggest video tutorials'
    ];
    
    final lowerContent = content.toLowerCase();
    return videoRecommendationPhrases.any((phrase) => lowerContent.contains(phrase));
  }

  // Helper method to extract the main topic from conversation
  String _extractTopicFromConversation() {
    // Find the most relevant topic - check the last few exchanges
    // Start with user messages before the "yes" to video request
    String topic = "PC building";
    
    // First, check if the current message is a feedback on previous videos
    String currentMessage = _conversationHistory.last['content'] ?? '';
    final lowerCurrentMessage = currentMessage.toLowerCase();
    final isVideoFeedback = lowerCurrentMessage.contains("those videos don't help") || 
                           lowerCurrentMessage.contains("these videos don't help") ||
                           lowerCurrentMessage.contains("not helpful") ||
                           lowerCurrentMessage.contains("doesn't help") ||
                           lowerCurrentMessage.contains("not what i'm looking for");
    
    // If user is saying the videos don't help, look back for the original request
    if (isVideoFeedback) {
      String originalQuery = "";
      
      // Go back through conversation to find what the user originally asked about
      for (int i = 0; i < _conversationHistory.length - 1; i++) {
        final message = _conversationHistory[i];
        if (message['role'] == 'user' && 
            message['content'].toString().length > 10 &&
            !_isSimpleVideoRequest(message['content'].toString())) {
          originalQuery = message['content'].toString();
          break;
        }
      }
      
      if (originalQuery.isNotEmpty) {
        return originalQuery;
      }
    }
    
    // Check if current message is asking for more videos
    if (_isAskingForMoreVideos(currentMessage)) {
      // For "more videos" requests, we need to find the original topic
      // Look back further in conversation for meaningful content
      for (int i = _conversationHistory.length - 3; i >= 0; i--) {
        final message = _conversationHistory[i];
        final content = message['content'] ?? '';
        
        // Skip short responses and look for meaningful queries
        if (message['role'] == 'user' && 
            content.length > 10 && 
            !_isSimpleVideoRequest(content) &&
            !_isAskingForVideos(content)) {
          return content;
        }
      }
    }
    
    // For simple responses like "yes please" or "show me videos", look for the topic in previous bot messages
    if (_isSimpleVideoRequest(currentMessage)) {
      // Find the most recent bot message that suggests videos
      for (int i = _conversationHistory.length - 2; i >= 0; i--) {
        final message = _conversationHistory[i];
        if (message['role'] == 'assistant') {
          final content = message['content'] ?? '';
          
          // Check if this message was suggesting videos about a specific topic
          if (_containsVideoSuggestion(content)) {
            // Now find the user query that prompted this response
            if (i > 0 && _conversationHistory[i-1]['role'] == 'user') {
              final userQuery = _conversationHistory[i-1]['content'] ?? '';
              if (userQuery.length > 10 && !_isSimpleVideoRequest(userQuery)) {
                return userQuery;
              }
            }
          }
        }
      }
    }
    
    // General case: look back through conversation history for user content
    for (int i = _conversationHistory.length - 1; i >= 0; i--) {
      final message = _conversationHistory[i];
      final content = message['content'] ?? '';
      
      // Skip the "yes" message or short responses
      if (message['role'] == 'user' && 
          content.length > 5 && 
          !_isSimpleVideoRequest(content)) {
        return content;
      }
    }
    
    return topic; // Fallback
  }
  
  // Helper to detect simple "yes" responses
  bool _isSimpleVideoRequest(String message) {
    final simpleResponses = ['yes', 'sure', 'ok', 'okay', 'please', 'yes please'];
    final lowerMessage = message.toLowerCase().trim();
    return simpleResponses.contains(lowerMessage);
  }

  // Check if a string contains a comparison query
  bool _isComparisonQuery(String message) {
    final comparisonTerms = [
      ' vs ', ' versus ', ' or ', ' compared to ', ' difference between ',
      ' better than ', 'comparison', 'differences', 'which is better'
    ];
    
    final lowerMessage = message.toLowerCase();
    
    // Check for specific comparison terms
    final hasComparisonTerms = comparisonTerms.any((term) => lowerMessage.contains(term));
    
    // Check for multiple hardware components being mentioned (implicit comparison)
    final components = _extractHardwareComponents(lowerMessage);
    final hasMultipleComponents = components.length >= 2;
    
    return hasComparisonTerms || hasMultipleComponents;
  }

  // Generate appropriate responses for conversational messages
  String _generateConversationalResponse(String message) {
    final lowerMessage = message.toLowerCase().trim();
    
    // Thank you responses
    if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      return "You're welcome! Is there anything else you'd like to know about PC building or hardware?";
    }
    
    // Affirmative responses (ok, got it, etc.)
    if (lowerMessage.contains('ok') || lowerMessage.contains('got it') || 
        lowerMessage == 'sure' || lowerMessage == 'alright' || 
        lowerMessage.contains('understood')) {
      return "Great! Let me know if you need any more information or have other questions.";
    }
    
    // Goodbye responses
    if (lowerMessage.contains('bye') || lowerMessage.contains('goodbye') || 
        lowerMessage.contains('see you') || lowerMessage.contains('talk later')) {
      return "Goodbye! Feel free to come back if you have more questions about PC building or hardware.";
    }
    
    // Default response for other conversational phrases
    return "Is there anything else you'd like to know about PC components or building a computer?";
  }

  // Add a method to extract topic from a reference (like "show me videos of it")
  String _extractReferenceTopicFromMessage(String message) {
    // First, check if the message contains reference words
    final lowerMessage = message.toLowerCase();
    final hasReference = lowerMessage.contains(" it ") || 
                         lowerMessage.contains(" this ") || 
                         lowerMessage.endsWith(" it") ||
                         lowerMessage.endsWith(" these") ||
                         lowerMessage.endsWith(" that");
    
    if (!hasReference) {
      return "";
    }
    
    // Check recent conversation history for topics being discussed
    String potentialTopic = "";
    
    // Look for recent bot responses and user queries for context
    for (int i = _conversationHistory.length - 1; i >= 0; i--) {
      final entry = _conversationHistory[i];
      
      // Skip current user message
      if (i == _conversationHistory.length - 1) continue;
      
      final role = entry['role'];
      final content = entry['content'] ?? '';
      
      // Check bot messages for product mentions (GPUs, CPUs, etc.)
      if (role == 'assistant' && content.isNotEmpty) {
        // Check for GPU model mentions (RTX, GTX, etc.)
        final gpuMatches = RegExp(r'(?:RTX|GTX|RX)\s+\d{4}(?:\s+[A-Za-z]+)?', caseSensitive: false).allMatches(content);
        if (gpuMatches.isNotEmpty) {
          final model = gpuMatches.first.group(0);
          if (model != null) {
            return "$model review";
          }
        }
        
        // Check for CPU model mentions
        final cpuMatches = RegExp(r'(?:Core i[3579]|Ryzen [3579]|Threadripper)\s+\d{4}(?:X|XT)?', caseSensitive: false).allMatches(content);
        if (cpuMatches.isNotEmpty) {
          final model = cpuMatches.first.group(0);
          if (model != null) {
            return "$model review";
          }
        }
        
        // Look for section headings in markdown as they often contain the main topic
        final headingMatches = RegExp(r'##\s+(.*?)$', multiLine: true).allMatches(content);
        if (headingMatches.isNotEmpty) {
          final heading = headingMatches.first.group(1)?.trim();
          if (heading != null && heading.isNotEmpty) {
            // Use heading as topic but remove any "Review" text that might be there
            return heading.replaceAll(RegExp(r'Review', caseSensitive: false), '').trim();
          }
        }
      }
      
      // Check user messages for product-related questions
      if (role == 'user' && content.length > 10) {
        // Extract hardware model numbers using regex
        final modelMatches = RegExp(r'(?:RTX|GTX|RX|Core i[3579]|Ryzen [3579])\s+\d{4}(?:\s+[A-Za-z]+)?', caseSensitive: false).allMatches(content);
        if (modelMatches.isNotEmpty) {
          final model = modelMatches.first.group(0);
          if (model != null) {
            return "$model review";
          }
        }
        
        // If we can't find specific model numbers, use the full user query
        // But only if it has substance (not just "show me videos")
        if (!_isDirectVideoRequest(content) && !_isSimpleVideoRequest(content)) {
          return content;
        }
      }
    }
    
    return potentialTopic;
  }
  
  // Extract specific topic from a video request message
  String _extractTopicFromMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Try to find hardware product mentions first (GPUs, CPUs, etc.)
    final hardwareMatches = RegExp(r'(?:rtx|gtx|rx|radeon|core i[3579]|ryzen|threadripper)\s+\d{4}(?:\s+[a-z]+)?', caseSensitive: false).allMatches(lowerMessage);
    if (hardwareMatches.isNotEmpty) {
      final model = hardwareMatches.first.group(0);
      if (model != null) {
        return "$model review";
      }
    }
    
    // Try to extract specific topic using regex patterns
    final patterns = [
      // Pattern for "show me videos of X"
      RegExp(r'show me (?:videos|video|reviews|review) (?:of|about|on|for) (.*?)(?:$|\?|\.|,)', caseSensitive: false),
      // Pattern for "X videos/reviews"
      RegExp(r'(.*?)(?:videos|video|reviews|review)(?:$|\?|\.|,)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(lowerMessage);
      if (matches.isNotEmpty && matches.first.groupCount >= 1) {
        final match = matches.first.group(1)?.trim();
        if (match != null && match.isNotEmpty) {
          // Extract any hardware terms from the match
          if (_containsHardwareTerms(match)) {
            // If it contains hardware terms, add "review" to get better search results
            if (!match.contains('review')) {
              return "$match review";
            }
          }
          return match;
        }
      }
    }
    
    // If no specific topic found but mentions the word "review"
    if (lowerMessage.contains("review") || lowerMessage.contains("reviews")) {
      // Default to most recently discussed topic
      return _extractTopicFromConversation();
    }
    
    // Try to extract general components if mentioned in message
    final components = _extractHardwareComponents(lowerMessage);
    if (components.isNotEmpty) {
      return "${components.join(' ')} review";
    }
    
    return "PC building tutorial";
  }
  
  // Checks if text contains hardware-related terms
  bool _containsHardwareTerms(String text) {
    final hardwareTerms = [
      'cpu', 'gpu', 'processor', 'graphics card', 'motherboard',
      'ram', 'memory', 'ssd', 'hdd', 'storage', 'psu', 'power supply',
      'cooler', 'cooling', 'rtx', 'gtx', 'rx', 'radeon', 'geforce',
      'ryzen', 'intel', 'amd', 'nvidia', 'x3d', 'case', 'fan',
      'cabinet', 'chassis', 'heatsink', 'thermal', 'ddr4', 'ddr5',
      'nvme', 'm.2', 'sata', 'monitor', 'display', 'screen'
    ];
    
    final lowerText = text.toLowerCase();
    return hardwareTerms.any((term) => lowerText.contains(term));
  }
  
  // Refine video search query based on message content
  String _refineVideoSearchQuery(String topic, String originalMessage) {
    final lowerMessage = originalMessage.toLowerCase();
    final lowerTopic = topic.toLowerCase();
    
    // If topic already has review/tutorial/guide keywords, leave it as is
    if (lowerTopic.contains("review") || 
        lowerTopic.contains("tutorial") || 
        lowerTopic.contains("guide")) {
      return topic;
    }
    
    // Handle different request types based on the message
    if (lowerMessage.contains("review")) {
      return "$topic review";
    } else if (lowerMessage.contains("tutorial") || lowerMessage.contains("guide")) {
      return "$topic tutorial";
    } else if (lowerMessage.contains("comparison") || lowerMessage.contains("vs") || lowerMessage.contains("versus")) {
      return "$topic comparison";
    } else if (lowerMessage.contains("benchmark") || lowerMessage.contains("performance")) {
      return "$topic benchmark";
    } else if (lowerMessage.contains("teardown") || lowerMessage.contains("disassembly")) {
      return "$topic teardown";
    } else if (lowerMessage.contains("unboxing")) {
      return "$topic unboxing";
    }
    
    // Default: if we're talking about hardware and nothing specific was requested,
    // a review is probably the most useful
    if (_containsHardwareTerms(topic)) {
      return "$topic review";
    }
    
    return topic;
  }
} 