import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gr0ve/core/theme/persona_theme.dart';
import 'package:gr0ve/core/widgets/misc/value_listenable_builder_2.dart';
import 'package:gr0ve/features/admin/screens/admin_panel_screen.dart';
import 'package:gr0ve/features/absence/screens/absence_screen.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/features/help/help_screen.dart';
import 'package:gr0ve/features/home/screens/home_screen.dart';
import 'package:gr0ve/features/club/screens/join_requests_screen.dart';
import 'package:gr0ve/features/club/screens/club_detail_screen.dart';
import 'package:gr0ve/features/landing/screens/landing_screen.dart';
import 'package:gr0ve/features/landing/screens/landing_screen_web.dart';
import 'package:gr0ve/features/landing/screens/login_screen.dart';
import 'package:gr0ve/features/landing/screens/register_screen.dart';
import 'package:gr0ve/features/links/screens/link_screen.dart';
import 'package:gr0ve/features/lunch_menu/screens/lunch_menu_screen.dart';
import 'package:gr0ve/features/navigation/screens/navigation_screen.dart';
import 'package:gr0ve/features/privacy_policy/screens/privacy_policy_screen.dart';
import 'package:gr0ve/legal/terms_screen.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:gr0ve/features/absence/services/teacher_service.dart';
import 'package:gr0ve/core/helper/landing_decider.dart';
import 'package:gr0ve/features/account/services/dawn_unlock_service.dart';
import 'package:flutter/foundation.dart';
import 'package:gr0ve/core/helper/teacher_utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'configuration/firebase_options.dart';
import 'package:gr0ve/features/onboarding/screens/loading_screen.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';

// ── Services that need to boot on login ──────────────────────────────────────
import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/features/calendar/services/calendar_service.dart';
import 'package:gr0ve/features/home/services/layout_service.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_pomodoro_card.dart'
    show PomPrefsService;
import 'package:gr0ve/features/account/services/profile_picture_service.dart';
import 'package:gr0ve/services/settings/accessibility_service.dart';
import 'package:gr0ve/services/settings/theme_color_service.dart';
import 'package:gr0ve/features/home/widgets/school_closed_overlay.dart';
import 'package:gr0ve/features/maintenance/screens/maintenance_screen.dart';

// Global navigator key for handling notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  final bootWatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  print('[BOOT] WidgetsBinding: ${bootWatch.elapsedMilliseconds}ms');

  // Initialize Firebase first as everything depends on it
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        print('[BOOT] Firebase.init TIMEOUT - proceeding anyway');
        if (Firebase.apps.isNotEmpty) return Firebase.app();
        throw Exception(
          'Firebase initialization timed out. This often happens on hot restarts '
          'with a buggy emulator. Please STOP the app (press "q") and run "flutter run" again.',
        );
      },
    );
  }
  print('[BOOT] Firebase.init: ${bootWatch.elapsedMilliseconds}ms');

  // 1. Critical UI-blocking init — ONLY local/instant services needed for
  //    the very first frame (SharedPreferences reads, ~5ms each).
  //    NO Firestore calls here — those require a gRPC channel that takes
  //    hundreds of ms to establish on Android cold start.
  await Future.wait([
    AccessibilityService.init(), // SharedPreferences only
    ThemeColorService.init(), // SharedPreferences only
  ]);
  print('[BOOT] SharedPrefs init: ${bootWatch.elapsedMilliseconds}ms');

  // 2. Render the app IMMEDIATELY — splash screen appears
  runApp(const MyApp());
  print('[BOOT] runApp called: ${bootWatch.elapsedMilliseconds}ms');

  // 3. Deferred init — everything that touches Firestore or network.
  //    Runs AFTER the first frame is painted, so the user sees the splash
  //    instantly instead of staring at a blank screen.
  _deferredInit(bootWatch);
}

/// Services that can init after the first frame — Firestore, FCM, etc.
/// All of these use ValueNotifiers, so the UI updates reactively when ready.
void _deferredInit(Stopwatch bootWatch) {
  // Load dotenv and feature flags — lightweight, non-blocking
  dotenv
      .load(fileName: ".env")
      .then(
        (_) => print('[BOOT] dotenv ready: ${bootWatch.elapsedMilliseconds}ms'),
      );
  AppFeatureFlags.load().then(
    (_) =>
        print('[BOOT] FeatureFlags ready: ${bootWatch.elapsedMilliseconds}ms'),
  );

  // Notification init (local notifications plugin + FCM) — fire and forget
  NotificationService().initialize().then(
    (_) =>
        print('[BOOT] Notifications ready: ${bootWatch.elapsedMilliseconds}ms'),
  );

  // Teacher list — background, non-blocking
  _backgroundInit();
}

