import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/reddit_post.dart';

// RedditLinkCard is a widget that displays a card with a Reddit post title, selftext, and a link to the Reddit post.
class RedditLinkCard extends StatelessWidget {
  final RedditPost post;
  
  const RedditLinkCard({
    Key? key, 
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchRedditUrl(post.url),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade900 
              : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Red banner with Reddit
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7.0),
                  topRight: Radius.circular(7.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reddit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Image.network(
                    'https://www.redditstatic.com/desktop2x/img/favicon/favicon-32x32.png', // Reddit logo
                    height: 20,
                    width: 20,
                  ),
                ],
              ),
            ),
            
            // Post title and community
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "From the ${post.subreddit} community on Reddit: ${post.title}",
                    style: TextStyle(
                      color: Colors.blue.shade500,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Add the selftext snippet if available
                  if (post.selftext.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade800 
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        post.selftext.length > 200 
                            ? '${post.selftext.substring(0, 200)}...'
                            : post.selftext,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey.shade200 
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 8.0),
                  Text(
                    "Explore this post and more from the ${post.subreddit} community",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey.shade400 
                          : Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Launch the Reddit URL
  Future<void> _launchRedditUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
} 