import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
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

  bool isLoading = true;
  String searchQuery = "";
  String selectedPeriod = "All";

  Timer? _refreshTimer;

  static const _teacherSpreadsheetId =
      '1Ocm7wpxK9_xlkJGe9z8zH-I5TPsio1fZAxUf0rNs5Jk';
  static const _teacherWorksheetTitle = 'Absences';

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

  // Schedule times in minutes from midnight
  static const List<int> _refreshTimes = [
    // 7:30-8:00 every 5 minutes
    450, 455, 460, 465, 470, 475, 480,
    // Individual times
    530, 534, 538, 542, // 8:50, 8:54, 8:58, 9:02
    592, 596, // 9:52, 9:56
    646, 650, // 10:46, 10:50
    700, 704, // 11:40, 11:44
    754, 758, // 12:34, 12:38
    808, 812, // 1:28, 1:32
    802, // 1:22
    866, // 2:26
    916, 920, // 3:16, 3:20
    970, // 4:10
    990, // 4:30
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await StarredTeacherService.load();
    await loadTeachers();
    await loadAbsences();
    _scheduleNextRefresh();
  }

  void _scheduleNextRefresh() {
    _refreshTimer?.cancel();

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Find the next scheduled refresh time
    int? nextRefreshMinutes;
    for (final time in _refreshTimes) {
      if (time > currentMinutes) {
        nextRefreshMinutes = time;
        break;
      }
    }

    // If no time today, schedule for first time tomorrow
    if (nextRefreshMinutes == null) {
      nextRefreshMinutes = _refreshTimes.first + (24 * 60);
    }

    // Calculate duration until next refresh
    final minutesUntilRefresh = nextRefreshMinutes - currentMinutes;
    final duration = Duration(
      minutes: minutesUntilRefresh,
      seconds: -now.second, // Align to start of minute
    );

    _refreshTimer = Timer(duration, () {
      loadAbsences(silent: true);
      _scheduleNextRefresh(); // Schedule the next one
    });
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

    try {
      final rawData = await fetchGoogleSheetAbsences(
        spreadsheetId: _teacherSpreadsheetId,
        worksheetTitle: _teacherWorksheetTitle,
      );

      if (!mounted) return;

      setState(() {
        absenceList = rawData;
        filteredTeachers = applyFilters(teachers);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String getTeacherStatus(String fullName) {
    final normalized = normalizeTeacherName(fullName);
    for (final entry in absenceList.entries) {
      if (matchesTeacher(entry.key, normalized)) {
        return entry.value;
      }
    }
    return "Present";
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

  List<Map<String, dynamic>> getOrderedTeachers(Set<String> starredTeachers) {
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

  Widget _buildVerifyEmailState(BuildContext context, User? user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_unread, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Verify your email",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "You need to verify your email before viewing teacher absences.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: user == null
                  ? null
                  : () async {
                      await user.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Verification email sent"),
                        ),
                      );
                    },
              child: const Text("Send verification email"),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () async {
                await user?.reload();
                setState(() {}); // re-check emailVerified
              },
              child: const Text("I've verified — refresh"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      return _buildVerifyEmailState(context, user);
    }

    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          CustomHeader(
            title: "Teachers".capitalized,
            subtitle: absenceList['Date'] ?? "",
          ),
          const SizedBox(height: 12),
          Material(
            elevation: 4,
            shadowColor: context.colors.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search buses or parking spot...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: context.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                searchQuery = value;
                setState(() {
                  filteredTeachers = applyFilters(teachers);
                });
              },
            ),
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

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ValueListenableBuilder<Set<String>>(
                    valueListenable: StarredTeacherService.starredTeachers,
                    builder: (context, starredTeachers, _) {
                      final orderedTeachers = getOrderedTeachers(
                        starredTeachers,
                      );

                      if (orderedTeachers.isEmpty) {
                        return const Center(child: Text("No teachers found"));
                      }

                      return LayoutBuilder(
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
                                spacing: 12,
                                runSpacing: 12,
                                children: orderedTeachers.map((t) {
                                  final name = t['name'];
                                  final rawStatus = getTeacherStatus(name);
                                  final status = formatStatusString(rawStatus);

                                  return SizedBox(
                                    width: cardWidth,
                                    child: CustomTeacherCard(
                                      name: name,
                                      department: t['department'],
                                      email: t['email'],
                                      status: status,
                                      showStar: true,
                                      starred: starredTeachers.contains(name),
                                      onStarTap: () =>
                                          StarredTeacherService.toggleTeacher(
                                            name,
                                          ),
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
