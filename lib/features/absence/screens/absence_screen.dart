import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/core/widgets/cards/custom_teacher_card.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:gr0ve/features/absence/services/teacher_service.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';
import 'package:gr0ve/core/widgets/misc/email_verification_gate.dart';
import 'package:gr0ve/features/admin/services/admin_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool isAdmin = false;
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
    isAdmin = await AdminHelper.isCurrentUserAdmin();
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
    final match = RegExp(
      r'Period[s]?\s+(.+)',
      caseSensitive: false,
    ).firstMatch(rawStatus);
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
          if (start != null &&
              end != null &&
              period >= start &&
              period <= end) {
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
    return status
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Future<void> _deleteTeacher(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Teacher?'),
        content: Text('Are you sure you want to remove $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(name)
          .delete();
      _loadAbsences(silent: true);
    }
  }

  Future<void> _showTeacherDialog({Map<String, dynamic>? teacher}) async {
    final nameCtrl = TextEditingController(text: teacher?['name'] ?? '');
    final deptCtrl = TextEditingController(text: teacher?['department'] ?? '');
    final emailCtrl = TextEditingController(text: teacher?['email'] ?? '');

    // Parse current status to determine selected periods
    final currentStatus = teacher != null
        ? _statusFor(teacher['name'])
        : 'Present';
    final List<String> selectedPeriods = [];

    if (currentStatus.toLowerCase().contains('all day')) {
      selectedPeriods.addAll([
        '1',
        '2',
        'HR',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
      ]);
    } else {
      if (currentStatus.toUpperCase().contains('IGS')) {
        selectedPeriods.add('HR');
      }

      final periodMatch = RegExp(
        r'Period[s]?\s+([0-9\-,]+)',
        caseSensitive: false,
      ).firstMatch(currentStatus);
      if (periodMatch != null) {
        final pStr = periodMatch.group(1)!;
        if (pStr.contains('-')) {
          final range = pStr.split('-');
          final start = int.tryParse(range[0]) ?? 1;
          final end = int.tryParse(range[1]) ?? 9;
          for (int i = start; i <= end; i++) {
            if (!selectedPeriods.contains(i.toString()))
              selectedPeriods.add(i.toString());
          }
        } else {
          final parts = pStr.split(',').map((e) => e.trim());
          for (final p in parts) {
            if (p.isNotEmpty && !selectedPeriods.contains(p))
              selectedPeriods.add(p);
          }
        }
      }
    }

    final isNew = teacher == null;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = Theme.of(context).colorScheme;

          Widget periodSquare(String p, int index) {
            final isSelected = selectedPeriods.contains(p);
            return GestureDetector(
              onTap: () {
                setDialogState(() {
                  if (isSelected) {
                    selectedPeriods.remove(p);
                  } else {
                    selectedPeriods.add(p);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withOpacity(0.85)
                      : colors.surface,
                ),
                alignment: Alignment.center,
                child: Text(
                  p,
                  style: TextStyle(
                    color: isSelected
                        ? colors.onPrimary
                        : colors.onSurface.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }

          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 340, // More compact width
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_calendar_rounded,
                          size: 20,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isNew ? 'New Entry' : 'Update Info',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      readOnly: !isNew,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: deptCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(
                          Icons.school_outlined,
                          size: 18,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          size: 18,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.onSurface.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20), // Pill-ish
                        border: Border.all(
                          color: colors.onSurface.withOpacity(0.08),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 5,
                        mainAxisSpacing: 1,
                        crossAxisSpacing: 1,
                        childAspectRatio: 1.2, // More compact/pillish
                        physics: const NeverScrollableScrollPhysics(),
                        children:
                            ['1', '2', 'HR', '3', '4', '5', '6', '7', '8', '9']
                                .asMap()
                                .entries
                                .map(
                                  (entry) =>
                                      periodSquare(entry.value, entry.key),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (!isNew)
                          IconButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _deleteTeacher(teacher['name']);
                            },
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 22,
                              color: colors.error.withOpacity(0.7),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Discard',
                            style: TextStyle(
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;

                            await FirebaseFirestore.instance
                                .collection('teachers')
                                .doc(name)
                                .set({
                                  'name': name,
                                  'department': deptCtrl.text.trim(),
                                  'email': emailCtrl.text.trim(),
                                }, SetOptions(merge: true));

                            String newStatus = "Present";
                            if (selectedPeriods.isNotEmpty) {
                              final pSorted =
                                  selectedPeriods
                                      .where((p) => int.tryParse(p) != null)
                                      .toList()
                                    ..sort(
                                      (a, b) =>
                                          int.parse(a).compareTo(int.parse(b)),
                                    );

                              final hasHR = selectedPeriods.contains('HR');

                              if (pSorted.length == 9 && hasHR) {
                                newStatus = "All Day";
                              } else {
                                List<String> parts = [];
                                if (pSorted.isNotEmpty) {
                                  parts.add("Periods ${pSorted.join(',')}");
                                }
                                if (hasHR) {
                                  parts.add("IGS");
                                }
                                newStatus = parts.join(" & ");
                              }
                            }

                            if (newStatus != "Present") {
                              await FirebaseFirestore.instance
                                  .collection('public_data')
                                  .doc('teacher_absences')
                                  .update({'teachers.$name': newStatus});
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('public_data')
                                  .doc('teacher_absences')
                                  .update({
                                    'teachers.$name': FieldValue.delete(),
                                  });
                            }

                            if (mounted) Navigator.pop(ctx);
                            _loadAbsences(silent: true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      transitionBuilder: (ctx, anim1, anim2, child) => FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(anim1),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: EmailVerificationGate(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 32, 0),
          child: Column(
            children: [
              const CustomHeader(title: "Teachers"),
              if (isAdmin)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: InkWell(
                      onTap: () => _showTeacherDialog(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Add Entry',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
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
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text("Period: $p"),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      selectedPeriod = v!;
                      setState(() => filteredTeachers = _applyFilters());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                                    status: formatStatusString(
                                      _statusFor(name),
                                    ),
                                    showStar: true,
                                    starred: starred.contains(name),
                                    onStarTap: () =>
                                        StarredTeacherService.toggleTeacher(
                                          name,
                                        ),
                                    isAdmin: isAdmin,
                                    onEditTap: () =>
                                        _showTeacherDialog(teacher: t),
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
      ),
    );
  }
}
