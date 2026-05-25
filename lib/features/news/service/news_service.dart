import 'package:flutter/foundation.dart';
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
  static const baseUrl = 'https://academychronicle.org/feed/';

  Future<List<NewsArticle>> fetchArticles() async {
    return fetchPage(1);
  }

  Future<List<NewsArticle>> fetchPage(int page) async {
    final url = page == 1 ? baseUrl : '$baseUrl?paged=$page';

    try {
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
        if (kDebugMode)
          print('Failed to fetch page $page: ${response.statusCode}');
        return [];
      }

      final document = xml.XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      List<NewsArticle> articles = [];

      for (var item in items) {
        final title = item.getElement('title')?.innerText ?? 'No title';
        final link = item.getElement('link')?.innerText ?? '';
        final author =
            item.getElement('dc:creator')?.innerText ?? 'Academy Chronicle';

        final pubDate = item.getElement('pubDate')?.innerText;
        DateTime? published = _parseDate(pubDate);

        final description = item.getElement('description')?.innerText ?? '';
        final contentEncoded =
            item.getElement('content:encoded')?.innerText ?? '';
        final content = contentEncoded.isNotEmpty
            ? contentEncoded
            : description;

        final excerpt = description;

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
              categories.add(categoryValue);
            }
          }
        }

        String? featuredImage = _extractFeaturedImage(item, content);

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

      articles.sort((a, b) {
        if (a.published == null && b.published == null) return 0;
        if (a.published == null) return 1;
        if (b.published == null) return -1;
        return b.published!.compareTo(a.published!);
      });

      return articles;
    } catch (e) {
      if (kDebugMode) print('Error fetching news page $page: $e');
      return [];
    }
  }

  DateTime? _parseDate(String? pubDate) {
    if (pubDate == null || pubDate.isEmpty) return null;

    try {
      final format = DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz');
      return format.parse(pubDate);
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

  String? _extractFeaturedImage(xml.XmlElement item, String content) {
    final mediaContent = item.getElement('media:content');
    if (mediaContent != null) {
      final url = mediaContent.getAttribute('url');
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    final mediaThumbnail = item.getElement('media:thumbnail');
    if (mediaThumbnail != null) {
      final url = mediaThumbnail.getAttribute('url');
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

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

    final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false);
    final match = imgRegex.firstMatch(content);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  Future<List<NewsArticle>> fetchRecentArticles({int count = 50}) async {
    final pagesNeeded = (count / 10).ceil();

    List<NewsArticle> allArticles = [];

    for (int page = 1; page <= pagesNeeded; page++) {
      try {
        final pageArticles = await fetchPage(page);

        if (pageArticles.isEmpty) break;

        allArticles.addAll(pageArticles);

        if (allArticles.length >= count) break;
      } catch (e) {
        print('Error fetching page $page: $e');
        break;
      }
    }

    final uniqueArticles = <String, NewsArticle>{};
    for (var article in allArticles) {
      if (!uniqueArticles.containsKey(article.link)) {
        uniqueArticles[article.link] = article;
      }
    }

    final articles = uniqueArticles.values.toList();

    articles.sort((a, b) {
      if (a.published == null && b.published == null) return 0;
      if (a.published == null) return 1;
      if (b.published == null) return -1;
      return b.published!.compareTo(a.published!);
    });

    return articles.take(count).toList();
  }

  Future<List<String>> getCategories() async {
    final articles = await fetchArticles();
    final categories = <String>{};

    for (var article in articles) {
      categories.addAll(article.categories);
    }

    return categories.toList()..sort();
  }

  Future<List<String>> getTags() async {
    final articles = await fetchArticles();
    final tags = <String>{};

    for (var article in articles) {
      tags.addAll(article.tags);
    }

    return tags.toList()..sort();
  }

  Future<List<NewsArticle>> getArticlesByCategory(String category) async {
    final articles = await fetchArticles();
    return articles.where((article) {
      return article.categories.any(
        (cat) => cat.toLowerCase() == category.toLowerCase(),
      );
    }).toList();
  }

  Future<List<NewsArticle>> getArticlesByTag(String tag) async {
    final articles = await fetchArticles();
    return articles.where((article) {
      return article.tags.any((t) => t.toLowerCase() == tag.toLowerCase());
    }).toList();
  }
}
