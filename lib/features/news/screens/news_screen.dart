import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/features/easter_eggs/hidden_fish/hidden_fish.dart';
import 'package:gr0ve/features/news/screens/news_detail_screen.dart';
import 'package:gr0ve/features/news/service/news_service.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';
import 'package:hugeicons/hugeicons.dart';

enum SortOption { newest, oldest, titleAZ, titleZA }

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsArticle> _allArticles = [];
  List<NewsArticle> _filteredArticles = [];

  String searchQuery = "";
  Set<String> selectedCategories = {};
  Set<String> selectedTags = {};
  SortOption currentSort = SortOption.newest;

  List<String> availableCategories = [];
  List<String> availableTags = [];

  bool showFilters = false;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;

  int currentPage = 1;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500 &&
        !isLoadingMore &&
        hasMore &&
        !isLoading &&
        searchQuery.isEmpty) {
      _loadMoreArticles();
    }
  }

  Future<void> _loadMoreArticles() async {
    setState(() => isLoadingMore = true);

    try {
      final nextPage = currentPage + 1;
      final newArticles = await NewsService().fetchPage(nextPage);

      if (newArticles.isEmpty) {
        setState(() {
          hasMore = false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          currentPage = nextPage;
          _allArticles.addAll(newArticles);
          _applyFilters(resetPagination: false);
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingMore = false);
    }
  }

  Future<void> _loadArticles() async {
    setState(() {
      isLoading = true;
      currentPage = 1;
      hasMore = true;
    });

    try {
      final articles = await NewsService().fetchPage(1);

      final categories = <String>{};
      final tags = <String>{};

      for (var article in articles) {
        categories.addAll(article.categories);
        tags.addAll(article.tags);
      }

      setState(() {
        _allArticles = articles;
        _filteredArticles = articles;
        availableCategories = categories.toList()..sort();
        availableTags = tags.toList()..sort();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters({bool resetPagination = true}) {
    setState(() {
      _filteredArticles = _allArticles.where((article) {
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final matchesSearch =
              article.title.toLowerCase().contains(query) ||
              article.author.toLowerCase().contains(query) ||
              article.excerpt?.toLowerCase().contains(query) == true;
          if (!matchesSearch) return false;
        }

        if (selectedCategories.isNotEmpty) {
          final hasCategory = article.categories.any(
            (cat) => selectedCategories.contains(cat),
          );
          if (!hasCategory) return false;
        }

        if (selectedTags.isNotEmpty) {
          final hasTag = article.tags.any((tag) => selectedTags.contains(tag));
          if (!hasTag) return false;
        }

        return true;
      }).toList();

      _applySorting();
    });
  }

  void _applySorting() {
    switch (currentSort) {
      case SortOption.newest:
        _filteredArticles.sort((a, b) {
          if (a.published == null && b.published == null) return 0;
          if (a.published == null) return 1;
          if (b.published == null) return -1;
          return b.published!.compareTo(a.published!);
        });
        break;
      case SortOption.oldest:
        _filteredArticles.sort((a, b) {
          if (a.published == null && b.published == null) return 0;
          if (a.published == null) return 1;
          if (b.published == null) return -1;
          return a.published!.compareTo(b.published!);
        });
        break;
      case SortOption.titleAZ:
        _filteredArticles.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.titleZA:
        _filteredArticles.sort((a, b) => b.title.compareTo(a.title));
        break;
    }
  }

  void _clearAllFilters() {
    setState(() {
      selectedCategories.clear();
      selectedTags.clear();
      searchQuery = "";
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeFiltersCount =
        selectedCategories.length +
        selectedTags.length +
        (searchQuery.isNotEmpty ? 1 : 0);

    final nonSearchFiltersCount =
        selectedCategories.length + selectedTags.length;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          CustomHeader(title: 'NEWS'),
          HiddenFishTrigger(
            id: 'neonfin_after_hours',
            gesture: HiddenFishTriggerGesture.doubleTap,
            child: Text(
              'All articles are provided by Academy chronicle'.capitalized,
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurface.withAlpha(100),
                fontStyle: FontStyle.italic,
                fontSize: 10,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: searchQuery.isNotEmpty
                            ? theme.primaryColor
                            : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300),
                        width: searchQuery.isNotEmpty ? 1.5 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        TextField(
                          onChanged: (value) {
                            setState(() => searchQuery = value);
                            _applyFilters();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search articles...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: searchQuery.isNotEmpty
                                  ? theme.primaryColor
                                  : Colors.grey.shade500,
                            ),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      size: 20,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() => searchQuery = "");
                                      _applyFilters();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        if (searchQuery.isNotEmpty && searchQuery.length > 0)
                          Positioned(
                            right: 48,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 6,
                                minHeight: 6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                _ActionButton(
                  icon: Icons.tune_rounded,
                  isActive: showFilters,
                  badge: nonSearchFiltersCount > 0
                      ? nonSearchFiltersCount
                      : null,
                  onTap: () => setState(() => showFilters = !showFilters),
                ),

                const SizedBox(width: 8),

                _ActionButton(
                  icon: Icons.sort_rounded,
                  onTap: () => _showSortMenu(context),
                ),
              ],
            ),
          ),

          if (!showFilters && activeFiltersCount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...selectedCategories.map(
                      (cat) => _ActiveFilterChip(
                        label: cat,
                        onRemove: () {
                          setState(() {
                            selectedCategories.remove(cat);
                            _applyFilters();
                          });
                        },
                      ),
                    ),

                    ...selectedTags.map(
                      (tag) => _ActiveFilterChip(
                        label: tag,
                        onRemove: () {
                          setState(() {
                            selectedTags.remove(tag);
                            _applyFilters();
                          });
                        },
                      ),
                    ),

                    TextButton.icon(
                      onPressed: _clearAllFilters,
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (showFilters)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (activeFiltersCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$activeFiltersCount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (activeFiltersCount > 0)
                          TextButton(
                            onPressed: _clearAllFilters,
                            child: const Text('Clear All'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: Colors.grey.shade200),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (availableCategories.isNotEmpty) ...[
                            _FilterSection(
                              title: 'Categories',
                              icon: Icons.category_rounded,
                              children: availableCategories.map((category) {
                                final isSelected = selectedCategories.contains(
                                  category,
                                );
                                return _FilterChipItem(
                                  label: category,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedCategories.remove(category);
                                      } else {
                                        selectedCategories.add(category);
                                      }
                                      _applyFilters();
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          if (availableTags.isNotEmpty) ...[
                            _FilterSection(
                              title: 'Tags',
                              icon: Icons.local_offer_rounded,
                              children: availableTags.take(20).map((tag) {
                                final isSelected = selectedTags.contains(tag);
                                return _FilterChipItem(
                                  label: tag,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedTags.remove(tag);
                                      } else {
                                        selectedTags.add(tag);
                                      }
                                      _applyFilters();
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          Expanded(
            child: isLoading
                ? const PremiumLoadingIndicator()
                : _filteredArticles.isEmpty
                ? _buildEmptyState(activeFiltersCount > 0)
                : RefreshIndicator(
                    onRefresh: _loadArticles,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 800;

                        if (isWide) {
                          return GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 500,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: 90,
                                ),
                            itemCount:
                                _filteredArticles.length +
                                (isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _filteredArticles.length) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final article = _filteredArticles[index];
                              return TweenAnimationBuilder<double>(
                                key: ValueKey('grid-article-${article.link}'),
                                duration: Duration(
                                  milliseconds: 500 + (index * 50),
                                ),
                                curve: Curves.easeOutQuart,
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _NewsCard(article: article),
                              );
                            },
                          );
                        }

                        return ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          itemCount:
                              _filteredArticles.length +
                              (isLoadingMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index >= _filteredArticles.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final article = _filteredArticles[index];
                            return TweenAnimationBuilder<double>(
                              key: ValueKey('list-article-${article.link}'),
                              duration: Duration(
                                milliseconds: 500 + (index * 50),
                              ),
                              curve: Curves.easeOutQuart,
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: _NewsCard(article: article),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort by',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _SortOption(
                    icon: Icons.schedule_rounded,
                    title: 'Newest First',
                    isSelected: currentSort == SortOption.newest,
                    onTap: () {
                      setState(() {
                        currentSort = SortOption.newest;
                        _applySorting();
                      });
                      Navigator.pop(context);
                    },
                  ),
                  _SortOption(
                    icon: Icons.history_rounded,
                    title: 'Oldest First',
                    isSelected: currentSort == SortOption.oldest,
                    onTap: () {
                      setState(() {
                        currentSort = SortOption.oldest;
                        _applySorting();
                      });
                      Navigator.pop(context);
                    },
                  ),
                  _SortOption(
                    icon: Icons.sort_by_alpha_rounded,
                    title: 'Title A-Z',
                    isSelected: currentSort == SortOption.titleAZ,
                    onTap: () {
                      setState(() {
                        currentSort = SortOption.titleAZ;
                        _applySorting();
                      });
                      Navigator.pop(context);
                    },
                  ),
                  _SortOption(
                    icon: Icons.sort_by_alpha_rounded,
                    title: 'Title Z-A',
                    isSelected: currentSort == SortOption.titleZA,
                    onTap: () {
                      setState(() {
                        currentSort = SortOption.titleZA;
                        _applySorting();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters
                  ? Icons.filter_list_off_rounded
                  : Icons.newspaper_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No articles match your filters'
                  : 'No articles found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.isActive = false,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive
            ? theme.primaryColor
            : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? theme.primaryColor
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(icon, color: isActive ? Colors.white : null, size: 20),
            onPressed: onTap,
            padding: EdgeInsets.zero,
          ),
          if (badge != null)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FilterSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.15)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_rounded, size: 16, color: theme.primaryColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? theme.primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.primaryColor : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.primaryColor : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: theme.primaryColor)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle article;

  const _NewsCard({required this.article});

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final date = _formatDate(article.published);

    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewsDetailScreen(article: article),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.featuredImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    article.featuredImage!,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 90,
                        height: 110,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedNote01,
                          strokeWidth: 1.5,
                          color:
                              (!isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200)
                                  .withAlpha(150),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 90,
                  height: 110,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedNote01,
                    strokeWidth: 1.5,
                    color:
                        (!isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                            .withAlpha(150),
                  ),
                ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      if (article.excerpt != null &&
                          article.excerpt!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            article.excerpt!,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 11,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              article.author,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
