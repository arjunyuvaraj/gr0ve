import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/core/widgets/cards/custom_teacher_card.dart';
import 'package:gr0ve/features/authentication/screen/bergen_onboarding_screen.dart';
import 'package:gr0ve/features/bus/widgets/custom_bus_card.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/features/absence/services/teacher_service.dart';
import 'package:gr0ve/features/bus/services/bus_service.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';

// SCREEN: Dashboard displaying starred items and relevant school info
// LOGIC: Aggregates teachers, buses, and absences into a unified view
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  bool needsOnboarding = false;
  Map<String, String> absenceList = {};
  Map<String, Map<String, dynamic>> allTeachers = {};
  List<BusRoute> allBuses = [];

  User? user;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    FirebaseAnalytics.instance.logEvent(name: 'screen_home');
    _checkOnboarding();
    _updateTimeBasedView();
  }

  Future<void> _checkOnboarding() async {
    if (user == null) {
      setState(() {
        isLoading = false;
        needsOnboarding = false;
      });
      return;
    }

    final email = user!.email ?? '';
    final isBergenStudent = email.endsWith('@bergen.org');

    if (!isBergenStudent) {
      setState(() {
        isLoading = false;
        needsOnboarding = false;
      });
      await _loadData();
      return;
    }

    // Check if email is verified and profile is complete
    await user!.reload();
    final isEmailVerified = user!.emailVerified;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final data = userDoc.data();
      final hasGrade = data?['grade'] != null;
      final hasAcademy = data?['academy'] != null;

      final needsSetup = !isEmailVerified || !hasGrade || !hasAcademy;

      setState(() {
        needsOnboarding = needsSetup;
        isLoading = false;
      });

      if (!needsSetup) {
        await _loadData();
      }
    } catch (e) {
      setState(() {
        needsOnboarding = false;
        isLoading = false;
      });
      await _loadData();
    }
  }

  void _updateTimeBasedView() {
    final now = DateTime.now();
    final cutoffTime = DateTime(
      now.year,
      now.month,
      now.day,
      15,
      45,
    ); // 3:45 PM
    final showTeachers = now.isBefore(cutoffTime);
    _currentPage = showTeachers ? 0 : 1;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Show onboarding screen if needed
    if (needsOnboarding) {
      return BergenOnboardingScreen(
        onComplete: () {
          setState(() {
            needsOnboarding = false;
          });
          _loadData();
        },
      );
    }
    String? displayName = FirebaseAuth.instance.currentUser?.displayName;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CustomHeader(title: displayName ?? "GR0VE"),
            ),

            if (!isWide) ...[
              // Page indicator bar (Mobile only)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPageIndicator(
                        0,
                        colors,
                        Icons.person_rounded,
                        'Teachers',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPageIndicator(
                        1,
                        colors,
                        Icons.directions_bus_rounded,
                        'Buses',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: PremiumLoadingIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: isWide
                          ? _buildWideContent(colors, textTheme, context)
                          : PageView(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              children: [
                                _buildTeachersSection(colors, textTheme),
                                _buildBusesSection(colors, textTheme),
                              ],
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWideContent(
    ColorScheme colors,
    TextTheme textTheme,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTeachersSection(colors, textTheme)),
        const SizedBox(width: 16),
        VerticalDivider(
          width: 1,
          indent: 20,
          endIndent: 20,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(50),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildBusesSection(colors, textTheme)),
      ],
    );
  }

  Widget _buildPageIndicator(
    int page,
    ColorScheme colors,
    IconData icon,
    String label,
  ) {
    final isActive = _currentPage == page;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? colors.primary.withOpacity(0.15)
              : colors.surface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? colors.primary : colors.outline.withOpacity(0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? colors.primary
                  : colors.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? colors.primary
                    : colors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachersSection(ColorScheme colors, TextTheme textTheme) {
    return ValueListenableBuilder<Set<String>>(
      key: const ValueKey('teachers'),
      valueListenable: StarredTeacherService.starredTeachers,
      builder: (_, starred, __) {
        final teachers = allTeachers.values
            .where((t) => starred.contains(t['name']))
            .toList();

        if (teachers.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 400,
              child: _buildEmptyState(
                colors,
                textTheme,
                Icons.person_off_rounded,
                'No Starred Teachers',
                'Star your favorite teachers to see them here',
              ),
            ),
          );
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 0),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'STARRED TEACHERS',
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${teachers.length}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...teachers.map((t) {
              final name = t['name']!;
              return CustomTeacherCard(
                name: name,
                department: t['department'],
                email: t['email'],
                status: _statusFor(name),
                showStar: true,
                starred: true,
                onStarTap: () => StarredTeacherService.toggleTeacher(name),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildBusesSection(ColorScheme colors, TextTheme textTheme) {
    return ValueListenableBuilder<Set<String>>(
      key: const ValueKey('buses'),
      valueListenable: StarredBusService.starredTowns,
      builder: (_, starred, __) {
        final buses = allBuses.where((b) => starred.contains(b.town)).toList();

        if (buses.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 400,
              child: _buildEmptyState(
                colors,
                textTheme,
                Icons.directions_bus_outlined,
                'No Favorite Buses',
                'Star your bus routes to see them here',
              ),
            ),
          );
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 0),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'FAVORITE BUSES',
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${buses.length}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...buses.map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CustomBusCard(
                  route: b,
                  starred: true,
                  onStarTap: () => StarredBusService.toggleTown(b.town),
                  isLoggedIn: user != null,
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(
    ColorScheme colors,
    TextTheme textTheme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: colors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
