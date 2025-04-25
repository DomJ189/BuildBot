import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as Math;

class RedditClient {
  final String clientId;
  final String clientSecret;
  String? _accessToken;
  DateTime? _tokenExpiry;

  RedditClient({
    required this.clientId,
    required this.clientSecret,
  });

  Future<String> _getAccessToken() async {
    // If we have a valid token, return it
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    // Otherwise, get a new token
    final response = await http.post(
      Uri.parse('https://www.reddit.com/api/v1/access_token'),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
      return _accessToken!;
    } else {
      throw Exception('Failed to get Reddit access token: ${response.body}');
    }
  }

  Future<List<RedditPost>> search({
    required String subreddit,
    required String query,
    String sort = 'relevance',
    String time = 'all',
    int limit = 5,
  }) async {
    try {
      final token = await _getAccessToken();
      
      print('Searching Reddit subreddit: $subreddit, query: "$query"');
      
      // Add "selftext:query" to search both title and post content 
      // This improves results by finding posts where the detail matches
      final enhancedQuery = '$query selftext:$query';
      
      final uri = Uri.parse('https://oauth.reddit.com/r/$subreddit/search')
          .replace(queryParameters: {
        'q': enhancedQuery,
        'sort': sort,
        't': time,
        'limit': limit.toString(),
        'restrict_sr': 'true', // Restrict to subreddit
        'type': 'link',        // Return regular posts, not just comments
      });
      
      print('Reddit API request URL: $uri');
      
      // Add timeout to prevent hanging on slow API responses
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': 'BuildBot/1.0.0',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Reddit API request timed out for subreddit: $subreddit');
          return http.Response('{"message": "Request timed out"}', 408); 
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Process Reddit API response data
        if (data['data'] != null && data['data']['children'] != null) {
          final children = data['data']['children'] as List;
          
          if (children.isEmpty) {
            // No results found in the subreddit for this query
            return [];
          }
          
          // Transform API response into RedditPost objects
          final posts = children
              .map((post) {
                try {
                  // Skip posts with very short titles or no content
                  if (post['data'] != null) {
                    final title = post['data']['title'] as String? ?? '';
                    final selftext = post['data']['selftext'] as String? ?? '';
                    
                    // Skip posts with very little content
                    if (title.length < 5 || (selftext.isEmpty && title.length < 15)) {
                      return null;
                    }
                    
                    return RedditPost.fromJson(post['data']);
                  }
                  return null;
                } catch (e) {
                  // Handle errors when parsing a specific post
                  return null;
                }
              })
              .whereType<RedditPost>() // Filter out nulls
              .toList();
          
          return posts;
        } else {
          // Invalid API response structure received
          return [];
        }
      } else {
        // API returned error status code
        return [];
      }
    } catch (e) {
      // Exception occurred during API request
      return [];
    }
  }
}

class RedditPost {
  final String title;
  final String selftext;
  final String url;
  final int score;
  final String subreddit;
  final int createdUtc;

  RedditPost({
    required this.title,
    required this.selftext,
    required this.url,
    required this.score,
    required this.subreddit,
    required this.createdUtc,
  });

  factory RedditPost.fromJson(Map<String, dynamic> json) {
    try {
      // Handle score which can be int, double, or null
      int score = 0;
      if (json['score'] != null) {
        if (json['score'] is int) {
          score = json['score'];
        } else if (json['score'] is double) {
          score = (json['score'] as double).toInt();
        }
      }
      
      // Handle createdUtc which can be int, double, or null
      int createdUtc = 0;
      if (json['created_utc'] != null) {
        if (json['created_utc'] is int) {
          createdUtc = json['created_utc'];
        } else if (json['created_utc'] is double) {
          createdUtc = (json['created_utc'] as double).toInt();
        }
      }
      
      return RedditPost(
        title: json['title'] ?? '',
        selftext: json['selftext'] ?? '',
        url: json['url'] ?? '',
        score: score,
        subreddit: json['subreddit'] ?? '',
        createdUtc: createdUtc,
      );
    } catch (e) {
      // Return empty post if error occurs during parsing
      return RedditPost(
        title: 'Error loading post',
        selftext: '',
        url: '',
        score: 0,
        subreddit: '',
        createdUtc: 0,
      );
    }
  }
} 