import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reddit_post.dart';
import 'dart:async';

class RedditService {
  final String clientId;
  final String clientSecret;
  String? _accessToken;
  DateTime? _tokenExpiry;
  
  RedditService({required this.clientId, required this.clientSecret});

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
        'Authorisation': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
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

  // Low-level API method to search a specific subreddit
  Future<List<RedditPost>> _searchSubreddit({
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
          'Authorisation': 'Bearer $token',
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
      print('Error searching subreddit $subreddit: $e');
      return [];
    }
  }

  // Public method for searching Reddit for troubleshooting posts
  Future<List<RedditPost>> searchRedditForTroubleshooting(String query) async {
    try {
      // Expanded list of subreddits to search with more technical PC-focused ones first
      final subreddits = [
        'buildapc', 'techsupport', 'pcmasterrace', 'PcBuild', 
        'hardware', 'pcgaming', 'overclocking', 'nvidia', 'amd',
        'intel', 'watercooling', 'pchelp', 'computers', 'computertechs',
        'buildmeapc', 'nvidia', 'amdhelp'
      ];
      final List<RedditPost> results = [];
      
      // Refine the search query for better results
      String searchQuery = _refineSearchQuery(query);
      
      // Extract key terms for relevance scoring
      final queryTerms = _extractKeyTerms(query.toLowerCase());
      
      // Get posts from relevant subreddits
      for (final subreddit in subreddits) {
        try {
          final posts = await _searchSubreddit(
            subreddit: subreddit,
            query: searchQuery,
            sort: 'relevance',
            time: 'all',
            limit: 3, // Limit per subreddit to avoid too many results
          );
          
          if (posts.isNotEmpty) {
            try {
              final enhancedPosts = posts.map((post) {
                // Calculate relevance score
                final relevanceScore = _calculateRelevanceScore(post, queryTerms, query);
                
                // Return post with relevance score
                return post.copyWithRelevance(relevanceScore);
              }).toList();
              
              results.addAll(enhancedPosts);
              
              // If we found some posts already, we don't need to check all subreddits
              if (results.length >= 5 && !_isSpecificSubredditRequest(query)) {
                break;
              }
            } catch (e) {
              print('Error processing Reddit posts: $e');
            }
          }
        } catch (e) {
          print('Error searching Reddit subreddit $subreddit: $e');
          // Continue with other subreddits even if one fails
        }
      }
      
      if (results.isNotEmpty) {
        print('Found ${results.length} Reddit posts before filtering');
      } else {
        print('No Reddit posts found for query: "$searchQuery"');
      }
      
      // Filter out irrelevant or inappropriate content
      final filteredResults = _filterResults(results, query);
      
      if (results.length != filteredResults.length) {
        print('Filtered out ${results.length - filteredResults.length} irrelevant posts');
      }
      
      // Sort by combined relevance and score
      filteredResults.sort((a, b) {
        // If relevance scores differ significantly, use that for sorting
        if ((b.relevanceScore - a.relevanceScore).abs() > 0.3) {
          return b.relevanceScore.compareTo(a.relevanceScore);
        }
        
        // Otherwise use a combination of relevance and popularity
        final aScore = a.relevanceScore * 2 + (a.score > 100 ? 1 : a.score / 100);
        final bScore = b.relevanceScore * 2 + (b.score > 100 ? 1 : b.score / 100);
        return bScore.compareTo(aScore);
      });
      
      // Return at most 3 posts to avoid overwhelming the user
      return filteredResults.take(3).toList();
    } catch (e) {
      print('Error searching Reddit: $e');
      return [];
    }
  }
  
