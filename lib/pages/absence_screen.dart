import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/components/custom_teacher_card.dart';
import 'package:gr0ve/services/starred_teacher_service.dart';
import 'package:gr0ve/services/teacher_service.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/teacher_utils.dart';

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

  // These aren't used anymore but kept for backwards compatibility
  static const _spreadsheetId = '1Ocm7wpxK9_xlkJGe9z8zH-I5TPsio1fZAxUf0rNs5Jk';
  static const _worksheetTitle = 'Absences';

  final periodOptions = [
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

  static const _refreshTimes = [
    450,
    455,
    460,
    465,
    470,
    475,
    480,
    530,
    534,
    538,
    542,
    592,
    596,
    646,
    650,
    700,
    704,
    754,
    758,
    802,
    808,
    812,
    866,
    916,
    920,
    970,
    990,
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await StarredTeacherService.load();
    teachers = teacherList.values
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
    await _loadAbsences();
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;

    int next = _refreshTimes.firstWhere(
      (t) => t > current,
      orElse: () => _refreshTimes.first + 1440,
    );

    final duration = Duration(minutes: next - current, seconds: -now.second);

    _refreshTimer = Timer(duration, () {
      _loadAbsences(silent: true);
      _scheduleRefresh();
    });
  }

  Future<void> _loadAbsences({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);

    absenceList = await fetchGoogleSheetAbsences(
      spreadsheetId: _spreadsheetId,
      worksheetTitle: _worksheetTitle,
    );

    if (!mounted) return;

    setState(() {
      filteredTeachers = _applyFilters();
      isLoading = false;
    });
  }

  String _statusFor(String name) {
    return resolveTeacherStatus(teacherName: name, absenceMap: absenceList);
  }

  List<Map<String, dynamic>> _applyFilters() {
    return teachers.where((t) {
      final name = t['name'].toString();
      if (searchQuery.isNotEmpty &&
          !name.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }

      if (selectedPeriod != "All") {
        return _statusFor(
          name,
        ).toLowerCase().contains(selectedPeriod.toLowerCase());
      }

      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _ordered(Set<String> starred) {
    return filteredTeachers.toList()..sort((a, b) {
      final aName = a['name'];
      final bName = b['name'];

      final aStar = starred.contains(aName);
      final bStar = starred.contains(bName);
      if (aStar != bStar) return aStar ? -1 : 1;

      final aAbsent = _statusFor(aName) != "Present";
      final bAbsent = _statusFor(bName) != "Present";
      if (aAbsent != bAbsent) return aAbsent ? -1 : 1;

      return aName.compareTo(bName);
    });
  }

  Widget _buildVerifyEmailState(BuildContext context, User? user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              "Please verify your email to view absences.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (user != null && !user.emailVerified) {
                  await user.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Verification email sent!")),
                  );
                }
              },
              child: const Text("Resend verification email"),
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
            // FIXED: Changed from 'Date' to 'date' to match Firestore structure
            subtitle: absenceList['date'] ?? "",
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search teachers...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) {
              searchQuery = v;
              setState(() => filteredTeachers = _applyFilters());
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedPeriod,
            items: periodOptions
                .map(
                  (p) => DropdownMenuItem(value: p, child: Text("Period: $p")),
                )
                .toList(),
            onChanged: (v) {
              selectedPeriod = v!;
              setState(() => filteredTeachers = _applyFilters());
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ValueListenableBuilder<Set<String>>(
                    valueListenable: StarredTeacherService.starredTeachers,
                    builder: (_, starred, __) {
                      final ordered = _ordered(starred);

                      return RefreshIndicator(
                        onRefresh: () => _loadAbsences(silent: true),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: ordered.map((t) {
                            final name = t['name'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CustomTeacherCard(
                                name: name,
                                department: t['department'],
                                email: t['email'],
                                status: formatStatusString(_statusFor(name)),
                                showStar: true,
                                starred: starred.contains(name),
                                onStarTap: () =>
                                    StarredTeacherService.toggleTeacher(name),
                              ),
                            );
                          }).toList(),
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
