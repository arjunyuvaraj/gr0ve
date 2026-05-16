import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/account/services/profile_picture_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';
import 'package:gr0ve/features/counselor/screens/counselor_screen.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/features/grove/grove_screen.dart';
import 'package:gr0ve/features/help/help_screen.dart';
import 'package:gr0ve/features/links/screens/link_screen.dart';
import 'package:gr0ve/features/authentication/screen/bergen_onboarding_screen.dart';
import 'package:gr0ve/features/news/screens/news_screen.dart';
import 'package:gr0ve/features/changelog/screens/changelog_screen.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'package:gr0ve/features/account/services/dawn_unlock_service.dart';

// Import your screens
import 'package:gr0ve/features/account/screens/account_screen.dart';
import 'package:gr0ve/features/admin/screens/admin_panel_screen.dart';
import 'package:gr0ve/features/admin/screens/admin_calendar_requests_screen.dart';
import 'package:gr0ve/features/bus/screens/bus_screen.dart';
import 'package:gr0ve/features/calendar/screens/calendar_screen.dart';
import 'package:gr0ve/features/club/screens/club_screen.dart';
import 'package:gr0ve/features/absence/screens/absence_screen.dart';
import 'package:gr0ve/features/home/screens/home_screen.dart';
import 'package:gr0ve/features/lunch_menu/screens/lunch_menu_screen.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gr0ve/features/navigation/models/nav_config.dart';
import 'package:gr0ve/features/navigation/services/navigation_persistence_service.dart';
import 'package:gr0ve/services/settings/fun_mode_service.dart';
import 'package:gr0ve/features/grove/services/grove_unlock_service.dart';

// SCREEN: Main navigation hub with role-based access control
class NavigationScreen extends StatefulWidget {
  final int initialIndex;

  const NavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late int _selectedIndex;
  User? _user;
  UserRole _userRole = UserRole.guest;
  bool _isPlatformAdmin = false;

  List<NavConfig> _navConfigs = [];
  List<Widget> _screens = [];
  final NavigationPersistenceService _persistenceService =
      NavigationPersistenceService();
  List<String>? _customOrder;
  String _selectedTabId = 'home'; // Track by ID to prevent re-order glitches

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _versionCode = '0.0.0';
  StreamSubscription? _unreadCountSubscription;
  Map<String, int> _unreadCounts = {};
  Map<String, int> _unreadAnnouncementsByClub = {};
  Map<String, int> _unreadQAByClub = {};

  // Feature flags
  bool _enableClubs = false;
  bool _enableCounselor = false;
  bool _isBetaTester = false;
  bool _isFunMode = false;
  bool _isGroveUnlocked = false;

  // Onboarding state
  bool _isCheckingOnboarding = true;
  bool _needsOnboarding = false;

