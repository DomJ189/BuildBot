import '../models/reddit_post.dart';

/// Handles data processing and extraction for bot responses
class BotModel {
  // Extract topic from message text
  static String extractTopicFromMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Look for phrases like "videos about X" or "show me videos about X"
    final aboutMatch = RegExp(r'(?:videos?|tutorials?)\s+(?:about|on|for|of)\s+([\w\s]+)', caseSensitive: false)
        .firstMatch(lowerMessage);
    
    if (aboutMatch != null && aboutMatch.groupCount >= 1) {
      final topic = aboutMatch.group(1);
      if (topic != null && topic.length > 3) {
        return topic.trim();
      }
    }
    
    // Look for phrases like "show me some videos about X"
    final someVideosAboutMatch = RegExp(r'show\s+(?:me\s+)?some\s+videos?\s+(?:about|on|for|of)\s+([\w\s]+)', caseSensitive: false)
        .firstMatch(lowerMessage);
        
    if (someVideosAboutMatch != null && someVideosAboutMatch.groupCount >= 1) {
      final topic = someVideosAboutMatch.group(1);
      if (topic != null && topic.length > 3) {
        return topic.trim();
      }
    }
    
    // Look for phrases like "show me X videos"
    final showMatch = RegExp(r'show\s+(?:me|some)\s+([\w\s]+)\s+(?:videos?|tutorials?)', caseSensitive: false)
        .firstMatch(lowerMessage);
    
    if (showMatch != null && showMatch.groupCount >= 1) {
      final topic = showMatch.group(1);
      if (topic != null && topic.length > 3) {
        // Filter out the word "some" from the extracted topic
        final cleanedTopic = topic.replaceAll(RegExp(r'(?:^|\s)some(?:\s|$)', caseSensitive: false), ' ').trim();
        if (cleanedTopic.length > 3) {
          return cleanedTopic;
        }
      }
    }
    
    // Extract hardware components for comparison
    final hardwareComponents = extractHardwareComponents(lowerMessage);
    if (hardwareComponents.length >= 2) {
      return '${hardwareComponents.join(' vs ')} comparison';
    }
    
    // Fall back to the entire message, but exclude common phrases
    String cleanedMessage = lowerMessage
        .replaceAll('show me videos', '')
        .replaceAll('show videos', '')
        .replaceAll('find videos', '')
        .replaceAll('videos about', '')
        .replaceAll('videos on', '')
        .replaceAll('tutorials on', '')
        .replaceAll('show me some videos', '')
        .replaceAll('some videos', '')
        .replaceAll('please', '')
        .trim();
        
    if (cleanedMessage.length > 5) {
      return cleanedMessage;
    }
    