  // Calculate relevance score based on query terms
  double _calculateRelevanceScore(RedditPost post, List<String> queryTerms, String originalQuery) {
    if (queryTerms.isEmpty) return 0.5; // Default mid-level score if no query terms
    
    final lowerTitle = post.title.toLowerCase();
    
    // Prioritise technical PC subreddits over general ones
    final techSubreddits = [
      'buildapc', 'techsupport', 'hardware', 'computers', 'pchelp'
    ];
    
    double score = 0.0;
    
    // Subreddit relevance (0-0.3)
    if (techSubreddits.contains(post.subreddit.toLowerCase())) {
      score += 0.3;
    } else {
      score += 0.1;
    }
    
    // Title relevance based on query terms (0-0.7)
    int matchedTerms = 0;
    
    // Count how many query terms appear in the title
    for (final term in queryTerms) {
      if (term.length > 3 && lowerTitle.contains(term)) {
        matchedTerms++;
        
        // Extra points for exact phrase matches
        if (lowerTitle.contains(term)) {
          score += 0.1;
        }
      }
    }
    
    // Calculate percentage of query terms matched
    if (queryTerms.isNotEmpty) {
      final matchPercentage = matchedTerms / queryTerms.length;
      score += matchPercentage * 0.5;
    }
    
    // Check for original query as a whole appearing in title
    if (lowerTitle.contains(originalQuery.toLowerCase())) {
      score += 0.2;
    }
    
    return score.clamp(0.0, 1.0); // Ensure score is between 0 and 1
  }
  
