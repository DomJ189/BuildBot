class YouTubeVideo {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final DateTime publishedAt;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
  });

  String get watchUrl => 'https://www.youtube.com/watch?v=$id';
  
  // Add app-specific URLs for different platforms
  String get appUrl => 'youtube://www.youtube.com/watch?v=$id';
  
  // YouTube deep link format for mobile apps
  String get deepLinkUrl => 'vnd.youtube:$id';
  
  // Creates a map representation for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'channelTitle': channelTitle,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }
  
  // Create from a map, useful for deserialization
  factory YouTubeVideo.fromMap(Map<String, dynamic> map) {
    return YouTubeVideo(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      channelTitle: map['channelTitle'] ?? '',
      publishedAt: map['publishedAt'] != null 
          ? DateTime.parse(map['publishedAt']) 
          : DateTime.now(),
    );
  }
} 