// Class to handle simple conversational messages and generate appropriate responses
class ConversationalResponseHandler {
  static final _conversationalPhrases = [
    'thank you', 'thanks', 'ok', 'okay', 'got it', 'understood', 'great',
    'good', 'perfect', 'excellent', 'awesome', 'nice', 'cool', 'sounds good',
    'appreciate it', 'that\'s helpful', 'that helps', 'i see', 'alright',
    'all right', 'sure', 'fine', 'bye', 'goodbye', 'see you', 'talk later',
    'have a good day', 'great job', 'well done', 'amazing'
  ];
  
  static bool isConversational(String message) {
    final lowerMessage = message.toLowerCase().trim();
    return _conversationalPhrases.any((phrase) => 
      lowerMessage == phrase || 
      lowerMessage.startsWith('$phrase.') || 
      lowerMessage.startsWith('$phrase!') ||
      lowerMessage.startsWith('$phrase,')
    );
  }
  
  static String generateResponse(String message) {
    final lowerMessage = message.toLowerCase().trim();
    
    if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      return "You're welcome! Is there anything else you'd like to know about PC building or hardware?";
    }
    
    if (lowerMessage.contains('ok') || lowerMessage.contains('got it') || 
        lowerMessage == 'sure' || lowerMessage == 'alright' || 
        lowerMessage.contains('understood')) {
      return "Great! Let me know if you need any more information or have other questions.";
    }
    
    if (lowerMessage.contains('bye') || lowerMessage.contains('goodbye') || 
        lowerMessage.contains('see you') || lowerMessage.contains('talk later')) {
      return "Goodbye! Feel free to come back if you have more questions about PC building or hardware.";
    }
    
    return "Is there anything else you'd like to know about PC components or building a computer?";
  }
} 