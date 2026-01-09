import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/components/custom_teacher_card.dart';
import 'package:gr0ve/services/starred_teacher_service.dart';
import 'package:gr0ve/services/teacher_service.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/data/teacher_list.dart';

class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key});

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> filteredTeachers = [];
  Map<String, String> absenceList = {};

  Set<String> starredTeachers = {};
  bool isLoading = true;
  String searchQuery = "";
  String selectedPeriod = "All";

  final List<String> periodOptions = [
    "All",
    "IGS",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await loadStarredTeachers();
    await loadTeachers();
    await loadAbsences();
  }

  Future<void> loadStarredTeachers() async {
    final starred = await StarredTeacherService.getStarredTeachers();
    if (!mounted) return;
    setState(() => starredTeachers = starred);
  }

  Future<void> toggleTeacherStar(String fullName) async {
    await StarredTeacherService.toggleTeacher(fullName);
    await loadStarredTeachers();
  }

  Future<void> loadTeachers() async {
    final data = teacherList.values
        .map((t) => Map<String, dynamic>.from(t))
        .toList();

    if (!mounted) return;
    setState(() {
      teachers = data;
      filteredTeachers = applyFilters(data);
      isLoading = false;
    });
  }

  Future<void> loadAbsences({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);

    const docId =
        "2PACX-1vT_iK6QcUDVJoo_A6Enz5eizn4PzAWGfJBGo1vaC6T2y_0vHaYcL3ZlwcPN4H6pNCNEExNKGwxyktWC";
    const docUrl = 'https://docs.google.com/document/d/e/$docId/pub';

    try {
      final data = await fetchGoogleDocMap(docUrl);
      if (!mounted) return;

      setState(() {
        absenceList = data;
        filteredTeachers = applyFilters(teachers);
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String getTeacherStatus(String fullName) {
    final normalizedName = fullName.trim();

    if (normalizedName.toLowerCase().contains("kim")) {
      final kimEntries = absenceList.entries
          .where((e) => e.key.toLowerCase().contains("kim"))
          .toList();

      for (final entry in kimEntries) {
        if (entry.value != "Present") return entry.value;
      }
      return "Present";
    }
    return absenceList[normalizedName.substring(
          0,
          normalizedName.indexOf(","),
        )] ??
        "Present";
  }

  List<Map<String, dynamic>> applyFilters(List<Map<String, dynamic>> source) {
    var result = source;

    if (searchQuery.isNotEmpty) {
      result = result.where((t) {
        return t['name'].toString().toLowerCase().contains(
          searchQuery.toLowerCase(),
        );
      }).toList();
    }

    if (selectedPeriod != "All") {
      result = result.where((t) {
        final status = getTeacherStatus(t['name']);
        return status.toLowerCase().contains(selectedPeriod.toLowerCase());
      }).toList();
    }

    return result;
  }

  List<Map<String, dynamic>> getOrderedTeachers() {
    return filteredTeachers.toList()..sort((a, b) {
      final aName = a['name'];
      final bName = b['name'];

      final aStar = starredTeachers.contains(aName);
      final bStar = starredTeachers.contains(bName);

      if (aStar && !bStar) return -1;
      if (!aStar && bStar) return 1;

      final aAbsent = getTeacherStatus(aName) != "Present";
      final bAbsent = getTeacherStatus(bName) != "Present";

      if (aAbsent && !bAbsent) return -1;
      if (!aAbsent && bAbsent) return 1;

      return aName.compareTo(bName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final orderedTeachers = getOrderedTeachers();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          CustomHeader(
            title: "Teachers".capitalized,
            subtitle: absenceList['Date'] ?? "",
          ),
          const SizedBox(height: 12),

          TextField(
            decoration: InputDecoration(
              hintText: "Search teachers…",
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              searchQuery = value;
              setState(() {
                filteredTeachers = applyFilters(teachers);
              });
            },
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: selectedPeriod,
            items: periodOptions
                .map((p) => DropdownMenuItem(value: p, child: Text("Per: $p")))
                .toList(),
            onChanged: (value) {
              selectedPeriod = value!;
              setState(() {
                filteredTeachers = applyFilters(teachers);
              });
            },
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // TEACHERS
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : orderedTeachers.isEmpty
                ? const Center(child: Text("No teachers found"))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int columns = 1;
                      if (constraints.maxWidth > 1000) {
                        columns = 3;
                      } else if (constraints.maxWidth > 650) {
                        columns = 2;
                      }

                      final cardWidth =
                          (constraints.maxWidth - (16 * (columns - 1))) /
                          columns;

                      return RefreshIndicator(
                        onRefresh: () => loadAbsences(silent: true),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: orderedTeachers.map((t) {
                              final name = t['name'];
                              final status = getTeacherStatus(name);

                              return SizedBox(
                                width: cardWidth,
                                child: CustomTeacherCard(
                                  name: name,
                                  department: t['department'],
                                  email: t['email'],
                                  status: status,
                                  showStar: true,
                                  starred: starredTeachers.contains(name),
                                  onStarTap: () => toggleTeacherStar(name),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
