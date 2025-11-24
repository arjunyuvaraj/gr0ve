import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/components/custom_teacher_card.dart';
import 'package:gr0ve/services/authentication_service.dart';
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
  bool showFavoritesOnly = false;
  String selectedPeriod = "All";

  List<String> periodOptions = [
    "All",
    "IGS",
    "Period 1",
    "Period 2",
    "Period 3",
    "Period 4",
    "Period 5",
    "Period 6",
    "Period 7",
    "Period 8",
    "Period 9",
  ];

  @override
  void initState() {
    super.initState();
    loadTeachers();
  }

  void applyFilters() {
    List<Map<String, dynamic>> result = teachers;

    // SEARCH FILTER
    if (searchQuery.isNotEmpty) {
      result = result.where((t) {
        final name = t['name'].toString().toLowerCase();
        return name.contains(searchQuery.toLowerCase());
      }).toList();
    }

    // PERIOD FILTER
    if (selectedPeriod.trim().toLowerCase() != "all") {
      result = result.where((t) {
        final tName = t['name'].toString();
        final lastName = tName.split(",")[0].trim();
        final status = absenceList[lastName] ?? "Present";

        // Status example: "Period 3"
        return status.trim().toLowerCase().contains(
          selectedPeriod.trim()[selectedPeriod.length - 1],
        );
      }).toList();
    }

    setState(() {
      filteredTeachers = result;
    });
  }

  String searchQuery = "";
  // METHOD: Given a query search through the teachers
  void filterTeachers(String query) {
    searchQuery = query;
    applyFilters();
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

  void fetchTeacher() async {
    String docId =
        "2PACX-1vT_iK6QcUDVJoo_A6Enz5eizn4PzAWGfJBGo1vaC6T2y_0vHaYcL3ZlwcPN4H6pNCNEExNKGwxyktWC";
    String docUrl = 'https://docs.google.com/document/d/e/$docId/pub';
    Map<String, String> content = await fetchGoogleDocMap(docUrl);
    absenceList = content;
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
            subtitle: "Last updated: ${absenceList['Date']}".capitalized,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Container(
              width: double.infinity,
              child: TextButton(
                child: Text("Refresh".capitalized),
                onPressed: () => fetchTeacher(),
              ),
            ),
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
          const SizedBox(height: 8),
          Row(
            children: [
              // FAVORITES ONLY
              Expanded(
                child: Row(
                  children: [
                    Switch(
                      value: showFavoritesOnly,
                      onChanged: (value) {
                        setState(() => showFavoritesOnly = value);
                        applyFilters();
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Starred",
                      style: context.text.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // PERIOD DROPDOWN
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: periodOptions.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p.trim()));
                  }).toList(),
                  onChanged: (value) {
                    selectedPeriod = value!;
                    applyFilters();
                  },
                ),
              ),
            ],
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

                List<Map<String, dynamic>> temp = getOrderedTeachers(starred);

                // FAVORITES FILTER APPLIED HERE
                if (showFavoritesOnly) {
                  temp = temp
                      .where((t) => starred.contains(t['name']))
                      .toList();
                }

                final orderedTeachers = temp;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    // set your breakpoints
                    int columns = 1;
                    if (width > 1000) {
                      columns = 3;
                    } else if (width > 650) {
                      columns = 2;
                    }

                    // compute width per card
                    final double cardWidth =
                        (width - (16 * (columns - 1))) / columns;

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: orderedTeachers.map((t) {
                            final tName = t['name'].toString();
                            final lastName = tName
                                .substring(0, tName.indexOf(","))
                                .trim();
                            final status = lastName.toLowerCase() == "kim"
                                ? getKimStatus()
                                : (absenceList[lastName] ?? "Present");

                            return SizedBox(
                              width: cardWidth,
                              child: CustomTeacherCard(
                                department: t['department'],
                                email: t['email'],
                                name: tName,
                                status: status,
                                starred: starred.contains(tName),
                                onTap: () => toggleStarTeacher(tName),
                                star: !(AuthenticationService().userLoggedIn()),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
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
