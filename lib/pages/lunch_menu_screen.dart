import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LunchMenuScreen extends StatefulWidget {
  const LunchMenuScreen({super.key});

  @override
  State<LunchMenuScreen> createState() => _LunchMenuScreenState();
}

class _LunchMenuScreenState extends State<LunchMenuScreen> {
  List<DayMenu> menuData = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchLunchMenu();
  }

  Future<void> fetchLunchMenu() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final now = DateTime.now();
      final y = now.year;
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');

      final url =
          'https://bergen.api.nutrislice.com/menu/api/weeks/school/'
          'bergen-academy/menu-type/lunch/$y/$m/$d?format=json';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Status ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final days = (data['days'] as List)
          .map((day) => DayMenu.fromJson(day))
          .toList();

      setState(() {
        menuData = days;
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        error = 'Lunch menu unavailable';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchLunchMenu,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: ListView(
        children: [
          const Text(
            'Lunch Menu',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Because standing in line without knowing is a gamble.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          ...menuData.map((day) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(
                  day.date,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                children: day.menuItems.map((item) {
                  return ListTile(
                    title: Text(item.name),
                    subtitle: item.nutrition != null
                        ? Text(
                            'Calories: ${item.nutrition!.calories}',
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    trailing: item.allergens.isNotEmpty
                        ? Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade400,
                            size: 20,
                          )
                        : null,
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class DayMenu {
  final String date;
  final List<MenuItem> menuItems;

  DayMenu({required this.date, required this.menuItems});

  factory DayMenu.fromJson(Map<String, dynamic> json) {
    final items = (json['menu_items'] as List? ?? [])
        .where(
          (item) => item['food'] != null && item['is_section_title'] != true,
        )
        .map((item) => MenuItem.fromJson(item['food']))
        .toList();

    return DayMenu(date: json['date'] ?? '', menuItems: items);
  }
}

class MenuItem {
  final String name;
  final Nutrition? nutrition;
  final List<String> allergens;

  MenuItem({required this.name, this.nutrition, this.allergens = const []});

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final nutritionData = json['rounded_nutrition_info'];
    final allergenList = json['food_allergens'] as List? ?? [];

    return MenuItem(
      name: json['name'] ?? 'Unknown',
      nutrition: nutritionData != null
          ? Nutrition.fromJson(nutritionData)
          : null,
      allergens: allergenList
          .map((a) => a['allergen']?['name']?.toString() ?? '')
          .where((a) => a.isNotEmpty)
          .toList(),
    );
  }
}

class Nutrition {
  final String calories;

  Nutrition({required this.calories});

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(calories: json['calories']?.toString() ?? '0');
  }
}
