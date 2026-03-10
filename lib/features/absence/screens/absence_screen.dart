import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/core/widgets/cards/custom_teacher_card.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:gr0ve/features/absence/services/teacher_service.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';

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
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.email_rounded, size: 48, color: Colors.orange),
            ),
            const SizedBox(height: 32),
            Text(
              "Verify Your Email",
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Please verify your email address to view teacher absences",
              style: text.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.6),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            InkWell(
              onTap: () async {
                if (user != null && !user.emailVerified) {
                  try {
                    await user.sendEmailVerification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "Verification email sent! Check your inbox.",
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: ${e.toString()}"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.send_rounded, size: 20, color: colors.primary),
                    const SizedBox(width: 10),
                    Text(
                      "Send Verification",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                await user?.reload();
                setState(() {
                  // Rebuild to check email verification status
                });
                if (context.mounted && user?.emailVerified == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        "Email verified! Loading teachers...",
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: colors.primary,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.surface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "I've Verified My Email",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
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
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 32, 0),
        child: _buildVerifyEmailState(context, user),
      );
    }

    return Padding(
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
    );
  }
}
