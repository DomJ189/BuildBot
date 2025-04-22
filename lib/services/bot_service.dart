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
      'tutorial', 'demonstration', 'show', 'recommend', 'suggest'
    ];
    
    final lowerMessage = message.toLowerCase();
    return videoRequestPhrases.any((phrase) => lowerMessage.contains(phrase));
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
      
      // If this is just a conversational message (like "thank you"), 
      // respond appropriately without showing videos
      if (isConversational) {
        final conversationalResponse = _generateConversationalResponse(message);
        
        // Add bot response to history
        _conversationHistory.add({'role': 'assistant', 'content': conversationalResponse});
        
        return {
          'text': conversationalResponse,
          'videos': <YouTubeVideo>[], // No videos for conversational responses
        };
      }
      
      // Check for more videos request
      bool isMoreVideosRequest = _isAskingForMoreVideos(message);
      
      // Check if this is a direct video request or a response to a video suggestion
      bool isVideoRequest = _isDirectVideoRequest(message);
      bool isResponseToSuggestion = false;
      
      if (_conversationHistory.length >= 2 && !isVideoRequest) {
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
      if (isVideoRequest || isMoreVideosRequest || isResponseToSuggestion) {
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
        } else if (isVideoRequest) {
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
        
        // Only add video suggestion if we haven't recently suggested videos
        if (shouldSuggestVideos && !_containsVideoSuggestion(processedContent) && !alreadySuggestedVideos) {
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
      'here are some video tutorials'
    ];
    
    final lowerContent = content.toLowerCase();
    return videoSuggestionPhrases.any((phrase) => lowerContent.contains(phrase));
  }

  // Helper method to extract the main topic from conversation
  String _extractTopicFromConversation() {
    // Find the most relevant topic - check the last few exchanges
    // Start with user messages before the "yes" to video request
    String topic = "PC building";
    
    // First check current message for specific queries
    String currentMessage = _conversationHistory.last['content'] ?? '';
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
    
    // Look back through conversation history for user content
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
} 