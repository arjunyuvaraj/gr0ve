import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/components/custom_teacher_card.dart';
import 'package:gr0ve/components/custom_bus_card.dart';
import 'package:gr0ve/services/starred_teacher_service.dart';
import 'package:gr0ve/services/teacher_service.dart';
import 'package:gr0ve/services/starred_bus_service.dart';
import 'package:gr0ve/services/bus_service.dart';
import 'package:gr0ve/utilities/data/teacher_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool isLoading = true;
  Map<String, String> absenceList = {};
  List<BusRoute> allBuses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initialLoad() async {
    await Future.wait([
      StarredTeacherService.load(),
      StarredBusService.load(),
      fetchAllBuses(),
      fetchAbsences(),
    ]);

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> fetchAbsences() async {
    try {
      absenceList = await fetchGoogleDocMap(
        'https://docs.google.com/document/d/e/2PACX-1vT_iK6QcUDVJoo_A6Enz5eizn4PzAWGfJBGo1vaC6T2y_0vHaYcL3ZlwcPN4H6pNCNEExNKGwxyktWC/pub',
      );
    } catch (_) {
      absenceList = {};
    }
  }

  Future<void> fetchAllBuses() async {
    allBuses = await fetchBusRoutes();
  }

  String getTeacherStatus(String fullName) {
    return findAbsenceForTeacher(absenceList, fullName) ?? "Present";
  }

  String? findAbsenceForTeacher(
    Map<String, String> absenceMap,
    String teacherName,
  ) {
    for (final entry in absenceMap.entries) {
      if (matchesTeacher(entry.key, teacherName)) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const CustomHeader(title: "GR0VE", subtitle: "FOR BCA"),
            const SizedBox(height: 24),

            const Text(
              "STARRED TEACHERS",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ValueListenableBuilder<Set<String>>(
              valueListenable: StarredTeacherService.starredTeachers,
              builder: (context, starred, _) {
                final starredTeachers = teacherList.values
                    .map((t) => Map<String, dynamic>.from(t))
                    .where((t) => starred.contains(t['name']))
                    .toList();

                if (starredTeachers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        "Nothing here",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: starredTeachers.map((t) {
                    final name = t['name'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CustomTeacherCard(
                        name: name,
                        department: t['department'],
                        email: t['email'],
                        status: getTeacherStatus(name),
                        showStar: true,
                        starred: true,
                        onStarTap: () =>
                            StarredTeacherService.toggleTeacher(name),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 32),

            const Text(
              "FAVORITE BUSES",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ValueListenableBuilder<Set<String>>(
              valueListenable: StarredBusService.starredTowns,
              builder: (context, starred, _) {
                final favoriteBuses = allBuses
                    .where((b) => starred.contains(b.town))
                    .toList();

                if (favoriteBuses.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        "Nothing here",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: favoriteBuses.map((b) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CustomBusCard(
                        route: b,
                        starred: true,
                        onStarTap: () => StarredBusService.toggleTown(b.town),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
