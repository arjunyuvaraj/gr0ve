import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:icons_plus/icons_plus.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';

class LunchMenuScreen extends StatefulWidget {
  const LunchMenuScreen({super.key});

  @override
  State<LunchMenuScreen> createState() => _LunchMenuScreenState();
}

class _LunchMenuScreenState extends State<LunchMenuScreen> {
  bool loading = true;
  String? error;

  List<MenuEntry> allItems = [];
  List<MenuEntry> filteredItems = [];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTodayMenu();
    searchController.addListener(_applySearch);
    FirebaseAnalytics.instance.logEvent(name: 'screen_lunch');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTodayMenu() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final baseUrl =
          'https://bergen.api.nutrislice.com/menu/api/weeks/school/'
          'bergen-academy/menu-type/lunch/'
          '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}?format=json';

      final url = kIsWeb
          ? 'https://api.allorigins.win/get?url=${Uri.encodeComponent(baseUrl)}'
          : baseUrl;

      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception();

      final dynamic data;
      if (kIsWeb) {
        final proxyData = json.decode(res.body);
        data = json.decode(proxyData['contents']);
      } else {
        data = json.decode(res.body);
      }
      final days = data['days'] as List;

      final today = days.firstWhere(
        (d) => d['date'] == todayStr && (d['menu_items'] as List).isNotEmpty,
        orElse: () => null,
      );

      if (today == null) {
        throw Exception('No lunch today');
      }

      final items = today['menu_items'] as List;

      String currentStation = '';
      final List<MenuEntry> results = [];

      for (final item in items) {
        if (item['is_section_title'] == true &&
            item['food'] == null &&
            item['text'] != null) {
          currentStation = item['text'];
          continue;
        }

        if (item['food'] != null) {
          results.add(
            MenuEntry(
              station: currentStation,
              food: MenuItem.fromJson(item['food']),
            ),
          );
        }
      }