    return '';
  }

  // Extract hardware components from a message
  static List<String> extractHardwareComponents(String message) {
    final hardwareComponents = <String>[];
    
    // Common PC hardware components
    final componentPatterns = [
      r'(?:nvidia|rtx|gtx)\s+\d+\w*', // NVIDIA GPUs
      r'radeon\s+(?:rx|r\d)\s+\d+\w*', // AMD GPUs
      r'(?:ryzen|intel)\s+(?:i\d|r\d|i\d-\d+\w*|r\d-\d+\w*)', // CPUs
      r'(?:ddr\d)\s+\d+\s*gb', // RAM
      r'\d+\s*(?:gb|tb)\s+(?:ssd|hdd|nvme)', // Storage
    ];
    
    for (var pattern in componentPatterns) {
      final matches = RegExp(pattern, caseSensitive: false).allMatches(message);
      for (var match in matches) {
        hardwareComponents.add(match.group(0) ?? '');
      }
    }
    
    return hardwareComponents;
  }

  // Removes citation numbers in square brackets from text
  static String removeCitations(String text) {
    // Regular expression to match citation numbers like [1], [2], etc.
    final citationRegex = RegExp(r'\[\d+\]');
    return text.replaceAll(citationRegex, '');
  }
  
  // Check if a query is about GPU recommendations
  static bool isGPURecommendationQuery(String message) {
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('gpu') || 
           lowerMessage.contains('graphic') || 
           lowerMessage.contains('video card') || 
           (lowerMessage.contains('card') && (
              lowerMessage.contains('gaming') || 
              lowerMessage.contains('perform') || 
              lowerMessage.contains('rtx') || 
              lowerMessage.contains('gtx') || 
              lowerMessage.contains('radeon') || 
              lowerMessage.contains('amd') || 
              lowerMessage.contains('nvidia')
           ));
  }

  // Check if the message is asking for tech news
  static bool shouldFetchTechNews(String prompt) {
    final lower = prompt.toLowerCase();
    return lower.contains('news') || lower.contains('update') || lower.contains('latest');
  }

  // Check if the message is asking for Reddit posts/troubleshooting
  static bool shouldFetchRedditPosts(String prompt) {
    final lower = prompt.toLowerCase();
    return lower.contains('problem') || lower.contains('issue') || 
           lower.contains('help') || lower.contains('trouble') ||
           lower.contains('reddit') || lower.contains('post') || lower.contains('r/');
  }

  // Format Reddit posts for inclusion in response message
  static String formatRedditPostsMessage(String message, List<dynamic> redditPosts, String userQuery) {
    if (redditPosts.isEmpty) {
      return message;
    }
    
    // Add Reddit posts at the end of the message
    String result = message;
    
    // Only add Reddit section if it's not already mentioned
    if (!result.contains('Reddit posts')) {
      result += '\n\n### Relevant Reddit Posts\n';
      result += 'I found some discussions on Reddit that might help with your question:\n\n';
      
      for (var post in redditPosts.take(3)) {
        // Format depends on if this is a RedditPost object or just a Map
        if (post is RedditPost) {
          result += '- [${post.title}](${post.url}) (${post.subreddit}, ${post.score} upvotes)\n';
          if (post.selftext.isNotEmpty) {
            // Limit to 150 chars for snippet
            final snippet = post.selftext.length > 150 
                ? '${post.selftext.substring(0, 150)}...' 
                : post.selftext;
            result += '  > $snippet\n\n';
          }
        } else if (post is Map) {
          result += '- [${post['title']}](${post['url']}) (${post['subreddit']}, ${post['score']} upvotes)\n';
          if (post['selftext'] != null && post['selftext'].isNotEmpty) {
            // Limit to 150 chars for snippet
            final snippet = post['selftext'].length > 150 
                ? '${post['selftext'].substring(0, 150)}...' 
                : post['selftext'];
            result += '  > $snippet\n\n';
          }
        }
      }
    }
    
    return result;
  }

  // Generate system prompt for bot API
  static String buildSystemMessage(String additionalContext) {
    return 'You are a helpful PC-building maintenance and configuration assistant. '
        'Provide responses in markdown format. Maintain context from previous messages in the conversation. '
        'Focus on providing accurate and concise information about PC hardware, software, and troubleshooting. '
        'Pay close attention to the conversation context when responding to follow-up questions. '
        'For example, If a user asks a simple follow-up like "what about under \$500?" after discussing GPUs, '
        'interpret it as a continuation of the GPU discussion rather than switching to a new topic. '
        'Follow-up questions with brief context should maintain the subject of the previous exchange.'
        '$additionalContext';
  }

  // Refine video search query based on user feedback
  static String refineVideoSearchQuery(String topic, List<String> keywords) {
    // Extract important words from the topic, minimum 3 chars
    final queryWords = topic.toLowerCase().split(' ')
        .where((word) => word.length > 3)
        .toList();
    
    if (queryWords.isNotEmpty) {
      // Create a more explicit tutorial-focused query
      return "${queryWords.join(' ')} ${keywords.join(' ')}";
    }
    
    return "$topic ${keywords.join(' ')}";
  }
} 