import 'dart:math' as math;

// Class to manage conversation history for AI chat
class ConversationManager {
  final List<Map<String, dynamic>> _history = [];
  static const int _maxHistoryLength = 25; // Increased from 10 to 25 for better context retention

  void addMessage(String role, String content) {
    // Ensure content is a string and not null
    final safeContent = content.toString();
    _history.add({'role': role, 'content': safeContent});
    _trimHistory();
  }

  void clear() => _history.clear();

  void initializeFrom(List<Map<String, dynamic>> messages) {
    clear();
    
    // Process all messages into the history preserving exact conversation flow
    for (var message in messages) {
      String role = message['sender'] == 'user' ? 'user' : 'assistant';
      String content = (message['message'] ?? '').toString();
      
      // Skip empty messages
      if (content.trim().isEmpty) continue;
      
      _history.add({'role': role, 'content': content});
    }
    
    // Only trim if needed
    _trimHistory();
    
    // Debug log to verify history is properly loaded
    print('Initialized conversation with ${_history.length} messages');
    for (int i = 0; i < _history.length; i++) {
      final content = _history[i]['content']?.toString() ?? '';
      final previewLength = math.min<int>(50, content.length);
      print('Message ${i+1}: ${_history[i]['role']} - ${content.substring(0, previewLength)}...');
    }
  }

  List<Map<String, dynamic>> get messages => List.from(_history);
  
  void _trimHistory() {
    if (_history.length > _maxHistoryLength) {
      // Remove from the middle rather than just the beginning to preserve the start and end context
      int removeCount = _history.length - _maxHistoryLength;
      int startRemoveIndex = (_maxHistoryLength ~/ 5); // Keep some early context
      _history.removeRange(startRemoveIndex, startRemoveIndex + removeCount);
    }
  }
} 