/// Tasks that can run in the background after/during boot without blocking runApp
void _backgroundInit() {
  fetchTeacherListFromFirebase()
      .then((list) {
        teacherList = list;
        if (kDebugMode)
          print('[BOOT] Teacher list loaded: ${list.length} entries');
      })
      .catchError((e) {
        if (kDebugMode) print('[BOOT] Error loading teachers: $e');
        teacherList = {};
      });
  absenceList = {};
}

// ── Boots every service that feeds snapshot cards + home screen widgets ───────
// OPTIMIZED: Fetch user doc ONCE, then share it across all services that need it.
Future<void> _bootUserServices(User user) async {
  if (kDebugMode) print('[BOOT] Booting services for ${user.uid}');

  final sw = Stopwatch()..start();

  // Phase 1: Fetch the user document ONCE (this is the single most expensive
  // operation — gRPC channel establishment on cold start)
  final userData = await UserDocCache.get();
  if (kDebugMode) print('[BOOT] UserDoc fetched (${sw.elapsedMilliseconds}ms)');

  // Phase 2: Boot all services in parallel, sharing the cached user doc.
  // CounselorPersona and ProfilePicture both need unlock flags from the user doc.
  // DawnUnlock needs the dawn_avatar_unlocked field.
  // StarredTeacher/Bus need their own sub-collections (separate reads, but small).
  // LayoutService needs user settings sub-collection.
  // PomPrefs needs user settings sub-collection.
  await Future.wait([
    CounselorPersonaService.init(cachedUserData: userData),
    ProfilePictureService.init(cachedUserData: userData),
    DawnUnlockService.init(cachedUserData: userData),
    StarredTeacherService.load(), // Small sub-collection read
    StarredBusService.load(), // Small sub-collection read
    LayoutService.load(), // Small sub-collection read
    PomPrefsService.load(), // Small sub-collection read
  ]).timeout(
    const Duration(seconds: 4),
    onTimeout: () {
      print('[BOOT] Service boot TIMEOUT - showing UI anyway');
      return [];
    },
  );

  if (kDebugMode)
    print('[BOOT] Core services ready (${sw.elapsedMilliseconds}ms)');

  // Phase 3: Calendar is the heaviest service — it queries groups, BCA events,
  // personal events, and sets up Firestore streams. Run it AFTER core services
  // so the UI can render while it loads. The calendar widget uses ValueNotifiers
  // and will update reactively.
  CalendarService.loadAllEvents().then((_) {
    if (kDebugMode)
      print('[BOOT] Calendar ready (${sw.elapsedMilliseconds}ms)');
  });
}

