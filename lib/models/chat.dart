// Chat model for conversation data
class Chat {
  // Unique identifier for the chat
  final String id;
  
  // Name of the conversation
  final String title;
  
  // When the chat was created
  final DateTime createdAt;
  
  // List of messages in the conversation
  final List<Map<String, dynamic>> messages;
  
  // Whether chat is pinned to top of list
  final bool isPinned;

  // Constructor with required and optional fields
  Chat({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
    this.isPinned = false, // Default to not pinned
  });

  // Convert Chat to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      // Convert date to string format
      'createdAt': createdAt.toIso8601String(),
      // Normalise message format
      'messages': messages.map((m) => {
        'sender': m['sender'] ?? '', // Extracts sender from message map
        'message': m['message'] ?? '', // Extracts message content from message map
        'videos': m['videos'] ?? [], // Preserve video data if present
        'redditPosts': m['redditPosts'] ?? [], // Preserve Reddit post data
        'edited': m['edited'] ?? false, // Add edited flag
        'regenerated': m['regenerated'] ?? false, // Add regenerated flag
      }).toList(),
      'isPinned': isPinned,
    };
  }

  // Create Chat from database Map
  factory Chat.fromMap(Map<String, dynamic> map) {
    // Process messages with proper type handling
    var messagesList = (map['messages'] as List?)?.map((m) {
      if (m is Map) {
        // Handle video data
        final videosData = m['videos'] as List? ?? [];
        
        // Handle Reddit post data
        final redditPostsData = m['redditPosts'] as List? ?? [];
        
        return {
          'sender': (m['sender'] ?? '').toString(), // Ensures sender is a string
          'message': (m['message'] ?? '').toString(), // Ensures message is a string
          'videos': videosData, // Preserve original video data
          'redditPosts': redditPostsData, // Preserve original Reddit post data
          'edited': m['edited'] ?? false, // Get edited flag with default false
          'regenerated': m['regenerated'] ?? false, // Get regenerated flag with default false
        };
      }
      // Default values for invalid message data
      return {'sender': '', 'message': '', 'videos': [], 'redditPosts': [], 'edited': false, 'regenerated': false};
    }).toList() ?? [];

    // Create Chat with parsed data
    return Chat(
      id: map['id'] ?? '', //Fallback to empty string if id is null
      title: map['title'] ?? '', // Fallback to empty string if title is null
      // Parse date string with fallback
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      messages: messagesList, // Assigns the parsed messages list
      isPinned: map['isPinned'] ?? false,// Get isPinned status with default false
    );
  }

  // Create new Chat with updated properties
  Chat copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<Map<String, dynamic>>? messages,
    bool? isPinned,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      messages: messages ?? this.messages,
      isPinned: isPinned ?? this.isPinned,
    );
  }
} 