class RedditPostPreview {
  final String title;
  final String subreddit;
  final String url;
  final int score;
  final int commentCount;
  final String? thumbnailUrl;
  final double relevanceScore;

  RedditPostPreview({
    required this.title,
    required this.subreddit,
    required this.url,
    required this.score,
    this.commentCount = 0,
    this.thumbnailUrl,
    this.relevanceScore = 0.0,
  });

  factory RedditPostPreview.fromRedditPost(dynamic post) {
    try {
      // Convert score to int if needed
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
        commentCount: 0, // Default value as this might not be available
        thumbnailUrl: null, // Default value as this might not be available
      );
    } catch (e) {
      print('Error creating RedditPostPreview from RedditPost: $e');
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