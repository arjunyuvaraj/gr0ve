import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/authentication/screen/bergen_onboarding_screen.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';

// Snapshot Widgets
import 'package:gr0ve/features/snapshot/widgets/snapshot_countdown_card.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_absence_card.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_bus_card.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_weather_card.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_pomodoro_card.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_upcoming_card.dart';
import 'package:gr0ve/features/home/services/layout_service.dart';

import 'package:hugeicons/hugeicons.dart';

// ════════════════════════════════════════════════════════════════
// HOME SCREEN
// ════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _needsOnboarding = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAnalytics.instance.logEvent(name: 'screen_home');
    LayoutService.initializeTimeChecker();
    _initData();
  }

  @override
  void dispose() {
    LayoutService.stopTimeChecker();
    super.dispose();
  }

  Future<void> _initData() async {
    // Services (starred teachers, buses, calendar, layout) are already booted
    // by _bootUserServices() in main.dart. We only need to check onboarding.
    await _checkOnboarding();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _checkOnboarding() async {
    if (_user == null) {
      _needsOnboarding = false;
      return;
    }

    final email = _user!.email ?? '';
    if (!email.endsWith('@bergen.org')) {
      _needsOnboarding = false;
      return;
    }

    await _user!.reload();
    final isEmailVerified = _user!.emailVerified;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      final data = doc.data();
      final hasSetup =
          isEmailVerified && data?['grade'] != null && data?['academy'] != null;
      _needsOnboarding = !hasSetup;
    } catch (_) {
      _needsOnboarding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsOnboarding) {
      return BergenOnboardingScreen(
        onComplete: () {
          setState(() {
            _needsOnboarding = false;
            _isLoading = true;
          });
          _initData();
        },
      );
    }

    final name = FirebaseAuth.instance.currentUser?.displayName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 32, 0),
      child: Column(
        children: [
          // Personalized Greeting Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting().toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4.0,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  (name?.split(' ').first ?? "GR0VE").toUpperCase(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 42,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDateString().toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: PremiumLoadingIndicator())
                : ValueListenableBuilder<List<CardId>>(
                    valueListenable: LayoutService.currentLayout,
                    builder: (ctx, layout, _) {
                      return RefreshIndicator(
                        onRefresh: _initData,
                        child: ReorderableListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
                          itemCount: layout.length,
                          proxyDecorator: (widget, index, animation) {
                            return Material(
                              color: Colors.transparent,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 1.0,
                                  end: 1.02,
                                ).animate(animation),
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.15),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: widget,
                                ),
                              ),
                            );
                          },
                          onReorder: (oldI, newI) {
                            if (newI > oldI) newI--;
                            final current = List<CardId>.from(
                              LayoutService.currentLayout.value,
                            );
                            final item = current.removeAt(oldI);
                            current.insert(newI, item);

                            final now = DateTime.now();
                            final hour = now.hour;
                            final minute = now.minute;

                            TimePeriod activePeriod;
                            if (hour < 15) {
                              activePeriod = TimePeriod.school;
                            } else if (hour < 17 || (hour == 17 && minute < 30)) {
                              activePeriod = TimePeriod.afternoon;
                            } else {
                              activePeriod = TimePeriod.evening;
                            }

                            LayoutService.save(activePeriod, current);
                          },
                          itemBuilder: (ctx, i) {
                            final id = layout[i];
                            return Padding(
                              key: ValueKey(id.name),
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 600,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionTile(
                                        id.label.toUpperCase(),
                                        id.icon,
                                      ),
                                      switch (id) {
                                        CardId.countdown =>
                                          const SnapshotCountdownCard(
                                            compact: false,
                                          ),
                                        CardId.absence =>
                                          const SnapshotAbsenceCard(
                                            compact: false,
                                          ),
                                        CardId.buses => const SnapshotBusCard(
                                          compact: false,
                                        ),
                                        CardId.weather =>
                                          const SnapshotWeatherCard(
                                            compact: false,
                                          ),
                                        CardId.upcoming =>
                                          const SnapshotUpcomingCard(
                                            compact: false,
                                          ),
                                        CardId.pomodoro =>
                                          const SnapshotPomodoroCard(
                                            compact: false,
                                          ),
                                      },
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          // Subtle Footer Edit Button
          Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 16),
            child: Center(
              child: InkWell(
                onTap: () => _showLayoutSettings(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedPaintBoard,
                        size: 14,
                        color: Theme.of(
                           context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "EDIT DASHBOARD",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════════════════════════════════

  void _showLayoutSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _LayoutEditorSheet(),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // HELPER
  // ════════════════════════════════════════════════════════════════

  Widget _buildSectionTile(String title, dynamic icon) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(
              icon: icon,
              size: 12,
              color: colors.primary.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: colors.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.outline.withOpacity(0.15),
                    colors.outline.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  String _getDateString() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

// ════════════════════════════════════════════════════════════════
// LAYOUT EDITOR SHEET
// ════════════════════════════════════════════════════════════════

class _LayoutEditorSheet extends StatefulWidget {
  const _LayoutEditorSheet();

  @override
  State<_LayoutEditorSheet> createState() => _LayoutEditorSheetState();
}

class _LayoutEditorSheetState extends State<_LayoutEditorSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabPane(
    TimePeriod period,
    ValueNotifier<List<CardId>> notifier,
  ) {
    return ValueListenableBuilder<List<CardId>>(
      valueListenable: notifier,
      builder: (ctx, layout, _) {
        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          itemCount: layout.length,
          proxyDecorator: (widget, index, animation) {
            return Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.02).animate(animation),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: widget,
                ),
              ),
            );
          },
          onReorder: (oldI, newI) {
            if (newI > oldI) newI--;
            final current = List<CardId>.from(notifier.value);
            final item = current.removeAt(oldI);
            current.insert(newI, item);
            LayoutService.save(period, current);
          },
          itemBuilder: (ctx, i) {
            final id = layout[i];
            return Padding(
              key: ValueKey('${period.id}_${id.name}'),
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: id.icon,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        id.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.drag_handle_rounded,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dashboard Layout',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.tertiary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: colors.onSurface,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  'Your dashboard automatically adjusts based on the time of day. Customize the order of widgets for each time period below.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                dividerColor: colors.outline.withOpacity(0.1),
                indicatorColor: colors.primary,
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurface.withOpacity(0.5),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'School',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        Text('Before 4:10 PM', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Afternoon',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '4:10 PM to 5:30 PM',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Evening',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        Text('After 5:30 PM', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabPane(
                      TimePeriod.school,
                      LayoutService.schoolLayout,
                    ),
                    _buildTabPane(
                      TimePeriod.afternoon,
                      LayoutService.afternoonLayout,
                    ),
                    _buildTabPane(
                      TimePeriod.evening,
                      LayoutService.eveningLayout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
