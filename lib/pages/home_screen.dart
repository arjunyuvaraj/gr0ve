import 'package:firebase_auth/firebase_auth.dart';
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
  User? user;
  String? email;
  static const _teacherSpreadsheetId =
      '1Ocm7wpxK9_xlkJGe9z8zH-I5TPsio1fZAxUf0rNs5Jk';
  static const _teacherWorksheetTitle = 'Absences';
  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    email = user?.email ?? 'null';
    WidgetsBinding.instance.addObserver(this);
    _initialLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initialLoad() async {
    await Future.wait([
      StarredTeacherService.load(),
      StarredBusService.load(),
      fetchAllBuses(),
      fetchAbsences(),
    ]);

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _refreshData() async {
    await Future.wait([fetchAllBuses(), fetchAbsences()]);
    if (mounted) setState(() {});
  }

  Future<void> fetchAbsences() async {
    try {
      absenceList = await fetchGoogleSheetAbsences(
        spreadsheetId: _teacherSpreadsheetId,
        worksheetTitle: _teacherWorksheetTitle,
      );
    } catch (_) {
      absenceList = {};
    }
  }

  Future<void> fetchAllBuses() async {
    allBuses = await fetchBusRoutes();
  }

  String getTeacherStatus(String fullName) {
    for (final entry in absenceList.entries) {
      final docKey = entry.key;
      final period = entry.value;

      if (matchesTeacher(docKey, fullName)) {
        return period;
      }
    }

    return "Present";
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const CustomHeader(title: "GR0VE", subtitle: "FOR BCA"),
              if (email!.contains("@bergen.org")) const SizedBox(height: 24),
              if (email!.contains("@bergen.org"))
                const Text(
                  "STARRED TEACHERS",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              if (email!.contains("@bergen.org")) const SizedBox(height: 12),
              if (email!.contains("@bergen.org"))
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
                            "No starred teachers yet... try heading to the teachers absense page!",
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
                          "No starred buses yet... try heading to the buses page!",
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
                          isLoggedIn: isLoggedIn,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