      setState(() {
        allItems = results;
        filteredItems = results;
        loading = false;
      });
    } catch (_) {
      setState(() {
        error = 'No lunch data available today';
        loading = false;
      });
    }
  }

  void _applySearch() {
    final query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() => filteredItems = allItems);
      return;
    }

    setState(() {
      filteredItems = allItems.where((entry) {
        final food = entry.food;
        return food.name.toLowerCase().contains(query) ||
            food.description.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textSize = context.text;

    return Column(
      children: [
        CustomHeader(title: 'LUNCH'.capitalized),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search food...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: loading
              ? const PremiumLoadingIndicator()
              : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 64,
                          color: colors.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: textSize.titleMedium?.copyWith(
                            color: colors.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : filteredItems.isEmpty
              ? Center(
                  child: Text(
                    'No items match your search.',
                    style: textSize.bodyLarge?.copyWith(
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchTodayMenu,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            String? lastStation;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: filteredItems.map((entry) {
                                final widgets = <Widget>[];

                                if (entry.station.isNotEmpty &&
                                    entry.station != lastStation) {
                                  widgets.add(
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 24,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        entry.station,
                                        style: textSize.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                  lastStation = entry.station;
                                }

                                widgets.add(_MenuItemCard(item: entry.food));

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: widgets,
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const _MenuItemCard({required this.item});

  Map<String, dynamic> _getAllergenInfo(String allergen) {
    final lower = allergen.toLowerCase();

    if (lower.contains('milk') || lower.contains('dairy')) {
      return {
        'icon': Icon(Bootstrap.cup_fill, size: 14, color: Colors.white),
        'label': 'Milk',
        'color': Colors.blue.withAlpha(150),
      };
    }

    if (lower.contains('egg')) {
      return {
        'icon': const Icon(Bootstrap.egg_fill, size: 14, color: Colors.white),
        'label': 'Egg',
        'color': Colors.orange.withAlpha(150),
      };
    }

    if (lower.contains('wheat') || lower.contains('gluten')) {
      return {
        'icon': const Icon(
          Bootstrap.exclamation_triangle_fill,
          size: 14,
          color: Colors.white,
        ),
        'label': 'Wheat',
        'color': Colors.brown.withAlpha(150),
      };
    }

    if (lower.contains('soy')) {
      return {
        'icon': const Icon(Bootstrap.flower1, size: 14, color: Colors.white),
        'label': 'Soy',
        'color': Colors.green.withAlpha(150),
      };
    }

    if (lower.contains('sesame')) {
      return {
        'icon': const Icon(Bootstrap.asterisk, size: 14, color: Colors.white),
        'label': 'Sesame',
        'color': Colors.amber.shade400.withAlpha(150),
      };
    }

    if (lower.contains('tree nut') || lower.contains('nuts')) {
      return {
        'icon': const Icon(
          Bootstrap.exclamation_circle_fill,
          size: 14,
          color: Colors.white,
        ),
        'label': 'Nuts',
        'color': Colors.brown.shade600,
      };
    }

    if (lower.contains('peanut')) {
      return {
        'icon': const Icon(
          Bootstrap.exclamation_circle_fill,
          size: 14,
          color: Colors.white,
        ),
        'label': 'Peanut',
        'color': Colors.brown.shade800,
      };
    }

    if (lower.contains('fish')) {
      return {
        'icon': const Icon(
          FontAwesome.fish_solid,
          size: 14,
          color: Colors.white,
        ),
        'label': 'Fish',
        'color': Colors.blueAccent,
      };
    }

    if (lower.contains('shellfish') || lower.contains('crustacean')) {
      return {
        'icon': const Icon(
          FontAwesome.shrimp_solid,
          size: 14,
          color: Colors.white,
        ),
        'label': 'Shellfish',
        'color': Colors.pink,
      };
    }

    return {
      'icon': const Icon(
        Icons.warning_amber_rounded,
        size: 14,
        color: Colors.white,
      ),
      'label': allergen,
      'color': Colors.orange,
    };
  }

  void _showNutritionDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (item.nutrition == null || item.nutrition!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No nutrition information available'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.description.isNotEmpty) ...[
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: colors.onSurface.withOpacity(0.1)),
                const SizedBox(height: 12),
              ],
              const Text(
                'Nutrition Facts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...item.nutrition!.entries.map((entry) {
                final key = _formatNutritionKey(entry.key);
                final value = entry.value?.toString() ?? 'N/A';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(value),
                    ],
                  ),
                );
              }),
              if (item.icons.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: colors.onSurface.withOpacity(0.1)),
                const SizedBox(height: 8),
                const Text(
                  'Allergens',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.icons.map((icon) {
                    final info = _getAllergenInfo(icon.help);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: info['color'],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          info['icon'] as Widget,
                          const SizedBox(width: 6),
                          Text(
                            info['label'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatNutritionKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        shadowColor: colors.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _showNutritionDialog(context),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colors.onSurface.withOpacity(0.3),
                    ),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
                if (item.icons.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.icons.map((icon) {
                      final info = _getAllergenInfo(icon.help);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: info['color'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            info['icon'] as Widget,
                            const SizedBox(width: 4),
                            Text(
                              info['label'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MenuEntry {
  final String station;
  final MenuItem food;

  MenuEntry({required this.station, required this.food});
}

class MenuItem {
  final String name;
  final String description;
  final List<FoodIcon> icons;
  final Map<String, dynamic>? nutrition;

  MenuItem({
    required this.name,
    required this.description,
    required this.icons,
    this.nutrition,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      nutrition: json['rounded_nutrition_info'],
      icons: (json['icons']?['food_icons'] as List? ?? [])
          .map((i) => FoodIcon.fromJson(i))
          .toList(),
    );
  }
}

class FoodIcon {
  final String help;

  FoodIcon({required this.help});

  factory FoodIcon.fromJson(Map<String, dynamic> json) {
    return FoodIcon(help: json['sprite']?['help_text'] ?? '');
  }
}