  // IDs hidden from the nav bar — accessible via More > Extra
  static const _extraScreenIds = {'lunch_menu', 'news', 'help', 'changelog'};

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _user = FirebaseAuth.instance.currentUser;
    _isBetaTester = AppFeatureFlags.isBeta.value;
    _determineUserRole();
    _setupNotificationHandler();
    _subscribeToUnreadCounts();
    ProfilePictureService.activeVariant.addListener(_onVariantChanged);
    AppFeatureFlags.isBeta.addListener(_onBetaStatusChanged);
    AppFeatureFlags.enableClubs.addListener(_onBetaStatusChanged);
    AppFeatureFlags.enableCounselor.addListener(_onBetaStatusChanged);
    FunModeService.isFunMode.addListener(_onFunModeChanged);
    _isFunMode = FunModeService.isFunMode.value;
    GroveUnlockService.isUnlocked.addListener(_onGroveUnlockChanged);
    _isGroveUnlocked = GroveUnlockService.isUnlocked.value;
    _onBetaStatusChanged(); // Sync initial state
    _initAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) DawnUnlockService.checkAndUnlock(context);
    });
  }

  void _onBetaStatusChanged() {
    if (mounted) {
      setState(() {
        _isBetaTester = AppFeatureFlags.isBeta.value;
        _enableClubs = AppFeatureFlags.enableClubs.value;
        _enableCounselor = AppFeatureFlags.enableCounselor.value;
        _buildNavigation();
      });
    }
  }

  void _onFunModeChanged() {
    if (mounted) {
      setState(() {
        _isFunMode = FunModeService.isFunMode.value;
        _buildNavigation();
      });
    }
  }

  void _onGroveUnlockChanged() {
    if (mounted) {
      setState(() {
        _isGroveUnlocked = GroveUnlockService.isUnlocked.value;
        _buildNavigation();
      });
    }
  }

  /// Parallelizes all async init work that was previously done sequentially.
  Future<void> _initAll() async {
    await Future.wait([
      _checkOnboarding(),
      _checkAdminStatus(),
      _loadNavigationOrder(),
      _loadVersionInfo(),
    ]);
  }

  void _onVariantChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadNavigationOrder() async {
    final order = await _persistenceService.getSavedOrder();
    if (mounted) {
      setState(() {
        _customOrder = order;
        _buildNavigation();
      });
    }
  }

  @override
  void dispose() {
    AppFeatureFlags.isBeta.removeListener(_onBetaStatusChanged);
    AppFeatureFlags.enableClubs.removeListener(_onBetaStatusChanged);
    AppFeatureFlags.enableCounselor.removeListener(_onBetaStatusChanged);
    FunModeService.isFunMode.removeListener(_onFunModeChanged);
    GroveUnlockService.isUnlocked.removeListener(_onGroveUnlockChanged);
    ProfilePictureService.activeVariant.removeListener(_onVariantChanged);
    _unreadCountSubscription?.cancel();
    super.dispose();
  }

  // ============================================================================
  // ONBOARDING CHECK
  // ============================================================================

  Future<void> _checkOnboarding() async {
    if (_user == null) {
      if (mounted)
        setState(() {
          _isCheckingOnboarding = false;
          _needsOnboarding = false;
        });
      return;
    }

    final email = _user!.email ?? '';
    final isBergenStudent = email.endsWith('@bergen.org');

    if (!isBergenStudent) {
      if (mounted)
        setState(() {
          _isCheckingOnboarding = false;
          _needsOnboarding = false;
        });
      return;
    }

    // Don't block on reload — use the current verification state
    final isEmailVerified = _user!.emailVerified;

    try {
      // Use cached user doc — already fetched during boot
      final data = await UserDocCache.get();

      // If we couldn't fetch the data (timeout or error), don't force onboarding.
      // We only want to onboard if we POSITIVELY know the fields are missing.
      if (data == null) {
        if (mounted) {
          setState(() {
            _needsOnboarding = false;
            _isCheckingOnboarding = false;
          });
        }
        return;
      }

      final hasGrade = data['grade'] != null;
      final hasAcademy = data['academy'] != null;
      final needsSetup = !isEmailVerified || !hasGrade || !hasAcademy;

      if (mounted)
        setState(() {
          _needsOnboarding = needsSetup;
          _isCheckingOnboarding = false;
        });
    } catch (e) {
      print('[NAV] Error checking onboarding: $e');
      if (mounted)
        setState(() {
          _needsOnboarding = false;
          _isCheckingOnboarding = false;
        });
    }
  }

  // ============================================================================
  // USER ROLE & ACCESS CONTROL
  // ============================================================================

  void _determineUserRole() {
    final email = _user?.email ?? '';

    if (_user == null) {
      _userRole = UserRole.guest;
    } else if (email.endsWith('@bergen.org') ||
        email == "gr0ve.bca.manager@gmail.com") {
      _userRole = UserRole.student;
    } else {
      _userRole = UserRole.parent;
    }

    _buildNavigation();
  }

  Future<void> _checkAdminStatus() async {
    if (_user == null) return;

    try {
      final email = _user!.email ?? '';
      final isManagerEmail = email == "gr0ve.bca.manager@gmail.com";

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(_user!.uid)
          .get();

      if (mounted) {
        setState(() {
          _isPlatformAdmin = adminDoc.exists || isManagerEmail;
          _buildNavigation();
        });
      }
    } catch (e) {
      print('[NAV] Error checking admin status: $e');
    }
  }

  // ============================================================================
  // NAVIGATION CONFIGURATION
  // ============================================================================

  void _buildNavigation() {
    final baseDocs = _getNavigationForRole(_userRole, _isPlatformAdmin);

    if (_customOrder != null && _customOrder!.isNotEmpty) {
      final Map<String, NavConfig> configMap = {
        for (var config in baseDocs) config.id: config,
      };

      List<NavConfig> sortedConfigs = [];
      for (var id in _customOrder!) {
        if (configMap.containsKey(id)) {
          sortedConfigs.add(configMap[id]!);
          configMap.remove(id);
        }
      }
      sortedConfigs.addAll(configMap.values);
      _navConfigs = sortedConfigs;
    } else {
      _navConfigs = baseDocs;
    }

    _screens = _navConfigs.map((c) => c.screen).toList();

    // Sync index with selected ID
    final newIndex = _navConfigs.indexWhere((c) => c.id == _selectedTabId);
    if (newIndex != -1) {
      _selectedIndex = newIndex;
    } else if (_navConfigs.isNotEmpty) {
      _selectedIndex = 0;
      _selectedTabId = _navConfigs[0].id;
    }
  }

  List<NavConfig> _getNavigationForRole(UserRole role, bool isAdmin) {
    switch (role) {
      case UserRole.guest:
        return [
          NavConfig(
            id: 'bus',
            iconData: HugeIcons.strokeRoundedBus02,
            label: 'Bus',
            screen: const BusScreen(),
          ),
          NavConfig(
            id: 'account',
            iconData: HugeIcons.strokeRoundedUser,
            label: 'Account',
            screen: AccountScreen(onCustomizeNavigation: _showReorderMenu),
          ),
          NavConfig(
            id: 'changelog',
            iconData: HugeIcons.strokeRoundedClock01,
            label: 'Changelog',
            screen: const ChangelogScreen(),
          ),
        ];

      case UserRole.student:
        final baseNav = [
          NavConfig(
            id: 'home',
            iconData: HugeIcons.strokeRoundedHome01,
            label: 'Home',
            screen: const HomeScreen(),
          ),
          NavConfig(
            id: 'absence',
            iconData: HugeIcons.strokeRoundedUserRemove02,
            label: 'Absence',
            screen: const AbsenceScreen(),
          ),
          NavConfig(
            id: 'bus',
            iconData: HugeIcons.strokeRoundedBus02,
            label: 'Bus',
            screen: const BusScreen(),
            notificationKey: 'bus',
          ),
          NavConfig(
            id: 'calendar',
            iconData: HugeIcons.strokeRoundedCalendar03,
            label: 'Calendar',
            screen: const CalendarScreen(),
          ),
          // Extra screens — registered so deep-links & notification routing work,
          // but hidden from the nav bar. Accessible via ··· > Extra.
          NavConfig(
            id: 'lunch_menu',
            iconData: HugeIcons.strokeRoundedRestaurant02,
            label: 'Lunch Menu',
            screen: const LunchMenuScreen(),
          ),
          NavConfig(
            id: 'news',
            iconData: HugeIcons.strokeRoundedNews01,
            label: 'News',
            screen: const NewsScreen(),
          ),
          NavConfig(
            id: 'help',
            iconData: HugeIcons.strokeRoundedHelpCircle,
            label: 'Help',
            screen: const HelpScreen(),
          ),
          NavConfig(
            id: 'changelog',
            iconData: HugeIcons.strokeRoundedClock01,
            label: 'Changelog',
            screen: const ChangelogScreen(),
          ),
        ];

        if (_isFunMode && _isGroveUnlocked) {
          baseNav.add(
            NavConfig(
              id: 'grove',
              label: 'Gr0ve',
              iconData: HugeIcons.strokeRoundedPlant02,
              screen: GroveScreen(isBetaTester: _isBetaTester),
            ),
          );
        }

        if (isAdmin) {
          baseNav.addAll([
            NavConfig(
              id: 'event_requests',
              iconData: HugeIcons.strokeRoundedTaskDaily02,
              label: 'Event Requests',
              screen: const AdminCalendarRequestsScreen(),
              isAdminOnly: true,
            ),
            NavConfig(
              id: 'group_requests',
              iconData: HugeIcons.strokeRoundedUserQuestion01,
              label: 'Group Requests',
              screen: const AdminPanelScreen(),
              isAdminOnly: true,
              notificationKey: 'group_requests',
            ),
          ]);
        }

        if (_enableClubs) {
          baseNav.add(
            NavConfig(
              id: 'groups',
              iconData: HugeIcons.strokeRoundedUserGroup,
              label: 'Groups',
              screen: const ClubScreen(),
              showClubNotifications: true,
            ),
          );
        }

        if (_enableCounselor) {
          baseNav.add(
            NavConfig(
              id: 'counselor',
              iconData: HugeIcons.strokeRoundedAiChat02,
              label: 'Counselor',
              screen: const CounselorScreen(),
            ),
          );
        }

        baseNav.addAll([
          NavConfig(
            id: 'links',
            iconData: HugeIcons.strokeRoundedLink01,
            label: 'Links',
            screen: const LinksScreen(),
          ),
          NavConfig(
            id: 'account',
            iconData: HugeIcons.strokeRoundedUser,
            label: 'Account',
            screen: AccountScreen(onCustomizeNavigation: _showReorderMenu),
          ),
        ]);

        return baseNav;

      case UserRole.parent:
        return [
          NavConfig(
            id: 'bus',
            iconData: HugeIcons.strokeRoundedBus02,
            label: 'Bus',
            screen: const BusScreen(),
          ),
          NavConfig(
            id: 'account',
            iconData: HugeIcons.strokeRoundedUser,
            label: 'Account',
            screen: AccountScreen(onCustomizeNavigation: _showReorderMenu),
          ),
        ];
    }
  }

  // ============================================================================
  // NOTIFICATION HANDLING
  // ============================================================================

  void _subscribeToUnreadCounts() {
    _unreadCountSubscription = NotificationService().unreadCountStream.listen((
      data,
    ) {
      if (mounted) {
        setState(() {
          final countsMap = data['counts'] != null
              ? Map.from(data['counts'] as Map)
              : null;
          final announcementsMap = data['announcementsByClub'] != null
              ? Map.from(data['announcementsByClub'] as Map)
              : null;
          final qaMap = data['qaByClub'] != null
              ? Map.from(data['qaByClub'] as Map)
              : null;

          _unreadCounts =
              countsMap?.map(
                (key, value) => MapEntry(key.toString(), value as int),
              ) ??
              {};
          _unreadAnnouncementsByClub =
              announcementsMap?.map(
                (key, value) => MapEntry(key.toString(), value as int),
              ) ??
              {};
          _unreadQAByClub =
              qaMap?.map(
                (key, value) => MapEntry(key.toString(), value as int),
              ) ??
              {};
        });
      }
    });

    setState(() {
      _unreadCounts = NotificationService().unreadCounts;
      _unreadAnnouncementsByClub =
          NotificationService().unreadAnnouncementsByClub;
      _unreadQAByClub = NotificationService().unreadQAByClub;
    });
  }

  void _setupNotificationHandler() {
    print('[NAV] Setting up notification handler');

    NotificationService().setNotificationTapCallback((
      NotificationResponse response,
    ) {
      final payload = response.payload;
      print('[NAV] Notification tapped with payload: $payload');

      if (!_isVersionAbove150() || payload == null) return;

      if (payload.startsWith('announcement:')) {
        _navigateToScreenByType(ClubScreen);
      } else if (payload.startsWith('join_request:') ||
          payload.startsWith('club_request:')) {
        _navigateToScreenByType(AdminPanelScreen);
        NotificationService().clearUnreadCount('join_requests');
        NotificationService().clearUnreadCount('club_requests');
      } else if (payload.startsWith('bus:')) {
        _navigateToScreenByType(BusScreen);
      }
    });
  }

  void _navigateToScreenByType(Type screenType) {
    final index = _screens.indexWhere(
      (screen) => screen.runtimeType == screenType,
    );
    if (index != -1 && mounted) {
      setState(() => _selectedIndex = index);
    }
  }

  // ============================================================================
  // VERSION MANAGEMENT
  // ============================================================================

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _versionCode = packageInfo.version);
      }
      print('[NAV] App version: $_versionCode');
    } catch (e) {
      print('[NAV] Error loading version info: $e');
    }
  }

  bool _isVersionAbove150() {
    try {
      final parts = _versionCode.split('.');
      if (parts.length < 2) return false;
      final major = int.tryParse(parts[0]) ?? 0;
      final minor = int.tryParse(parts[1]) ?? 0;
      return major > 1 || (major == 1 && minor >= 5);
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // NAVIGATION LOGIC
  // ============================================================================

  void _changeIndex(int index) {
    if (index == -1 || index >= _navConfigs.length) return;
    final config = _navConfigs[index];

    if (config.notificationKey != null) {
      NotificationService().clearUnreadCount(config.notificationKey!);
    }
    setState(() {
      _selectedIndex = index;
      _selectedTabId = config.id;
    });
  }

  int _getTotalUnreadCount(NavConfig config) {
    int count = 0;
    if (config.showClubNotifications) {
      count += _unreadAnnouncementsByClub.values.fold(0, (s, c) => s + c);
      count += _unreadQAByClub.values.fold(0, (s, c) => s + c);
      count += _unreadCounts['qa_replies'] ?? 0;
      count += _unreadCounts['unread_questions'] ?? 0;
    } else if (config.notificationKey != null) {
      count = _unreadCounts[config.notificationKey] ?? 0;
    }
    return count;
  }

  // ============================================================================
  // UI - MORE MENU
  // ============================================================================

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMoreMenu(),
    );
  }

  Widget _buildMoreMenu() {
    final colors = Theme.of(context).colorScheme;
    final isStudent = _userRole == UserRole.student;

    // Only non-extra configs count toward overflow items
    final visibleConfigs = _navConfigs
        .where((c) => !_extraScreenIds.contains(c.id))
        .toList();
    final moreItems = visibleConfigs.length > 5
        ? visibleConfigs.sublist(4)
        : <NavConfig>[];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'More Options',
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Customize Navigation button
          InkWell(
            onTap: () {
              Navigator.pop(context);
              _showReorderMenu();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedSorting01,
                    color: colors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Customize Navigation',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Overflow nav items
          if (moreItems.isNotEmpty)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: moreItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final config = moreItems[index];
                  final actualIndex = _navConfigs.indexOf(config);
                  final isSelected = _selectedIndex == actualIndex;
                  final unreadCount = _getTotalUnreadCount(config);

                  return ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      _changeIndex(actualIndex);
                    },
                    leading: AnimatedScale(
                      scale: isSelected ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: HugeIcon(
                        icon: config.iconData,
                        color: isSelected
                            ? colors.primary
                            : colors.onSurface.withOpacity(0.4),
                      ),
                    ),
                    title: Text(
                      config.label,
                      style: TextStyle(
                        color: isSelected ? colors.primary : colors.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: TextStyle(
                                color: colors.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isSelected) ...[
                          if (unreadCount > 0) const SizedBox(width: 8),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                            color: colors.primary,
                            size: 20.0,
                          ),
                        ],
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: isSelected
                        ? colors.primary.withOpacity(0.05)
                        : null,
                  );
                },
              ),
            ),

          // ── Extra entry — BCA students only ────────────────────────────────
          if (isStudent) ...[
            Divider(height: 32, color: colors.onSurface.withOpacity(0.08)),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _showExtraMenu();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedGridView,
                      color: colors.onSurface.withOpacity(0.55),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Extra',
                      style: TextStyle(
                        color: colors.onSurface.withOpacity(0.75),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Lunch, News, Help...',
                      style: TextStyle(
                        color: colors.onSurface.withOpacity(0.35),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurface.withOpacity(0.3),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============================================================================
  // UI - EXTRA MENU (Lunch, News, Help)
  // ============================================================================

  void _showExtraMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildExtraMenu(),
    );
  }

  Widget _buildExtraMenu() {
    final colors = Theme.of(context).colorScheme;

    final extraConfigs = _navConfigs
        .where((c) => _extraScreenIds.contains(c.id))
        .toList();

    const descriptions = {
      'lunch_menu': "Today's cafeteria menu",
      'news': 'Bergen Community news & updates',
      'help': 'FAQs and support resources',
      'changelog': 'Version highlights and updates',
    };

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Extra',
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...extraConfigs.map((config) {
            final index = _navConfigs.indexOf(config);
            final isSelected = _selectedIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () {
                  Navigator.pop(context);
                  _changeIndex(index);
                },
                leading: AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: HugeIcon(
                    icon: config.iconData,
                    color: isSelected
                        ? colors.primary
                        : colors.onSurface.withOpacity(0.4),
                  ),
                ),
                title: Text(
                  config.label,
                  style: TextStyle(
                    color: isSelected ? colors.primary : colors.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  descriptions[config.id] ?? '',
                  style: TextStyle(
                    color: colors.onSurface.withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
                trailing: isSelected
                    ? HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: colors.primary,
                        size: 20.0,
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: colors.onSurface.withOpacity(0.3),
                        size: 20,
                      ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: isSelected
                    ? colors.primary.withOpacity(0.05)
                    : colors.onSurface.withOpacity(0.03),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ============================================================================
  // UI - MAIN BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isCheckingOnboarding) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    if (_needsOnboarding) {
      return BergenOnboardingScreen(
        onComplete: () => setState(() => _needsOnboarding = false),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Theme.of(context).brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: colors.surface,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return isWide
              ? _buildWideLayout(context, colors)
              : _buildMobileLayout(context, colors);
        },
      ),
    );
  }

  // ============================================================================
  // UI - WIDE LAYOUT
  // ============================================================================

  Widget _buildWideLayout(BuildContext context, ColorScheme colors) {
    // Extra screens are not shown in the sidebar either — still accessible
    // via the More / Extra flow if needed, or directly by deep-link.
    final sidebarConfigs = _navConfigs
        .where((c) => !_extraScreenIds.contains(c.id))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                right: BorderSide(color: colors.onSurface.withOpacity(0.05)),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Image.asset(
                  Theme.of(context).brightness == Brightness.light
                      ? 'assets/app_icon.png'
                      : 'assets/appicon_dark.png',
                  height: 48,
                  width: 48,
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: ListView.builder(
                    itemCount: sidebarConfigs.length,
                    itemBuilder: (context, index) {
                      final config = sidebarConfigs[index];
                      final navIndex = _navConfigs.indexOf(config);
                      final isSelected = _selectedIndex == navIndex;
                      final unreadCount = _getTotalUnreadCount(config);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _buildSidebarItem(
                          navIndex,
                          config,
                          isSelected,
                          unreadCount,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey<String>(_selectedTabId),
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    int index,
    NavConfig config,
    bool isSelected,
    int unreadCount,
  ) {
    final colors = context.colors;

    return Tooltip(
      message: config.label,
      child: InkWell(
        onTap: () => _changeIndex(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: config.id == 'account'
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            ProfilePictureService.activeVariant.value.assetPath(
                              Theme.of(context).brightness,
                            ),
                            fit: BoxFit.cover,
                            height: 28,
                            width: 28,
                          ),
                        )
                      : HugeIcon(
                          icon: config.iconData,
                          color: isSelected
                              ? colors.primary
                              : colors.onSurface.withOpacity(0.4),
                          size: 28,
                        ),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 12,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: TextStyle(
                        color: colors.onError,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // UI - MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(BuildContext context, ColorScheme colors) {
    // Filter out extra screens — they don't appear in the bottom bar
    final visibleConfigs = _navConfigs
        .where((c) => !_extraScreenIds.contains(c.id))
        .toList();

    final int displayCount = visibleConfigs.length > 5
        ? 4
        : visibleConfigs.length;
    final List<Widget> navItems = [];

    for (int i = 0; i < displayCount; i++) {
      final config = visibleConfigs[i];
      final navIndex = _navConfigs.indexOf(config);
      navItems.add(_buildNavItem(navIndex, config, _selectedIndex == navIndex));
    }

    if (visibleConfigs.length > 5) {
      final anyMoreSelected = visibleConfigs
          .sublist(4)
          .any((c) => _selectedIndex == _navConfigs.indexOf(c));
      navItems.add(_buildMoreNavItem(anyMoreSelected));
    }

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: KeyedSubtree(
                key: ValueKey<String>(_selectedTabId),
                // Inject nav-bar clearance so every screen's scrollable content
                // stops above the floating pill. Nav pill sits at bottom:20
                // with all(10) padding + 28px icons + 24px v-pad ≈ 120px total.
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    // padding is used by SafeArea / scroll views for auto-insets
                    padding: MediaQuery.of(
                      context,
                    ).padding.copyWith(bottom: 120),
                    // viewPadding is used by Scaffold, keyboard, etc.
                    viewPadding: MediaQuery.of(
                      context,
                    ).viewPadding.copyWith(bottom: 120),
                  ),
                  child: _screens[_selectedIndex],
                ),
              ),
            ),
            // Mask for the bottom area to prevent content from being visible behind/below the pill
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 110,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withOpacity(0.0),
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withOpacity(0.8),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: navItems,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavConfig config, bool isSelected) {
    final unreadCount = _getTotalUnreadCount(config);

    return GestureDetector(
      onTap: () => _changeIndex(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: AnimatedScale(
          scale: isSelected ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: config.id == 'account'
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          ProfilePictureService.activeVariant.value.assetPath(
                            Theme.of(context).brightness,
                          ),
                          fit: BoxFit.cover,
                          height: 28,
                          width: 28,
                        ),
                      )
                    : HugeIcon(
                        icon: config.iconData,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.onSurface.withOpacity(0.5),
                        size: 28.0,
                      ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.colors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: TextStyle(
                        color: context.colors.onError,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreNavItem(bool isSelected) {
    final visibleConfigs = _navConfigs
        .where((c) => !_extraScreenIds.contains(c.id))
        .toList();

    bool hasNotificationsInRange = false;
    if (visibleConfigs.length > 5) {
      for (final config in visibleConfigs.sublist(4)) {
        if (_getTotalUnreadCount(config) > 0) {
          hasNotificationsInRange = true;
          break;
        }
      }
    }

    return GestureDetector(
      onTap: _showMoreMenu,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: AnimatedScale(
          scale: isSelected ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedMoreHorizontal,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurface.withOpacity(0.5),
                size: 28.0,
              ),
              if (hasNotificationsInRange)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: context.colors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // UI - REORDERING
  // ============================================================================

  void _showReorderMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildReorderMenu(),
    );
  }

  Widget _buildReorderMenu() {
    final colors = Theme.of(context).colorScheme;
    List<NavConfig> itemsToReorder = List.from(_navConfigs);

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Customize Navigation',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Drag items to reorder them in your navigation bar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: itemsToReorder.length,
                  onReorder: (oldIndex, newIndex) {
                    setModalState(() {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = itemsToReorder.removeAt(oldIndex);
                      itemsToReorder.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final config = itemsToReorder[index];
                    return ListTile(
                      key: ValueKey(config.id),
                      leading: HugeIcon(
                        icon: config.iconData,
                        color: colors.primary,
                      ),
                      title: Text(config.label),
                      trailing: Icon(
                        Icons.drag_handle_rounded,
                        color: colors.onSurface.withOpacity(0.2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final newOrder = itemsToReorder.map((c) => c.id).toList();
                    await _persistenceService.saveOrder(newOrder);
                    if (mounted) {
                      setState(() {
                        _customOrder = newOrder;
                        _buildNavigation();
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navigation order saved!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Order',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await _persistenceService.saveOrder([]);
                  if (mounted) {
                    setState(() {
                      _customOrder = null;
                      _buildNavigation();
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Reset to Default',
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
