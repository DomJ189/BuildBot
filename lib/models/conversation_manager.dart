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

  void initialiseFrom(List<Map<String, dynamic>> messages) {
    clear();
    
    // Process all messages into the history preserving exact conversation flow
    for (var message in messages) {
      // Check for different possible field names to improve robustness
      String role;
      String content;
      
      // Determine role: could be in 'role' field or derived from 'sender'
      if (message.containsKey('role')) {
        role = message['role'].toString();
      } else if (message.containsKey('sender')) {
        role = message['sender'] == 'user' ? 'user' : 'assistant';
      } else {
        // Skip messages without role information
        print('Warning: Skipping message without role/sender information');
        continue;
      }
      
      // Determine content: could be in 'content' field or 'message'
      if (message.containsKey('content')) {
        content = message['content'].toString();
      } else if (message.containsKey('message')) {
        content = message['message'].toString();
      } else {
        // Skip messages without content
        print('Warning: Skipping message without content/message information');
        continue;
      }
      
      // Skip empty messages
      if (content.trim().isEmpty) {
        print('Warning: Skipping empty message');
        continue;
      }
      
      _history.add({'role': role, 'content': content});
    }
    
    // Only trim if needed
    _trimHistory();
    
    // Debug log to verify history is properly loaded
    print('✓ Initialised conversation with ${_history.length} messages');
    for (int i = 0; i < _history.length; i++) {
      final content = _history[i]['content']?.toString() ?? '';
      final previewLength = math.min<int>(50, content.length);
      final preview = content.length > 0 ? content.substring(0, previewLength) : '';
      print('Message ${i+1}: ${_history[i]['role']} - $preview${content.length > previewLength ? "..." : ""}');
    }
  }

  List<Map<String, dynamic>> get messages => List.from(_history);
  
  void _trimHistory() {
    if (_history.length > _maxHistoryLength) {
      // Remove from the middle rather than just the beginning to preserve the start and end context
      int removeCount = _history.length - _maxHistoryLength;
      int startRemoveIndex = (_maxHistoryLength ~/ 5); // Keep some early context
      print('Trimming conversation history: removing $removeCount messages starting at index $startRemoveIndex');
      _history.removeRange(startRemoveIndex, startRemoveIndex + removeCount);
    }
  }
} 