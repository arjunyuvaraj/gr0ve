import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/components/custom_teacher_card.dart';
import 'package:gr0ve/components/custom_bus_card.dart';
import 'package:gr0ve/services/starred_teacher_service.dart';
import 'package:gr0ve/services/teacher_service.dart';
import 'package:gr0ve/services/starred_bus_service.dart';
import 'package:gr0ve/services/bus_service.dart';
import 'package:gr0ve/utilities/teacher_utils.dart';

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

  static const _spreadsheetId = '1Ocm7wpxK9_xlkJGe9z8zH-I5TPsio1fZAxUf0rNs5Jk';
  static const _worksheetTitle = 'Absences';

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    email = user?.email ?? '';
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    await Future.wait([
      StarredTeacherService.load(),
      StarredBusService.load(),
      initGSheets(), // <-- ensure GSheets is initialized
      _loadAbsences(),
      _loadBuses(),
    ]);

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _refresh() async {
    await Future.wait([_loadAbsences(), _loadBuses()]);
    if (mounted) setState(() {});
  }

  Future<void> _loadAbsences() async {
    absenceList = await fetchGoogleSheetAbsences(
      spreadsheetId: _spreadsheetId,
      worksheetTitle: _worksheetTitle,
    );
  }

  Future<void> _loadBuses() async {
    allBuses = await fetchBusRoutes();
  }

  String _statusFor(String name) {
    return resolveTeacherStatus(teacherName: name, absenceMap: absenceList);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;

    if (isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const CustomHeader(title: "GR0VE", subtitle: "FOR BCA"),

            // Starred Teachers
            if (email!.contains("@bergen.org")) ...[
              const SizedBox(height: 24),
              const Text(
                "STARRED TEACHERS",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<Set<String>>(
                valueListenable: StarredTeacherService.starredTeachers,
                builder: (_, starred, __) {
                  final teachers = teacherList.values
                      .map((t) => Map<String, dynamic>.from(t))
                      .where((t) => starred.contains(t['name']))
                      .toList();

                  if (teachers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          "No starred teachers yet... try heading to the teachers absence page!",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: teachers.map((t) {
                      final name = t['name'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomTeacherCard(
                          name: name,
                          department: t['department'],
                          email: t['email'],
                          status: _statusFor(name),
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
            ],

            // Starred Buses
            const SizedBox(height: 32),
            const Text(
              "FAVORITE BUSES",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<Set<String>>(
              valueListenable: StarredBusService.starredTowns,
              builder: (_, starred, __) {
                final buses = allBuses
                    .where((b) => starred.contains(b.town))
                    .toList();

                if (buses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "No starred buses yet... try heading to the buses page!",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: buses.map((b) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CustomBusCard(
                        route: b,
                        starred: true,
                        onStarTap: () => StarredBusService.toggleTown(b.town),
                        isLoggedIn: loggedIn,
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
