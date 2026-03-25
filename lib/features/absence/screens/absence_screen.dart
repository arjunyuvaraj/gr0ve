import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/core/widgets/cards/custom_teacher_card.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:gr0ve/features/absence/services/teacher_service.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';
import 'package:gr0ve/core/widgets/misc/email_verification_gate.dart'; // Added this import

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
    FirebaseAnalytics.instance.logEvent(name: 'screen_absence');
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await StarredTeacherService.load();
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

    // Fetch teacher list and absences in parallel
    final results = await Future.wait([
      fetchTeacherListFromFirebase(),
      fetchGoogleSheetAbsences(
        spreadsheetId: _spreadsheetId,
        worksheetTitle: _worksheetTitle,
      ),
    ]);

    teachers = (results[0] as Map<String, Map<String, dynamic>>).values
        .map((t) => Map<String, dynamic>.from(t))
        .toList();

    absenceList = results[1] as Map<String, String>;

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
        final rawStatus = _statusFor(name);
        if (rawStatus == 'Present') return false;

        if (selectedPeriod == "IGS") {
          return rawStatus.toUpperCase().contains("IGS");
        }

        // Expand ranges so "Periods 2-9" matches period 3, 4, 5, etc.
        final periodNum = int.tryParse(selectedPeriod);
        if (periodNum != null) {
          return _statusContainsPeriod(rawStatus, periodNum);
        }

        return rawStatus.toLowerCase().contains(selectedPeriod.toLowerCase());
      }

      return true;
    }).toList();
  }

  /// Check if a raw status string (e.g. "Periods 2-9" or "Periods 5-9")
  /// includes a specific period number.
  bool _statusContainsPeriod(String rawStatus, int period) {
    if (rawStatus.toLowerCase() == 'all day') return true;

    // Extract the period portion after "Period(s) "
    final match = RegExp(r'Period[s]?\s+(.+)', caseSensitive: false)
        .firstMatch(rawStatus);
    if (match == null) return false;

    final periodsString = match.group(1)!;
    final parts = periodsString.split(RegExp(r'[,&]')).map((e) => e.trim());

    for (final part in parts) {
      if (part.toUpperCase() == 'IGS') continue;
      if (part.contains('-')) {
        final rangeParts = part.split('-').map((e) => e.trim()).toList();
        if (rangeParts.length == 2) {
          final start = int.tryParse(rangeParts[0]);
          final end = int.tryParse(rangeParts[1]);
          if (start != null && end != null && period >= start && period <= end) {
            return true;
          }
        }
      } else {
        final num = int.tryParse(part);
        if (num == period) return true;
      }
    }

    return false;
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

  String formatStatusString(String status) {
    if (status.isEmpty) return 'No status';
    return status.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return EmailVerificationGate(
      description: "Please verify your email address to view teacher absences.",
      padding: const EdgeInsets.fromLTRB(16, 24, 32, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 32, 0),
        child: Column(
          children: [
          const CustomHeader(title: "Teachers"),
          const SizedBox(height: 16),
          Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search teachers...',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (v) {
                  searchQuery = v;
                  setState(() => filteredTeachers = _applyFilters());
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                decoration: const InputDecoration(isDense: true),
                value: selectedPeriod,
                items: periodOptions
                    .map(
                      (p) =>
                          DropdownMenuItem(value: p, child: Text("Period: $p")),
                    )
                    .toList(),
                onChanged: (v) {
                  selectedPeriod = v!;
                  setState(() => filteredTeachers = _applyFilters());
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const PremiumLoadingIndicator()
                : ValueListenableBuilder<Set<String>>(
                    valueListenable: StarredTeacherService.starredTeachers,
                    builder: (_, starred, __) {
                      final ordered = _ordered(starred);
                      return RefreshIndicator(
                        onRefresh: () => _loadAbsences(silent: true),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 110),
                          itemCount: ordered.length,
                          itemBuilder: (context, index) {
                            final t = ordered[index];
                            final name = t['name'];
                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 300 + (index % 10) * 50,
                              ),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
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
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
        ),
      ),
    );
  }
}
