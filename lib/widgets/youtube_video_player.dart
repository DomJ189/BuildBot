import 'package:flutter/material.dart';
import '../models/youtube_video.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class YouTubeVideoPlayer extends StatelessWidget {
  final YouTubeVideo video;
  
  const YouTubeVideoPlayer({
    super.key,
    required this.video,
  });

  // Extract the URL launch function for reusability
  Future<void> _launchYouTubeVideo() async {
    // Create various URL formats for different platforms
    final Uri youtubeAppUri = Uri.parse(video.appUrl);
    final Uri youtubeDeepLinkUri = Uri.parse(video.deepLinkUrl);
    final Uri youtubeWebUri = Uri.parse(video.watchUrl);
    
    try {
      // First try to launch with the deep link format (most reliable for apps)
      bool launched = await launchUrl(
        youtubeDeepLinkUri,
        mode: LaunchMode.externalApplication,
      );
      
      // If the deep link fails, try the app URL format
      if (!launched) {
        launched = await launchUrl(
          youtubeAppUri,
          mode: LaunchMode.externalApplication,
        );
        
        // If the app URL also fails, fall back to the web browser
        if (!launched) {
          if (!await launchUrl(
            youtubeWebUri,
            mode: LaunchMode.externalApplication,
          )) {
            throw Exception('Could not launch YouTube');
          }
        }
      }
    } catch (e) {
      // If opening the app fails, try the web URL as a fallback
      debugPrint('Error launching YouTube app: $e');
      try {
        if (!await launchUrl(
          youtubeWebUri,
          mode: LaunchMode.externalApplication,
        )) {
          throw Exception('Could not launch YouTube');
        }
      } catch (webError) {
        debugPrint('Error launching YouTube in browser: $webError');
      }
    }
  }

  // Format the published date
  String _formatPublishedDate() {
    final DateFormat formatter = DateFormat('MMM d, yyyy');
    return formatter.format(video.publishedAt);
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme brightness
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: isDarkTheme ? 4 : 3,
      color: isDarkTheme ? Color(0xFF2A2A2A) : null, // Dark background for dark theme
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Make the thumbnail area tappable with its own InkWell
          Stack(
            children: [
              // Image with error handling and loading state
              AspectRatio(
                aspectRatio: 16 / 9,
                child: InkWell(
                  onTap: _launchYouTubeVideo,
                  child: Hero(
                    tag: 'thumbnail-${video.id}',
                    child: Image.network(
                      video.thumbnailUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          color: isDarkTheme ? Colors.grey[800] : Colors.grey[300],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(height: 4),
                                Text('Image not available',
                                    style: TextStyle(color: isDarkTheme ? Colors.grey[400] : Colors.grey[700])),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // YouTube play button overlay
              Positioned.fill(
                child: InkWell(
                  onTap: _launchYouTubeVideo,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Duration tag
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ondemand_video,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'YouTube',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Video details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkTheme ? Colors.white : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        video.channelTitle,
                        style: TextStyle(
                          color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      _formatPublishedDate(),
                      style: TextStyle(
                        color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Watch on YouTube button
                InkWell(
                  onTap: _launchYouTubeVideo,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Watch on YouTube',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 