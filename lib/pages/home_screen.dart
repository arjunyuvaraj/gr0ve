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
  Set<String> starredTeachers = {};
  List<Map<String, dynamic>> teachers = [];

  Set<String> starredTowns = {};
  List<BusRoute> buses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      absenceList = await fetchGoogleDocMap('YOUR_DOC_URL_HERE');
    } catch (_) {
      absenceList = {};
    }

    starredTeachers = await StarredTeacherService.getStarredTeachers();
    teachers = teacherList.values
        .map((t) => Map<String, dynamic>.from(t))
        .where((t) => starredTeachers.contains(t['name']))
        .toList();

    starredTowns = await StarredBusService.getStarredTowns();
    final allBuses = await fetchBusRoutes();
    buses = allBuses.where((b) => starredTowns.contains(b.town)).toList();

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  String getTeacherStatus(String fullName) {
    final key = fullName.contains(",")
        ? fullName.split(",")[0].trim()
        : fullName.trim();
    return absenceList[key] ?? "Present";
  }

  Future<void> toggleTeacherStar(String name) async {
    await StarredTeacherService.toggleTeacher(name);
    await _loadData();
  }

  Future<void> toggleBusStar(BusRoute route) async {
    await StarredBusService.toggleTown(route.town);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: const CustomHeader(
                        title: "GR0VE",
                        subtitle: "FOR BCA",
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "STARRED TEACHERS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (teachers.isEmpty)
                      const Center(
                        child: Text(
                          "Nothing here",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Column(
                        children: teachers.map((t) {
                          final name = t['name'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomTeacherCard(
                              name: name,
                              department: t['department'],
                              email: t['email'],
                              status: getTeacherStatus(name),
                              showStar: true,
                              starred: starredTeachers.contains(name),
                              onStarTap: () => toggleTeacherStar(name),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      "FAVORITE BUSES",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (buses.isEmpty)
                      const Center(
                        child: Text(
                          "Nothing here",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: buses.map((b) {
                          final isStarred = starredTowns.contains(b.town);
                          return SizedBox(
                            width: MediaQuery.of(context).size.width > 600
                                ? (MediaQuery.of(context).size.width - 48) / 2
                                : double.infinity,
                            child: CustomBusCard(
                              route: b,
                              starred: isStarred,
                              onStarTap: () => toggleBusStar(b),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
