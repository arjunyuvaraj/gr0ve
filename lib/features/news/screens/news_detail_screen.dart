import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/news/service/news_service.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailScreen({super.key, required this.article});

  String _formatFullDate(DateTime? date) {
    if (date == null) return 'No date available';

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _openArticleInBrowser(BuildContext context) async {
    final url = Uri.parse(article.link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open article')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF111111) : Color(0xFFF8F9F9),
        shadowColor: isDark ? Color(0xFF111111) : Color(0xFFF8F9F9),
        surfaceTintColor: isDark ? Color(0xFF111111) : Color(0xFFF8F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open in browser',
            onPressed: () => _openArticleInBrowser(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: article.link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Academy Chronicle badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.newspaper_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ACADEMY CHRONICLE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 24),

                // Meta information
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Author
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Written by',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              article.author,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        height: 50,
                        width: 1,
                        color: Colors.grey.shade400,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),

                      // Date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Published',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatFullDate(article.published),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Article content
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Html(
                      data: article.content,
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(17),
                          lineHeight: LineHeight(1.7),
                          maxLines: null,
                        ),
                        "p": Style(
                          margin: Margins.only(bottom: 20),
                          fontSize: FontSize(17),
                          lineHeight: LineHeight(1.7),
                          maxLines: null,
                        ),
                        "div": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          maxLines: null,
                        ),
                        "span": Style(maxLines: null),
                        "h1": Style(
                          fontSize: FontSize(26),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(top: 32, bottom: 16),
                          maxLines: null,
                        ),
                        "h2": Style(
                          fontSize: FontSize(22),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(top: 28, bottom: 14),
                          maxLines: null,
                        ),
                        "h3": Style(
                          fontSize: FontSize(19),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(top: 24, bottom: 12),
                          maxLines: null,
                        ),
                        "img": Style(
                          margin: Margins.only(top: 24, bottom: 24),
                          padding: HtmlPaddings.zero,
                          maxLines: null,
                        ),
                        "a": Style(
                          color: theme.primaryColor,
                          textDecoration: TextDecoration.underline,
                          maxLines: null,
                        ),
                        "blockquote": Style(
                          border: Border(
                            left: BorderSide(
                              color: theme.primaryColor,
                              width: 4,
                            ),
                          ),
                          margin: Margins.only(top: 20, bottom: 20, left: 0),
                          padding: HtmlPaddings.only(left: 20),
                          fontStyle: FontStyle.italic,
                          maxLines: null,
                        ),
                        "ul": Style(
                          margin: Margins.only(bottom: 20),
                          padding: HtmlPaddings.only(left: 24),
                          maxLines: null,
                        ),
                        "ol": Style(
                          margin: Margins.only(bottom: 20),
                          padding: HtmlPaddings.only(left: 24),
                          maxLines: null,
                        ),
                        "li": Style(
                          margin: Margins.only(bottom: 8),
                          lineHeight: LineHeight(1.6),
                          maxLines: null,
                        ),
                        "figure": Style(
                          margin: Margins.only(top: 24, bottom: 24),
                          padding: HtmlPaddings.zero,
                          maxLines: null,
                        ),
                        "figcaption": Style(
                          fontSize: FontSize(14),
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                          margin: Margins.only(top: 8),
                          maxLines: null,
                        ),
                      },
                      extensions: [
                        TagExtension(
                          tagsToExtend: {"img"},
                          builder: (extensionContext) {
                            final src = extensionContext.attributes['src'];
                            if (src == null || src.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  src,
                                  width: constraints.maxWidth,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: constraints.maxWidth,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          width: constraints.maxWidth,
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      onLinkTap: (url, _, __) async {
                        if (url != null) {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        }
                      },
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Bottom action card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Read more on',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Academy Chronicle',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openArticleInBrowser(context),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
