import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/components/custom_teacher_card.dart';
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

  // -----------------------------
  // KIM EDGE CASE
  // -----------------------------
  String getKimStatus() {
    final kimEntries = absenceList.keys
        .where((k) => k.toLowerCase().contains("kim"))
        .toList();

    if (kimEntries.isEmpty) return "Present";

    for (final key in kimEntries) {
      final status = absenceList[key];
      if (status != null && status != "Present") {
        return status;
      }
    }

    return "Present";
  }

  // -----------------------------
  // INIT
  // -----------------------------
  @override
  void initState() {
    super.initState();
    loadTeachers();
  }

  // -----------------------------
  // LOAD FROM teacherList ONLY
  // -----------------------------
  void loadTeachers() {
    final data = teacherList.values
        .map((t) => Map<String, dynamic>.from(t))
        .toList();

    setState(() {
      teachers = data;
      filteredTeachers = data;
      isLoading = false;
    });
  }

  // -----------------------------
  // FILTERING
  // -----------------------------
  void applyFilters() {
    List<Map<String, dynamic>> result = teachers;

    // SEARCH
    if (searchQuery.isNotEmpty) {
      result = result.where((t) {
        return t['name'].toString().toLowerCase().contains(
          searchQuery.toLowerCase(),
        );
      }).toList();
    }

    // PERIOD
    if (selectedPeriod.toLowerCase() != "all") {
      result = result.where((t) {
        final lastName = t['name'].toString().split(",")[0].trim();
        final status = lastName.toLowerCase() == "kim"
            ? getKimStatus()
            : (absenceList[lastName] ?? "Present");

        return status.toLowerCase().contains(selectedPeriod.toLowerCase());
      }).toList();
    }

    setState(() => filteredTeachers = result);
  }

  void filterTeachers(String query) {
    searchQuery = query;
    applyFilters();
  }

  // -----------------------------
  // SORTING (ABSENT FIRST)
  // -----------------------------
  List<Map<String, dynamic>> getOrderedTeachers() {
    return filteredTeachers.toList()..sort((a, b) {
      final aLast = a['name'].toString().split(",")[0].trim();
      final bLast = b['name'].toString().split(",")[0].trim();

      final aStatus = aLast.toLowerCase() == "kim"
          ? getKimStatus()
          : (absenceList[aLast] ?? "Present");

      final bStatus = bLast.toLowerCase() == "kim"
          ? getKimStatus()
          : (absenceList[bLast] ?? "Present");

      final aAbsent = aStatus != "Present";
      final bAbsent = bStatus != "Present";

      if (aAbsent && !bAbsent) return -1;
      if (!aAbsent && bAbsent) return 1;
      return 0;
    });
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          CustomHeader(
            title: "Teachers".capitalized,
            subtitle: absenceList['Date']?.toString().capitalized ?? "",
          ),

          const SizedBox(height: 12),

          TextField(
            decoration: InputDecoration(
              hintText: 'Search teachers...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: filterTeachers,
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: selectedPeriod,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: periodOptions
                .map((p) => DropdownMenuItem(value: p, child: Text("Per: $p")))
                .toList(),
            onChanged: (value) {
              selectedPeriod = value!;
              applyFilters();
            },
          ),

          const SizedBox(height: 10),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTeachers.isEmpty
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

                      final ordered = getOrderedTeachers();

                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: ordered.map((t) {
                              final lastName = t['name']
                                  .toString()
                                  .split(",")[0]
                                  .trim();

                              final status = lastName.toLowerCase() == "kim"
                                  ? getKimStatus()
                                  : (absenceList[lastName] ?? "Present");

                              return SizedBox(
                                width: cardWidth,
                                child: CustomTeacherCard(
                                  name: t['name'],
                                  department: t['department'],
                                  email: t['email'],
                                  status: status,
                                  starred: false,
                                  star: false,
                                  onTap: () {},
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