// ── Tears down everything on logout ──────────────────────────────────────────
void _teardownUserServices() {
  StarredTeacherService.reset();
  StarredBusService.reset();
  CalendarService.reset();
  NotificationService().stopListening();
  UserDocCache.invalidate();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showLoading = true;

  bool _isFirstAuthEvent = true;

  @override
  void initState() {
    super.initState();
    final initWatch = Stopwatch()..start();

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      final isFirst = _isFirstAuthEvent;
      if (isFirst) _isFirstAuthEvent = false;

      print('[MAIN] Auth state change. User: ${user?.uid}, isFirst: $isFirst');

      if (user == null) {
        _teardownUserServices();
      } else {
        if (isFirst) {
          print('[MAIN] Starting boot for initial user...');
          // Delay notifications slightly to prioritize core UI boot
          Future.delayed(const Duration(milliseconds: 500), () {
            NotificationService().startListening();
          });

          await _bootUserServices(user);
          print('[MAIN] Boot complete: ${initWatch.elapsedMilliseconds}ms');
        } else {
          NotificationService().startListening();
          print('[MAIN] Starting boot for newly logged in user...');
          _bootUserServices(user);
        }
      }

      if (isFirst) {
        print(
          '[MAIN] Setting _showLoading = false (${initWatch.elapsedMilliseconds}ms total)',
        );
        if (mounted) setState(() => _showLoading = false);
      }
    });

    _setupNotificationTapHandler();
  }

  void _setupNotificationTapHandler() {
    NotificationService().setNotificationTapCallback(_handleNotificationTap);
  }

  void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) {
      print('[MAIN] Notification tapped with no payload');
      return;
    }

    print('[MAIN] Notification tapped with payload: $payload');

    Future.delayed(const Duration(milliseconds: 300), () {
      final context = navigatorKey.currentContext;
      if (context == null) {
        print('[MAIN] No navigation context available');
        return;
      }

      if (payload.startsWith('bus:')) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const NavigationScreen(initialIndex: 2),
          ),
          (route) => false,
        );
      } else if (payload.startsWith('qa_reply:') ||
          payload.startsWith('qa_question:')) {
        final parts = payload.split(':');
        if (parts.length >= 4) {
          final groupId = parts[1];
          final announcementId = parts[2];
          final questionId = parts[3];
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => ClubDetailScreen(
                groupId: groupId,
                initialAnnouncementId: announcementId,
                initialQuestionId: questionId,
              ),
            ),
            (route) => false,
          );
        }
      } else if (payload.startsWith('announcement:')) {
        final groupId = payload.substring('announcement:'.length);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ClubDetailScreen(groupId: groupId),
          ),
          (route) => false,
        );
      } else if (payload.startsWith('join_request:')) {
        final groupId = payload.substring('join_request:'.length);
        Navigator.of(
          context,
        ).pushNamed('/club/join-requests', arguments: groupId);
      } else if (payload.startsWith('club_request:')) {
        Navigator.of(context).pushNamed('/admin');
      } else {
        print('[MAIN] Unknown payload type: $payload');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityService.accessibleColors,
      builder: (context, isAccessible, _) {
        return ValueListenableBuilder<CounselorPersona>(
          valueListenable: CounselorPersonaService.activePersona,
          builder: (context, persona, _) {
            return ValueListenableBuilder<AppThemeColor>(
              valueListenable: ThemeColorService.activeColor,
              builder: (context, themeColor, _) {
                return MaterialApp(
                  title: 'Gr0ve',
                  navigatorKey: navigatorKey,
                  theme: PersonaTheme.light(
                    persona,
                    themeColor,
                    isAccessible: isAccessible,
                  ),
                  darkTheme: PersonaTheme.dark(
                    persona,
                    themeColor,
                    isAccessible: isAccessible,
                  ),
                  themeMode: ThemeMode.system,
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) {
                    return StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        return ValueListenableBuilder2<bool, bool>(
                          first: AppFeatureFlags.isReady,
                          second: AppFeatureFlags.lockdownMode,
                          builder: (context, isReady, isLocked, _) {
                            // Don't show anything until we know the status
                            if (!isReady)
                              return const Scaffold(
                                backgroundColor: Colors.black,
                              );

                            final user = snapshot.data;
                            final isBeta = AppFeatureFlags.isBetaTester(
                              user?.email,
                            );

                            // If locked and user is NOT a beta tester, show maintenance
                            if (isLocked && !isBeta) {
                              return const MaintenanceScreen();
                            }

                            return SchoolClosedOverlay(child: child!);
                          },
                        );
                      },
                    );
                  },
                  home: _showLoading
                      ? const LogoLoadingScreen()
                      : LandingDecider(
                          landingPage: kIsWeb
                              ? const LandingWebsiteScreen()
                              : const LandingScreen(),
                          loginPage: const LoginScreen(),
                          navigationRoute: '/navigation',
                        ),
                  routes: {
                    '/home': (context) => const HomeScreen(),
                    '/teacher_absence': (context) => const AbsenceScreen(),
                    '/landing': (context) => const LandingScreen(),
                    '/login': (context) => const LoginScreen(),
                    '/admin': (context) => const AdminPanelScreen(),
                    '/register': (context) => const RegisterScreen(),
                    '/navigation': (context) => const NavigationScreen(),
                    '/privacy_policy': (context) => const PrivacyPolicyScreen(),
                    '/help': (context) => const HelpScreen(),
                    '/lunch_menu': (context) => const LunchMenuScreen(),
                    '/links': (context) => const LinksScreen(),
                    '/terms': (context) => const TermsOfServiceScreen(),
                  },
                  onGenerateRoute: (settings) {
                    if (settings.name == '/club/join-requests') {
                      final groupId = settings.arguments as String;
                      return MaterialPageRoute(
                        builder: (context) =>
                            JoinRequestsScreen(groupId: groupId),
                      );
                    }
                    return null;
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
