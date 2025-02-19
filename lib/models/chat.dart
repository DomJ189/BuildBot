class Chat {
  final String id; // Unique identifier for the chat
  final String title; // Title of the chat
  final DateTime createdAt; // Timestamp of when the chat was created
  final List<Map<String, String>> messages; // List of messages in the chat

  // Constructor for the Chat class
  Chat({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
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
      }).toList(),
    };
  }

  // Factory constructor to create a Chat object from a Map
  factory Chat.fromMap(Map<String, dynamic> map) {
    // Parses messages from the map, ensuring proper types
    var messagesList = (map['messages'] as List?)?.map((m) {
      if (m is Map) {
        return {
          'sender': (m['sender'] ?? '').toString(), // Ensures sender is a string
          'message': (m['message'] ?? '').toString(), // Ensures message is a string
        };
      }
      return {'sender': '', 'message': ''}; // Default values if message is not a map
    }).toList() ?? []; // Fallback to an empty list if null

    // Creates a Chat object from the provided map
    return Chat(
      id: map['id'] ?? '', // Fallback to empty string if id is null
      title: map['title'] ?? '', // Fallback to empty string if title is null
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()), // Parses createdAt or uses current time
      messages: messagesList, // Assigns the parsed messages list
    );
  }
} 