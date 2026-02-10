import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/components/custom_teacher_card.dart';
import 'package:gr0ve/components/custom_bus_card.dart';
import 'package:gr0ve/services/starred_teacher_service.dart';
import 'package:gr0ve/services/starred_bus_service.dart';
import 'package:gr0ve/services/teacher_service.dart';
import 'package:gr0ve/services/bus_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  Map<String, String> absenceList = {};
  Map<String, Map<String, dynamic>> allTeachers = {};
  List<BusRoute> allBuses = [];

  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    // Load teacher absences
    absenceList = await fetchGoogleSheetAbsences(
      spreadsheetId: '', // ignored now
      worksheetTitle: '', // ignored now
    );

    // Load all teachers
    allTeachers = await fetchTeacherListFromFirebase();

    // Load buses (assuming you have BusService.fetchBusRoutes)
    allBuses = await fetchBusRoutes();

    // Load starred data
    await Future.wait([StarredTeacherService.load(), StarredBusService.load()]);

    setState(() => isLoading = false);
  }

  String _statusFor(String name) =>
      resolveTeacherStatus(teacherName: name, absenceMap: absenceList);

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CustomHeader(title: "GR0VE", subtitle: "FOR BCA"),

          // STARRED TEACHERS
          const SizedBox(height: 24),
          const Text(
            "STARRED TEACHERS",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<Set<String>>(
            valueListenable: StarredTeacherService.starredTeachers,
            builder: (_, starred, __) {
              final teachers = allTeachers.values
                  .where((t) => starred.contains(t['name']))
                  .toList();

              if (teachers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text("No starred teachers yet.")),
                );
              }

              return Column(
                children: teachers.map((t) {
                  final name = t['name']!;
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

          // STARRED BUSES
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text("No starred buses yet.")),
                );
              }

              return Column(
                children: buses
                    .map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomBusCard(
                          route: b,
                          starred: true,
                          onStarTap: () => StarredBusService.toggleTown(b.town),
                          isLoggedIn: user != null,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
