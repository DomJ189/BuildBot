import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/youtube_video.dart';

class YouTubeService {
  final String apiKey;
  
  YouTubeService() : apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
  
  Future<List<YouTubeVideo>> searchVideos(String query, {int maxResults = 3}) async {
    if (apiKey.isEmpty) {
      // Return fallback videos when API key is not configured
      return _createFallbackVideos(query: query);
    }
    
    // Calculate date 2 years ago from now (for more recent videos)
    final DateTime twoYearsAgo = DateTime.now().subtract(Duration(days: 365 * 2));
    
    // Format date in RFC 3339 format (required by YouTube API)
    final String formattedDate = twoYearsAgo.toUtc().toIso8601String();
    
    // Clean up the query and add specificity if needed
    query = _refineSearchQuery(query);
    
    // Always add "comparison" for hardware component queries if not already present
    if (_isHardwareComparisonQuery(query) && !query.contains('comparison')) {
      query += ' comparison';
    }
    
    // Construct the YouTube API search URL with appropriate parameters
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&maxResults=$maxResults&publishedAfter=$formattedDate&relevanceLanguage=en&videoEmbeddable=true&key=$apiKey'
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        if (items.isEmpty) {
          // No results found, return fallback videos
          return _createFallbackVideos(query: query);
        }
        
        // Map API response items to YouTubeVideo objects
        final videos = items.map((item) {
          final videoId = item['id']?['videoId'] as String?;
          if (videoId == null) {
            return null;
          }
          
          final snippet = item['snippet'] as Map<String, dynamic>?;
          if (snippet == null) {
            return null;
          }
          
          final title = snippet['title'] as String? ?? 'Untitled Video';
          final channelTitle = snippet['channelTitle'] as String? ?? 'Unknown Channel';
          
          // Parse publishedAt date
          DateTime publishedAt = DateTime.now();
          if (snippet['publishedAt'] != null) {
            try {
              publishedAt = DateTime.parse(snippet['publishedAt'] as String);
            } catch (e) {
              // Failed to parse the date, use current date as fallback
            }
          }
          
          // Try to get the best quality thumbnail available
          String thumbnailUrl = 'https://via.placeholder.com/320x180?text=No+Thumbnail';
          
          if (snippet['thumbnails'] != null) {
            // Try each thumbnail quality in order of preference
            final qualities = ['maxres', 'high', 'medium', 'standard', 'default'];
            
            for (final quality in qualities) {
              if (snippet['thumbnails'][quality] != null && 
                  snippet['thumbnails'][quality]['url'] != null) {
                thumbnailUrl = snippet['thumbnails'][quality]['url'] as String;
                break;
              }
            }
          }
          
          return YouTubeVideo(
            id: videoId,
            title: title,
            thumbnailUrl: thumbnailUrl,
            channelTitle: channelTitle,
            publishedAt: publishedAt,
          );
        })
        .where((video) => video != null)
        .cast<YouTubeVideo>()
        .toList();
        
        // If we got no results, create fallback videos
        if (videos.isEmpty) {
          print('No valid videos found in YouTube results, using fallbacks');
          return _createFallbackVideos(query: query); // Pass the query to fallback videos
        }
        
        // If we got fewer results than requested and this was a hardware comparison,
        // try a more generic search as a backup
        if (videos.length < maxResults && _isHardwareComparisonQuery(query)) {
          try {
            String genericQuery = _makeGenericHardwareQuery(query);
            if (genericQuery != query) {
              print('Using generic query as backup: $genericQuery');
              final backupVideos = await searchVideos(genericQuery, maxResults: maxResults - videos.length);
              videos.addAll(backupVideos);
            }
          } catch (e) {
            print('Error fetching backup videos: $e');
            // Just use what we have if the backup search fails
          }
        }
        
        print('Returning ${videos.length} videos');
        return videos;
      } else {
        print('YouTube API error: ${response.statusCode} - ${response.body}');
        return _createFallbackVideos(query: query); // Pass the query to fallback videos
      }
    } catch (e) {
      print('Error searching YouTube videos: $e');
      return _createFallbackVideos(query: query); // Pass the query to fallback videos
    }
  }
  
  // Create fallback videos in case the YouTube API fails
  List<YouTubeVideo> _createFallbackVideos({String query = ''}) {
    // If we have a query, make it more specific for better fallbacks
    if (query.isNotEmpty) {
      // Get keywords from the query to help construct better titles for fallbacks
      final queryWords = query.toLowerCase().split(' ')
          .where((word) => word.length > 3)
          .toList();
      
      // Use the query to create general fallback videos with more relevant titles
      // These videos don't exist but serve as placeholders until API works
      if (queryWords.isNotEmpty) {
        // Generate more specific titles based on the query keywords
        return [
          YouTubeVideo(
            id: 'YDp73WjNISc', // Placeholder ID
            title: 'Guide for ${queryWords.join(' ')} - Tech Tutorial',
            thumbnailUrl: 'https://i.ytimg.com/vi/YDp73WjNISc/hqdefault.jpg',
            channelTitle: 'Tech Tutorials',
            publishedAt: DateTime.now().subtract(Duration(days: 30)),
          ),
          YouTubeVideo(
            id: '18snEUK9l0Q', // Placeholder ID
            title: 'How To: ${queryWords.join(' ')} - Step by Step',
            thumbnailUrl: 'https://i.ytimg.com/vi/18snEUK9l0Q/hqdefault.jpg',
            channelTitle: 'PC Guides',
            publishedAt: DateTime.now().subtract(Duration(days: 60)),
          ),
          YouTubeVideo(
            id: 'BL4DCEp7blY', // Placeholder ID
            title: 'Expert Tutorial: ${queryWords.join(' ')}',
            thumbnailUrl: 'https://i.ytimg.com/vi/BL4DCEp7blY/hqdefault.jpg',
            channelTitle: 'Hardware Experts',
            publishedAt: DateTime.now().subtract(Duration(days: 90)),
          ),
        ];
      }
    }
    
    // Default generic fallback videos for PC building/hardware
    return [
      YouTubeVideo(
        id: 'YDp73WjNISc',
        title: 'Ultimate PC Components Guide',
        thumbnailUrl: 'https://i.ytimg.com/vi/YDp73WjNISc/hqdefault.jpg',
        channelTitle: 'LinusTechTips',
        publishedAt: DateTime.now().subtract(Duration(days: 30)),
      ),
      YouTubeVideo(
        id: '18snEUK9l0Q',
        title: 'How To Build a PC - Step by Step Guide',
        thumbnailUrl: 'https://i.ytimg.com/vi/18snEUK9l0Q/hqdefault.jpg',
        channelTitle: 'TechSource',
        publishedAt: DateTime.now().subtract(Duration(days: 60)),
      ),
      YouTubeVideo(
        id: 'BL4DCEp7blY',
        title: 'PC Hardware Comparison - Budget vs High-End',
        thumbnailUrl: 'https://i.ytimg.com/vi/BL4DCEp7blY/hqdefault.jpg',
        channelTitle: 'JayzTwoCents',
        publishedAt: DateTime.now().subtract(Duration(days: 90)),
      ),
    ];
  }
  
  // Helper method to refine search queries for better results
  String _refineSearchQuery(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Generic refinement for hardware product searches
    final gpuMatch = RegExp(r'(?:rtx|gtx|rx)\s+\d{4}', caseSensitive: false).firstMatch(lowerQuery);
    if (gpuMatch != null) {
      final gpuModel = gpuMatch.group(0);
      if (gpuModel != null) {
        if (lowerQuery.contains('review')) {
          return '$gpuModel review benchmark';
        }
        return '$gpuModel review';
      }
    }
    
    // Check if it's a comparison query
    if (_isComparisonQuery(lowerQuery)) {
      // For comparisons, add "benchmark comparison" if not already present
      if (!lowerQuery.contains('benchmark') && !lowerQuery.contains('comparison')) {
        return '$query benchmark comparison';
      }
      return query;
    }
    
    // If it's a hardware term but not a comparison
    if (_containsHardwareTerms(lowerQuery) && !_isComparisonQuery(lowerQuery)) {
      return '$query review';
    }
    
    // Add PC building context to general queries
    if (!_containsHardwareTerms(lowerQuery)) {
      return '$query pc building tutorial';
    }
    
    return query;
  }
  
  // Check if a query is likely a hardware comparison
  bool _isHardwareComparisonQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return _isComparisonQuery(lowerQuery) && _containsHardwareTerms(lowerQuery);
  }
  
  // Convert specific model comparisons to more generic hardware category comparisons
  // For example: "RTX 3080 vs RTX 4090" -> "GPU comparison"
  String _makeGenericHardwareQuery(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Hardware component keywords and their generic categories
    final componentMap = {
      'gpu': ['rtx', 'gtx', 'rx', 'graphics card', 'gpu', 'geforce', 'radeon'],
      'cpu': ['ryzen', 'intel', 'threadripper', 'core', 'processor', 'cpu', 'x3d'],
      'motherboard': ['motherboard', 'mobo'],
      'ram': ['ram', 'memory', 'ddr'],
      'storage': ['ssd', 'hdd', 'nvme', 'hard drive'],
      'psu': ['power supply', 'psu'],
      'case': ['case', 'chassis', 'cabinet'],
      'cooling': ['cooler', 'cooling', 'fan', 'aio']
    };
    
    // Check if the query contains specific component comparison indicators
    final components = <String>[];
    
    for (final entry in componentMap.entries) {
      for (final keyword in entry.value) {
        if (lowerQuery.contains(keyword) && !components.contains(entry.key)) {
          components.add(entry.key);
          break;
        }
      }
    }
    
    // If we identified component categories and it's a comparison query
    if (components.isNotEmpty && _isComparisonQuery(lowerQuery)) {
      if (components.length >= 2) {
        return '${components.join(" vs ")} comparison review';
      } else if (components.length == 1) {
        return '${components[0]} comparison benchmark';
      }
    }
    
    return query; // Return original if we couldn't generalise
  }
  
  // Check if query is a comparison between hardware
  bool _isComparisonQuery(String query) {
    return query.contains(' vs ') || 
           query.contains(' versus ') || 
           query.contains(' comparison ') || 
           query.contains(' compared to ') ||
           query.contains(' difference ') ||
           (query.contains(' or ') && _containsHardwareTerms(query));
  }
  
  // Check if query contains hardware terms
  bool _containsHardwareTerms(String query) {
    final hardwareTerms = [
      'cpu', 'gpu', 'processor', 'graphics card', 'motherboard',
      'ram', 'memory', 'ssd', 'hdd', 'storage', 'psu', 'power supply',
      'cooler', 'cooling', 'rtx', 'gtx', 'rx', 'radeon', 'geforce',
      'ryzen', 'intel', 'amd', 'nvidia', 'x3d', 'case', 'fan',
      'cabinet', 'chassis', 'heatsink', 'thermal', 'ddr4', 'ddr5',
      'nvme', 'm.2', 'sata', 'monitor', 'display', 'screen'
    ];
    
    return hardwareTerms.any((term) => query.contains(term));
  }
} 