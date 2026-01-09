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
  bool isInitialLoading = true;

  Map<String, String> absenceList = {};
  Set<String> starredTeachers = {};
  List<Map<String, dynamic>> teachers = [];

  Set<String> starredTowns = {};
  List<BusRoute> buses = [];

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatusesOnly();
      _refreshStars();
    }
  }

  Future<void> _refreshStars() async {
    final newStarredTeachers = await StarredTeacherService.getStarredTeachers();
    final newStarredTowns = await StarredBusService.getStarredTowns();

    final allBuses = await fetchBusRoutes();

    if (!mounted) return;

    setState(() {
      starredTeachers = newStarredTeachers;
      starredTowns = newStarredTowns;

      teachers = teacherList.values
          .map((t) => Map<String, dynamic>.from(t))
          .where((t) => starredTeachers.contains(t['name']))
          .toList();

      buses = allBuses.where((b) => starredTowns.contains(b.town)).toList();
    });
  }

  /// ----------------------------
  /// INITIAL LOAD (runs once)
  /// ----------------------------
  Future<void> _initialLoad() async {
    await Future.wait([_loadAbsences(), _loadTeachers(), _loadBuses()]);

    if (!mounted) return;
    setState(() => isInitialLoading = false);
  }

  /// ----------------------------
  /// LIGHT REFRESH (no spinner)
  /// ----------------------------
  Future<void> _refreshStatusesOnly() async {
    final absences = await fetchGoogleDocMap('YOUR_DOC_URL_HERE');
    if (!mounted) return;
    setState(() => absenceList = absences);
  }

  Future<void> _loadAbsences() async {
    try {
      absenceList = await fetchGoogleDocMap('YOUR_DOC_URL_HERE');
    } catch (_) {
      absenceList = {};
    }
  }

  Future<void> _loadTeachers() async {
    starredTeachers = await StarredTeacherService.getStarredTeachers();

    teachers = teacherList.values
        .map((t) => Map<String, dynamic>.from(t))
        .where((t) => starredTeachers.contains(t['name']))
        .toList();
  }

  Future<void> _loadBuses() async {
    starredTowns = await StarredBusService.getStarredTowns();
    final allBuses = await fetchBusRoutes();

    buses = allBuses.where((b) => starredTowns.contains(b.town)).toList();
  }

  String getTeacherStatus(String fullName) {
    final key = fullName.contains(',')
        ? fullName.split(',')[0].trim()
        : fullName.trim();

    return absenceList[key] ?? "Present";
  }

  /// ----------------------------
  /// LOCAL STAR UPDATES (NO RELOAD)
  /// ----------------------------
  Future<void> toggleTeacherStar(String name) async {
    await StarredTeacherService.toggleTeacher(name);

    final updatedStarred = await StarredTeacherService.getStarredTeachers();

    if (!mounted) return;

    setState(() {
      starredTeachers = updatedStarred;

      teachers = teacherList.values
          .map((t) => Map<String, dynamic>.from(t))
          .where((t) => starredTeachers.contains(t['name']))
          .toList();
    });
  }

  Future<void> toggleBusStar(BusRoute route) async {
    await StarredBusService.toggleTown(route.town);

    final updatedStarred = await StarredBusService.getStarredTowns();
    final allBuses = await fetchBusRoutes();

    if (!mounted) return;

    setState(() {
      starredTowns = updatedStarred;
      buses = allBuses.where((b) => starredTowns.contains(b.town)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const CustomHeader(title: "GR0VE", subtitle: "FOR BCA"),
                  const SizedBox(height: 24),

                  /// ----------------------------
                  /// TEACHERS
                  /// ----------------------------
                  const Text(
                    "STARRED TEACHERS",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (teachers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          "Nothing here",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...teachers.map((t) {
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
                          onStarTap: () => toggleTeacherStar(name),
                        ),
                      );
                    }),

                  const SizedBox(height: 32),

                  /// ----------------------------
                  /// BUSES
                  /// ----------------------------
                  const Text(
                    "FAVORITE BUSES",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (buses.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          "Nothing here",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...buses.map((b) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomBusCard(
                          route: b,
                          starred: true,
                          onStarTap: () => toggleBusStar(b),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
