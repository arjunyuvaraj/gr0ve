import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';

class NewsArticle {
  final String title;
  final String link;
  final String content;
  final String author;
  final DateTime? published;
  final List<String> categories;
  final List<String> tags;
  final String? featuredImage;
  final String? excerpt;
  final int? commentCount;

  NewsArticle({
    required this.title,
    required this.link,
    required this.content,
    required this.author,
    this.published,
    this.categories = const [],
    this.tags = const [],
    this.featuredImage,
    this.excerpt,
    this.commentCount,
  });
}

class NewsService {
  static const baseUrl = 'https://academychronicle.com/feed/';

  /// Fetch all articles by paginating through the RSS feed
  Future<List<NewsArticle>> fetchArticles() async {
    List<NewsArticle> allArticles = [];
    int page = 1;
    bool hasMorePages = true;

    while (hasMorePages && page <= 10) {
      try {
        final pageArticles = await _fetchPage(page);

        if (pageArticles.isEmpty) {
          hasMorePages = false;
        } else {
          allArticles.addAll(pageArticles);
          page++;

          if (pageArticles.length < 10) {
            hasMorePages = false;
          }
        }
      } catch (e) {
        print('Error fetching page $page: $e');
        hasMorePages = false;
      }
    }

    // Remove duplicates based on link
    final uniqueArticles = <String, NewsArticle>{};
    for (var article in allArticles) {
      if (!uniqueArticles.containsKey(article.link)) {
        uniqueArticles[article.link] = article;
      }
    }

    final articles = uniqueArticles.values.toList();

    // Sort newest first
    articles.sort((a, b) {
      if (a.published == null && b.published == null) return 0;
      if (a.published == null) return 1;
      if (b.published == null) return -1;
      return b.published!.compareTo(a.published!);
    });

    return articles;
  }

  /// Fetch a single page of articles with all metadata
  Future<List<NewsArticle>> _fetchPage(int page) async {
    final url = page == 1 ? baseUrl : '$baseUrl?paged=$page';

    final response = await http
        .get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      print('Failed to fetch page $page: ${response.statusCode}');
      return [];
    }

    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    List<NewsArticle> articles = [];

    for (var item in items) {
      // Basic fields
      final title = item.getElement('title')?.innerText ?? 'No title';
      final link = item.getElement('link')?.innerText ?? '';
      final author =
          item.getElement('dc:creator')?.innerText ?? 'Academy Chronicle';

      // Parse publication date
      final pubDate = item.getElement('pubDate')?.innerText;
      DateTime? published = _parseDate(pubDate);

      // Content
      final description = item.getElement('description')?.innerText ?? '';
      final contentEncoded =
          item.getElement('content:encoded')?.innerText ?? '';
      final content = contentEncoded.isNotEmpty ? contentEncoded : description;

      // Excerpt (description is typically the excerpt)
      final excerpt = description;

      // Categories and Tags
      // In WordPress RSS, both categories and tags are in <category> elements
      final List<String> categories = [];
      final List<String> tags = [];

      final categoryElements = item.findElements('category');
      for (var categoryElement in categoryElements) {
        final domain = categoryElement.getAttribute('domain');
        final categoryValue = categoryElement.innerText;

        if (categoryValue.isNotEmpty) {
          if (domain == 'category') {
            categories.add(categoryValue);
          } else if (domain == 'post_tag') {
            tags.add(categoryValue);
          } else {
            // If no domain specified, treat as category
            categories.add(categoryValue);
          }
        }
      }

      // Featured Image
      // WordPress can include featured images in multiple ways:
      // 1. <media:content> tag
      // 2. <enclosure> tag
      // 3. First image in content:encoded
      String? featuredImage = _extractFeaturedImage(item, content);

      // Comment count (if available)
      int? commentCount;
      final commentRssElement = item.getElement('slash:comments');
      if (commentRssElement != null) {
        commentCount = int.tryParse(commentRssElement.innerText);
      }

      articles.add(
        NewsArticle(
          title: title,
          link: link,
          content: content,
          author: author,
          published: published,
          categories: categories,
          tags: tags,
          featuredImage: featuredImage,
          excerpt: excerpt,
          commentCount: commentCount,
        ),
      );
    }

    return articles;
  }

  /// Parse date from various formats
  DateTime? _parseDate(String? pubDate) {
    if (pubDate == null || pubDate.isEmpty) return null;

    try {
      return HttpDate.parse(pubDate);
    } catch (_) {
      try {
        return DateTime.parse(pubDate);
      } catch (_) {
        try {
          final format = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z');
          return format.parse(pubDate);
        } catch (_) {
          return null;
        }
      }
    }
  }

  /// Extract featured image from various sources
  String? _extractFeaturedImage(xml.XmlElement item, String content) {
    // Try media:content tag (most reliable for WordPress)
    final mediaContent = item.getElement('media:content');
    if (mediaContent != null) {
      final url = mediaContent.getAttribute('url');
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    // Try media:thumbnail tag
    final mediaThumbnail = item.getElement('media:thumbnail');
    if (mediaThumbnail != null) {
      final url = mediaThumbnail.getAttribute('url');
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    // Try enclosure tag
    final enclosure = item.getElement('enclosure');
    if (enclosure != null) {
      final type = enclosure.getAttribute('type');
      if (type != null && type.startsWith('image/')) {
        final url = enclosure.getAttribute('url');
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    }

    // Try to extract first image from content
    final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false);
    final match = imgRegex.firstMatch(content);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  /// Fetch specific number of recent articles
  Future<List<NewsArticle>> fetchRecentArticles({int count = 50}) async {
    final pagesNeeded = (count / 10).ceil();

    List<NewsArticle> allArticles = [];

    for (int page = 1; page <= pagesNeeded; page++) {
      try {
        final pageArticles = await _fetchPage(page);

        if (pageArticles.isEmpty) break;

        allArticles.addAll(pageArticles);

        if (allArticles.length >= count) break;
      } catch (e) {
        print('Error fetching page $page: $e');
        break;
      }
    }

    // Remove duplicates
    final uniqueArticles = <String, NewsArticle>{};
    for (var article in allArticles) {
      if (!uniqueArticles.containsKey(article.link)) {
        uniqueArticles[article.link] = article;
      }
    }

    final articles = uniqueArticles.values.toList();

    // Sort newest first
    articles.sort((a, b) {
      if (a.published == null && b.published == null) return 0;
      if (a.published == null) return 1;
      if (b.published == null) return -1;
      return b.published!.compareTo(a.published!);
    });

    return articles.take(count).toList();
  }

  /// Get all unique categories from articles
  Future<List<String>> getCategories() async {
    final articles = await fetchArticles();
    final categories = <String>{};

    for (var article in articles) {
      categories.addAll(article.categories);
    }

    return categories.toList()..sort();
  }

  /// Get all unique tags from articles
  Future<List<String>> getTags() async {
    final articles = await fetchArticles();
    final tags = <String>{};

    for (var article in articles) {
      tags.addAll(article.tags);
    }

    return tags.toList()..sort();
  }

  /// Filter articles by category
  Future<List<NewsArticle>> getArticlesByCategory(String category) async {
    final articles = await fetchArticles();
    return articles.where((article) {
      return article.categories.any(
        (cat) => cat.toLowerCase() == category.toLowerCase(),
      );
    }).toList();
  }

  /// Filter articles by tag
  Future<List<NewsArticle>> getArticlesByTag(String tag) async {
    final articles = await fetchArticles();
    return articles.where((article) {
      return article.tags.any((t) => t.toLowerCase() == tag.toLowerCase());
    }).toList();
  }
}
