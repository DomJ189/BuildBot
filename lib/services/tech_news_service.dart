import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import '../models/news_article.dart';

class TechNewsService {
  static const String _tomshardwareUrl = 'https://www.tomshardware.com/uk';
  static const String _techpowerupUrl = 'https://www.techpowerup.com';
  static const String _pcgamerUrl = 'https://www.pcgamer.com';
  
  TechNewsService();

  Future<List<NewsArticle>> getLatestTechNews() async {
    final List<NewsArticle> articles = [];
    
    // Fetch from Tom's Hardware
    final tomsHardwareArticles = await _fetchTomsHardwareNews();
    articles.addAll(tomsHardwareArticles);
    
    // Fetch from TechPowerUp
    final techPowerUpArticles = await _fetchTechPowerUpNews();
    articles.addAll(techPowerUpArticles);
    
    // Fetch from PCGamer
    final pcGamerArticles = await _fetchPCGamerNews();
    articles.addAll(pcGamerArticles);
    
    // Sort by date and return
    articles.sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return articles;
  }

  Future<List<NewsArticle>> _fetchTomsHardwareNews() async {
    try {
      final response = await http.get(Uri.parse(_tomshardwareUrl));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final articles = document.querySelectorAll('.article');
        
        return articles.map((article) {
          final title = article.querySelector('h2')?.text ?? '';
          final link = article.querySelector('a')?.attributes['href'] ?? '';
          final date = article.querySelector('.date')?.text ?? '';
          
          DateTime publishDate;
          try {
            publishDate = DateTime.parse(date);
          } catch (e) {
            // Fallback to current date if parsing fails
            publishDate = DateTime.now();
          }
          
          return NewsArticle(
            title: title,
            url: link,
            source: 'Tom\'s Hardware',
            publishDate: publishDate,
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching Tom\'s Hardware news: $e');
    }
    return [];
  }

  Future<List<NewsArticle>> _fetchTechPowerUpNews() async {
    try {
      final response = await http.get(Uri.parse('$_techpowerupUrl/rss/news.xml'));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        
        return items.map((item) {
          final title = item.findElements('title').first.text;
          final link = item.findElements('link').first.text;
          final date = item.findElements('pubDate').first.text;
          
          DateTime publishDate;
          try {
            publishDate = DateTime.parse(date);
          } catch (e) {
            // Try alternative date format
            try {
              // RFC 822 format often used in RSS
              final dateStr = date.replaceAll(' GMT', ' +0000');
              publishDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z').parse(dateStr);
            } catch (e2) {
              // Fallback to current date
              publishDate = DateTime.now();
            }
          }
          
          return NewsArticle(
            title: title,
            url: link,
            source: 'TechPowerUp',
            publishDate: publishDate,
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching TechPowerUp news: $e');
    }
    return [];
  }

  Future<List<NewsArticle>> _fetchPCGamerNews() async {
    try {
      final response = await http.get(Uri.parse(_pcgamerUrl));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final articles = document.querySelectorAll('.article');
        
        return articles.map((article) {
          final title = article.querySelector('h3')?.text ?? '';
          final link = article.querySelector('a')?.attributes['href'] ?? '';
          final date = article.querySelector('time')?.attributes['datetime'] ?? '';
          
          DateTime publishDate;
          try {
            publishDate = DateTime.parse(date);
          } catch (e) {
            // Fallback to current date if parsing fails
            publishDate = DateTime.now();
          }
          
          return NewsArticle(
            title: title,
            url: link,
            source: 'PCGamer',
            publishDate: publishDate,
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching PCGamer news: $e');
    }
    return [];
  }
} 