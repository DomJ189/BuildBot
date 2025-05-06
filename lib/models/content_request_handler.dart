// Class to detect and analyze different types of content-related user requests
class ContentRequestHandler {
  static final _videoRequestPhrases = [
    'yes', 'sure', 'please', 'show me', 'i would like', 'video', 
    'tutorial', 'demonstration', 'show', 'recommend', 'suggest',
    'yes please'
  ];
  
  static final _moreVideosRequestPhrases = [
    'more videos', 'additional videos', 'other videos', 'different videos',
    'show more', 'another video', 'got more', 'have more', 'anything else',
    'other options', 'other tutorials'
  ];
  
  static final _directVideoRequestPhrases = [
    'show me videos', 'suggest videos', 'videos about', 'videos for', 'videos on',
    'video tutorial', 'tutorials on', 'suggest some videos', 'recommend videos',
    'can you show', 'show video', 'find videos', 'show me some'
  ];
  
  static final _directRedditRequestPhrases = [
    'show me reddit', 'reddit posts', 'posts on reddit', 'reddit discussions',
    'show reddit', 'find reddit', 'reddit threads', 'from reddit',
    'show me some reddit', 'reddit communities', 'subreddit'
  ];
  
  static final _negativeFeedbackPhrases = [
    "those videos don't help", "these videos don't help",
    "not helpful", "doesn't help", "not what i'm looking for",
    "wrong videos", "unrelated videos", "irrelevant",
    "not about", "not related", "not on topic"
  ];
  
  static bool isRequestingVideos(String message) {
    final lowerMessage = message.toLowerCase().trim();
    final simpleAffirmative = ['yes', 'yes please', 'sure', 'ok', 'okay', 'please'];
    return _videoRequestPhrases.any((phrase) => lowerMessage.contains(phrase)) || 
           simpleAffirmative.contains(lowerMessage);
  }
  
  static bool isRequestingMoreVideos(String message) {
    final lowerMessage = message.toLowerCase();
    return _moreVideosRequestPhrases.any((phrase) => lowerMessage.contains(phrase));
  }
  
  static bool isDirectRedditRequest(String message) {
    final lowerMessage = message.toLowerCase();
    return _directRedditRequestPhrases.any((phrase) => lowerMessage.contains(phrase));
  }
  
  static bool isDirectVideoRequest(String message) {
    final lowerMessage = message.toLowerCase();
    
    // First check if this is specifically a Reddit request
    if (isDirectRedditRequest(lowerMessage)) {
      return false;
    }
    
    return _directVideoRequestPhrases.any((phrase) => lowerMessage.contains(phrase));
  }
  
  static bool isNegativeFeedback(String message) {
    final lowerMessage = message.toLowerCase().trim();
    return _negativeFeedbackPhrases.any((phrase) => lowerMessage.contains(phrase));
  }
} 