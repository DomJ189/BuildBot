// Simplified model for displaying Reddit post information in the app
class RedditPostPreview {
  final String title;             // Post title
  final String subreddit;         // Source subreddit name
  final String url;               // Link to the original post
  final int score;                // Upvote count/karma score
  final int commentCount;         // Number of comments
  final String? thumbnailUrl;     // Optional preview image
  final double relevanceScore;    // Calculated relevance to user query

  RedditPostPreview({
    required this.title,
    required this.subreddit,
    required this.url,
    required this.score,
    this.commentCount = 0,
    this.thumbnailUrl,
    this.relevanceScore = 0.0,
  });

  // Creates a preview from a full Reddit post object
  factory RedditPostPreview.fromRedditPost(dynamic post) {
    try {
      // Handle score value type conversion
      int score = 0;
      if (post.score is int) {
        score = post.score;
      } else if (post.score is double) {
        score = post.score.toInt();
      } else {
        print('Unexpected score type: ${post.score.runtimeType}');
      }

      return RedditPostPreview(
        title: post.title,
        subreddit: post.subreddit,
        url: post.url,
        score: score,
        commentCount: 0,      // Default as not available in all API responses
        thumbnailUrl: null,   // Default as not available in all API responses
      );
    } catch (e) {
      print('Error creating RedditPostPreview from RedditPost: $e');
      // Return fallback object on error
      return RedditPostPreview(
        title: 'Error loading post',
        subreddit: '',
        url: '',
        score: 0,
        commentCount: 0,
        thumbnailUrl: null,
      );
    }
  }

  // Creates a new instance with updated relevance score
  RedditPostPreview copyWithRelevance(double newRelevanceScore) {
    return RedditPostPreview(
      title: title,
      subreddit: subreddit,
      url: url,
      score: score,
      commentCount: commentCount,
      thumbnailUrl: thumbnailUrl,
      relevanceScore: newRelevanceScore,
    );
  }
} 