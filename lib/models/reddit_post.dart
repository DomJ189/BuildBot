class RedditPost {
  final String title;         // Post title
  final String selftext;      // Post body content
  final String url;           // Post URL
  final int score;            // Post score (upvotes minus downvotes)
  final String subreddit;     // Subreddit name
  final int createdUtc;       // Creation timestamp
  final int commentCount;     // Number of comments
  final String? thumbnailUrl; // Optional preview image
  final double relevanceScore; // Calculated relevance to user query

  RedditPost({
    required this.title,
    required this.selftext,
    required this.url,
    required this.score,
    required this.subreddit,
    required this.createdUtc,
    this.commentCount = 0,
    this.thumbnailUrl,
    this.relevanceScore = 0.0,
  });

  // Create RedditPost from API JSON data
  factory RedditPost.fromJson(Map<String, dynamic> json) {
    try {
      // Handle score conversion
      int score = 0;
      if (json['score'] != null) {
        if (json['score'] is int) {
          score = json['score'];
        } else if (json['score'] is double) {
          score = (json['score'] as double).toInt();
        }
      }
      
      // Handle creation timestamp conversion
      int createdUtc = 0;
      if (json['created_utc'] != null) {
        if (json['created_utc'] is int) {
          createdUtc = json['created_utc'];
        } else if (json['created_utc'] is double) {
          createdUtc = (json['created_utc'] as double).toInt();
        }
      }
      
      // Extract comment count if available
      int commentCount = 0;
      if (json['num_comments'] != null) {
        if (json['num_comments'] is int) {
          commentCount = json['num_comments'];
        } else if (json['num_comments'] is double) {
          commentCount = (json['num_comments'] as double).toInt();
        }
      }
      
      // Extract thumbnail if available
      String? thumbnailUrl;
      if (json['thumbnail'] != null && 
          json['thumbnail'] is String && 
          json['thumbnail'] != 'self' && 
          json['thumbnail'] != 'default') {
        thumbnailUrl = json['thumbnail'];
      }
      
      return RedditPost(
        title: json['title'] ?? '',
        selftext: json['selftext'] ?? '',
        url: json['url'] ?? '',
        score: score,
        subreddit: json['subreddit'] ?? '',
        createdUtc: createdUtc,
        commentCount: commentCount,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      // Return empty post on error
      return RedditPost(
        title: 'Error loading post',
        selftext: '',
        url: '',
        score: 0,
        subreddit: '',
        createdUtc: 0,
        commentCount: 0,
      );
    }
  }

  // Create a simplified version from map (for chat history restoration)
  factory RedditPost.fromMap(Map<String, dynamic> map) {
    return RedditPost(
      title: map['title'] ?? '',
      selftext: map['selftext'] ?? '',
      url: map['url'] ?? '',
      score: map['score'] ?? 0,
      subreddit: map['subreddit'] ?? '',
      createdUtc: map['createdUtc'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      thumbnailUrl: map['thumbnailUrl'],
      relevanceScore: map['relevanceScore']?.toDouble() ?? 0.0,
    );
  }

  // Get DateTime object from createdUtc timestamp
  DateTime get createdDate => 
      DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000);
      
  // Get post content (selftext)
  String get content => selftext;
  
  // Creates a new instance with updated relevance score
  RedditPost copyWithRelevance(double newRelevanceScore) {
    return RedditPost(
      title: title,
      selftext: selftext,
      url: url,
      score: score,
      subreddit: subreddit,
      createdUtc: createdUtc,
      commentCount: commentCount,
      thumbnailUrl: thumbnailUrl,
      relevanceScore: newRelevanceScore,
    );
  }
  
  // Converts to a map for serialisation
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'selftext': selftext,
      'url': url,
      'score': score,
      'subreddit': subreddit,
      'createdUtc': createdUtc,
      'commentCount': commentCount,
      'thumbnailUrl': thumbnailUrl,
      'relevanceScore': relevanceScore,
    };
  }
} 