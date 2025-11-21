import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/components/custom_teacher_card.dart';
import 'package:gr0ve/services/teacher_service.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/data/teacher_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> filteredTeachers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTeachers();
  }

  // METHOD: Load the teachers
  Future<void> loadTeachers() async {
    final fetchedTeachers = await getTeachers();
    setState(() {
      teachers = fetchedTeachers;
      filteredTeachers = fetchedTeachers;
      isLoading = false;
    });
  }

  // METHOD: Given a query search through the teachers
  void filterTeachers(String query) {
    final filtered = teachers.where((t) {
      final name = t['name'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredTeachers = filtered;
    });
  }

  /* METHOD: Order the teachers as followers: 
      1. Absent + Starred
      2. Present + Starred
      3. Absent + Not-Starred
      4. Present + Not-Starred
  */
  List<Map<String, dynamic>> getOrderedTeachers(List<String> starredTeachers) {
    return filteredTeachers.toList()..sort((a, b) {
      final aName = a['name'].toString();
      final bName = b['name'].toString();

      final aBase = aName.split(",")[0].trim();
      final bBase = bName.split(",")[0].trim();

      // EDGE-CASE: In the event that Kim is used, handle appropriate
      final aStatus = aBase.toLowerCase() == "kim"
          ? getKimStatus()
          : (absenceList[aBase] ?? "Present");

      final bStatus = bBase.toLowerCase() == "kim"
          ? getKimStatus()
          : (absenceList[bBase] ?? "Present");

      final aStar = starredTeachers.contains(aName);
      final bStar = starredTeachers.contains(bName);

      // ORDER: Put starred first
      if (aStar && !bStar) return -1;
      if (!aStar && bStar) return 1;

      final aAbsent = aStatus != "Present";
      final bAbsent = bStatus != "Present";

      // ORDER: Absent before present
      if (aAbsent && !bAbsent) return -1;
      if (!aAbsent && bAbsent) return 1;

      return 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomHeader(
            title: "Gr0ve".capitalized,
            subtitle: "Who are you looking for?".capitalized,
          ),

          const SizedBox(height: 12),

          TextField(
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 14,
              ),
              hintText: 'Search teachers...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: filterTeachers,
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<List<String>>(
              stream: starredTeachersStream(),
              builder: (context, snapshot) {
                final starred = snapshot.data ?? [];

                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (filteredTeachers.isEmpty) {
                  return const Center(child: Text('No teachers found'));
                }

                final orderedTeachers = getOrderedTeachers(starred);

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 6),
                  itemCount: orderedTeachers.length,
                  itemBuilder: (context, i) {
                    final t = orderedTeachers[i];
                    final tName = t['name'].toString();

                    final lastName = tName
                        .substring(0, tName.indexOf(","))
                        .trim();

                    // --- Kim Fix here too ---
                    final status = lastName.toLowerCase() == "kim"
                        ? getKimStatus()
                        : (absenceList[lastName] ?? "Present");

                    return CustomTeacherCard(
                      department: t['department'],
                      email: t['email'],
                      name: tName,
                      status: status,
                      starred: starred.contains(tName),
                      onTap: () => toggleStarTeacher(tName),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
