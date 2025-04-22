class Chat {
  final String id; // Unique identifier for the chat
  final String title; // Title of the chat
  final DateTime createdAt; // Timestamp of when the chat was created
  final List<Map<String, dynamic>> messages; // List of messages in the chat
  final bool isPinned; // New property to track pinned status

  // Constructor for the Chat class
  Chat({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
    this.isPinned = false, // Default to not pinned
  });

  // Converts the Chat object to a Map for easy storage or transmission
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(), // Converts DateTime to ISO 8601 string
      'messages': messages.map((m) => {
        'sender': m['sender'] ?? '', // Extracts sender from message map
        'message': m['message'] ?? '', // Extracts message content from message map
        'videos': m['videos'] ?? [], // Preserve video data if present
        'edited': m['edited'] ?? false, // Add edited flag
        'regenerated': m['regenerated'] ?? false, // Add regenerated flag
      }).toList(),
      'isPinned': isPinned, // Add isPinned to the map
    };
  }

  // Factory constructor to create a Chat object from a Map
  factory Chat.fromMap(Map<String, dynamic> map) {
    // Parses messages from the map, ensuring proper types
    var messagesList = (map['messages'] as List?)?.map((m) {
      if (m is Map) {
        // Handle videos data if present
        final videosData = m['videos'] as List? ?? [];
        
        return {
          'sender': (m['sender'] ?? '').toString(), // Ensures sender is a string
          'message': (m['message'] ?? '').toString(), // Ensures message is a string
          'videos': videosData, // Preserve original video data
          'edited': m['edited'] ?? false, // Get edited flag with default false
          'regenerated': m['regenerated'] ?? false, // Get regenerated flag with default false
        };
      }
      return {'sender': '', 'message': '', 'videos': [], 'edited': false, 'regenerated': false}; // Default values if message is not a map
    }).toList() ?? []; // Fallback to an empty list if null

    // Creates a Chat object from the provided map
    return Chat(
      id: map['id'] ?? '', // Fallback to empty string if id is null
      title: map['title'] ?? '', // Fallback to empty string if title is null
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()), // Parses createdAt or uses current time
      messages: messagesList, // Assigns the parsed messages list
      isPinned: map['isPinned'] ?? false, // Get isPinned status with default false
    );
  }

  // Create a copy of this Chat with modified properties
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