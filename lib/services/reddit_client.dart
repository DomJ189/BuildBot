import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as Math;
import '../models/reddit_post.dart';

// Client for accessing Reddit API to search and retrieve posts
class RedditClient {
  final String clientId;
  final String clientSecret;
  String? _accessToken;
  DateTime? _tokenExpiry;

  // Initialize with API credentials
  RedditClient({
    required this.clientId,
    required this.clientSecret,
  });

  // Get or refresh OAuth access token
  Future<String> _getAccessToken() async {
    // Return existing token if still valid
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    // Request new token
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

  // Search Reddit for relevant posts
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
      
      // Enhance query to search both title and content
      final enhancedQuery = '$query selftext:$query';
      
      // Build search request URL
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
      
      // Send request with timeout
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
        
        // Parse response data
        if (data['data'] != null && data['data']['children'] != null) {
          final children = data['data']['children'] as List;
          
          if (children.isEmpty) {
            return [];
          }
          
          // Create RedditPost objects from API response
          final posts = children
              .map((post) {
                try {
                  // Skip low-quality posts
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
                  return null;
                }
              })
              .whereType<RedditPost>() // Filter out nulls
              .toList();
          
          return posts;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
} 