  // Filter out irrelevant or inappropriate content from search results
  List<RedditPost> _filterResults(List<RedditPost> results, String originalQuery) {
    // Extract key terms from the original query to check for relevance
    final queryTerms = _extractKeyTerms(originalQuery.toLowerCase());
    
    // Lists of terms to check for inappropriate or off-topic content
    final List<String> inappropriateSubreddits = [
      'interestingasfuck', 'funny', 'memes', 'gaming', 'askreddit', 
      'movies', 'news', 'worldnews', 'jokes', 'todayilearned',
      'showerthoughts', 'tifu', 'nostupidquestions', 'eli5',
      'outoftheloop', 'pics', 'videos', 'gifs'
    ];
    
    final List<String> irrelevantTitleTerms = [
      'meme', 'joke', 'funny', 'lol', 'simulator',
      'downvoted', 'upvoted', 'karma', 'musk', 'elon', 
      'moderator', 'ban', 'reddit history', 'comment of'
    ];
    
    // Extract PC-related terms from original query to check for topic relevance
    final Map<String, List<String>> pcTermsMap = {
      'ram': ['ram', 'memory', 'dimm', 'ddr', 'stick'],
      'cpu': ['cpu', 'processor', 'ryzen', 'intel', 'core'],
      'gpu': ['gpu', 'graphics', 'rtx', 'gtx', 'nvidia', 'amd', 'radeon'],
      'boot': ['boot', 'post', 'start', 'turn on', 'power on', 'won\'t boot'],
      'motherboard': ['motherboard', 'mobo', 'board'],
    };
    
    // Check which PC terms are in the original query
    List<String> queryPcTerms = [];
    final lowerOriginalQuery = originalQuery.toLowerCase();
    
    for (final entry in pcTermsMap.entries) {
      for (final term in entry.value) {
        if (lowerOriginalQuery.contains(term)) {
          queryPcTerms.add(entry.key);
          break;
        }
      }
    }
    
    print('PC-related terms in query: $queryPcTerms');
    
    return results.where((post) {
      // Check if from an inappropriate subreddit
      if (inappropriateSubreddits.contains(post.subreddit.toLowerCase())) {
        print('Filtering out post from inappropriate subreddit: ${post.subreddit}');
        return false;
      }
      
      // Check for irrelevant title terms (less strict filtering)
      final lowerTitle = post.title.toLowerCase();
      for (final term in irrelevantTitleTerms) {
        if (lowerTitle.contains(term)) {
          print('Filtering out post with irrelevant title term "$term": ${post.title}');
          return false;
        }
      }
      
      // Special rule: ALWAYS KEEP posts that match the query hardware terms
      // This ensures we don't filter out posts about RAM issues when the user asks about RAM
      for (final pcTerm in queryPcTerms) {
        final termSynonyms = pcTermsMap[pcTerm] ?? [];
        for (final syn in termSynonyms) {
          if (lowerTitle.contains(syn)) {
            // Important PC hardware in original query found in post title - keep it
            print('Keeping post with matching PC term "$syn": ${post.title}');
            return true;
          }
        }
      }
      
      // If the post title contains a good match for the query, keep it
      // For example, if query is about RAM not booting, keep posts mentioning RAM and booting
      if (queryPcTerms.length >= 2) {
        int matchedTerms = 0;
        for (final pcTerm in queryPcTerms) {
          final termSynonyms = pcTermsMap[pcTerm] ?? [];
          for (final syn in termSynonyms) {
            if (lowerTitle.contains(syn)) {
              matchedTerms++;
              break;
            }
          }
        }
        
        // If post matches multiple PC terms from query, keep it
        if (matchedTerms >= 2) {
          print('Keeping post matching multiple PC terms: ${post.title}');
          return true;
        }
      }
      
      // For remaining posts, check general topic relevance more leniently
      // Only apply this check if we have reasonable query terms
      if (queryTerms.isNotEmpty && queryTerms.any((term) => term.length > 3)) {
        // Check if any query term appears in the title
        bool hasAnyQueryTerm = false;
        for (final term in queryTerms) {
          if (term.length > 3 && lowerTitle.contains(term)) {
            hasAnyQueryTerm = true;
            break;
          }
        }
        
        if (!hasAnyQueryTerm) {
          print('Filtering out off-topic post: ${post.title}');
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  // Extract key terms from a query for relevance checking
  List<String> _extractKeyTerms(String query) {
    // First check for PC hardware terms
    final hardwareTerms = [
      'ram', 'memory', 'cpu', 'processor', 'gpu', 'graphics',
      'motherboard', 'boot', 'post', 'bios', 'screen', 'display',
      'install', 'computer', 'pc', 'desktop', 'build'
    ];
    
    final List<String> foundTerms = [];
    
    // Add hardware terms found in query
    for (final term in hardwareTerms) {
      if (query.contains(term)) {
        foundTerms.add(term);
      }
    }
    
    // Add other significant words (4+ characters, not common stop words)
    final stopWords = [
      'the', 'and', 'for', 'with', 'this', 'that', 'have', 'from',
      'what', 'when', 'where', 'will', 'would', 'should', 'could',
      'about', 'there', 'which', 'their', 'some', 'other'
    ];
    
    query.split(' ').forEach((word) {
      final cleaned = word.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
      if (cleaned.length > 3 && !stopWords.contains(cleaned) && !foundTerms.contains(cleaned)) {
        foundTerms.add(cleaned);
      }
    });
    
    return foundTerms;
  }
  
  // Helper method to refine the search query for better results
  String _refineSearchQuery(String query) {
    // Remove common phrases that might dilute the search
    final lowerQuery = query.toLowerCase();
    
    // Map of common PC troubleshooting issues to better search terms
    final Map<List<String>, String> troubleshootingTerms = {
      ['ram', 'install', 'boot']: 'ram install won\'t boot',
      ['ram', 'new', 'boot']: 'new ram computer won\'t boot',
      ['ram', 'boot']: 'ram won\'t boot',
      ['gpu', 'overheat']: 'gpu overheating fix',
      ['cpu', 'overheat']: 'cpu overheating fix',
      ['blue screen', 'bsod']: 'blue screen of death fix',
      ['pc', 'crash']: 'pc random crashes fix',
      ['computer', 'freeze']: 'computer freezing fix',
      ['black screen']: 'pc black screen on boot',
      ['no display']: 'pc no display troubleshooting',
    };
    
    // Check if query matches any common troubleshooting patterns
    for (final entry in troubleshootingTerms.entries) {
      final keyTerms = entry.key;
      if (keyTerms.every((term) => lowerQuery.contains(term))) {
        return entry.value;
      }
    }
    
    // Extract PC component terms for hardware-specific issues
    final hardwareComponents = {
      'ram': ['ram', 'memory', 'dimm', 'ddr4', 'ddr5', 'stick'],
      'cpu': ['cpu', 'processor', 'ryzen', 'intel', 'core i7', 'core i5', 'core i9', 'amd'],
      'gpu': ['gpu', 'graphics card', 'rtx', 'gtx', 'amd', 'nvidia', 'radeon'],
      'motherboard': ['motherboard', 'mobo', 'mainboard'],
      'boot': ['boot', 'post', 'start', 'turn on', 'power on'],
      'display': ['monitor', 'screen', 'display'],
      'storage': ['ssd', 'hdd', 'hard drive', 'nvme', 'm.2'],
      'psu': ['psu', 'power supply'],
    };
    
    // Build a more specific query based on hardware components mentioned
    List<String> detectedComponents = [];
    
    for (final component in hardwareComponents.entries) {
      if (component.value.any((term) => lowerQuery.contains(term))) {
        detectedComponents.add(component.key);
      }
    }
    
    // If we found specific PC components, create a more targeted search
    if (detectedComponents.isNotEmpty) {
      // Extract problem terms
      final problemTerms = [
        'won\'t boot', 'not booting', 'doesn\'t boot', 'won\'t start',
        'crash', 'freeze', 'black screen', 'blue screen', 'bsod',
        'error', 'fail', 'problem', 'issue', 'troubleshoot',
        'overheat', 'overheating', 'not working', 'broken'
      ];
      
      String problemTerm = '';
      for (final term in problemTerms) {
        if (lowerQuery.contains(term)) {
          problemTerm = term;
          break;
        }
      }
      
      if (problemTerm.isNotEmpty) {
        return '${detectedComponents.join(' ')} ${problemTerm}';
      } else {
        return '${detectedComponents.join(' ')} problem';
      }
    }
    
    // If specifically asking for reddit posts or links, extract the main topic
    if (lowerQuery.contains('reddit') || lowerQuery.contains('post') || 
        lowerQuery.contains('link') || lowerQuery.contains('r/')) {
      
      // Extract the main topic from queries like "show me reddit posts about X"
      final aboutMatch = RegExp(r'(?:about|on|for|related to)\s+([^?.]+)', caseSensitive: false)
          .firstMatch(lowerQuery);
      
      if (aboutMatch != null && aboutMatch.group(1) != null) {
        String topic = aboutMatch.group(1)!.trim();
        
        // Add "how to fix" for better results with troubleshooting queries
        if (topic.contains('problem') || 
            topic.contains('issue') || 
            topic.contains('error') ||
            topic.contains('not working')) {
          return 'how to fix $topic';
        }
        
        return topic;
      }
    }
    
    // For troubleshooting queries, formulate a specific "how to fix" query
    final troubleshootingIndicators = [
      'won\'t boot', 'not booting', 'doesn\'t boot', 'won\'t start',
      'crash', 'freeze', 'black screen', 'blue screen', 'bsod',
      'error', 'fail', 'problem', 'issue', 'troubleshoot', 'help',
      'fix', 'overheat', 'overheating', 'not working', 'broken'
    ];
    
    if (troubleshootingIndicators.any((term) => lowerQuery.contains(term))) {
      // Keep the whole query but format it as a "fix" query
      return 'how to fix ${query.toLowerCase().replaceAll("?", "")}';
    }
    
    // Filter out common words and keep key terms
    final words = query.split(' ')
        .where((word) => word.length > 3 && 
              !['show', 'give', 'find', 'help', 'need', 'want', 'please', 
                'reddit', 'post', 'links', 'about', 'some', 'with', 'other', 
                'cases', 'this', 'issue', 'can', 'you'].contains(word.toLowerCase()))
        .take(5)
        .join(' ');
    
    return words.isNotEmpty ? words : query;
  }
  
  // Check if the query is looking for posts in a specific subreddit
  bool _isSpecificSubredditRequest(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Check for r/ format
    if (lowerQuery.contains('r/')) {
      return true;
    }
    
    // Check for explicit subreddit names
    final subredditNames = [
      'pcmasterrace', 'buildapc', 'techsupport', 'hardware', 'pcgaming', 
      'overclocking', 'nvidia', 'amd', 'intel'
    ];
    
    return subredditNames.any((name) => lowerQuery.contains(name));
  }
} 