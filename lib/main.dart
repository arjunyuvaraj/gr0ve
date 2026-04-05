import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gr0ve/core/theme/persona_theme.dart';
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

// Global navigator key for handling notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first as everything depends on it
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 1. Background tasks (Non-critical, don't block UI)
  _backgroundInit();

  // 2. Critical UI initialization (Needed for initial theme/env)
  await Future.wait([
    NotificationService().initialize(),
    AppFeatureFlags.load(),
    CounselorPersonaService.init(),
    ProfilePictureService.init(),
    AccessibilityService.init(),
    ThemeColorService.init(),
    dotenv.load(fileName: ".env"),
  ]);

  if (kDebugMode) {
    debugPrint('[ENV] API_KEY = ${dotenv.env['API_KEY']?.substring(0, 5)}...');
  }

  runApp(const MyApp());
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
Future<void> _bootUserServices(User user) async {
  if (kDebugMode) print('[BOOT] Booting services for ${user.uid}');

  // Run everything in parallel — order ydoesn't matter
  await Future.wait([
    StarredTeacherService.load(),
    StarredBusService.load(),
    CalendarService.loadAllEvents(),
    LayoutService.load(),
    PomPrefsService.load(),
    ProfilePictureService.init(),
    DawnUnlockService.init(),
  ]);

  if (kDebugMode) print('[BOOT] All services ready');
}

// ── Tears down everything on logout ──────────────────────────────────────────
void _teardownUserServices() {
  StarredTeacherService.reset();
  StarredBusService.reset();
  CalendarService.reset();
  NotificationService().stopListening();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showLoading = true;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        NotificationService().startListening();
        // Boot all snapshot-card data sources as soon as the user is known
        _bootUserServices(user);
      } else {
        _teardownUserServices();
      }
    });

    _setupNotificationTapHandler();

    // Show splash animation for 1.8 seconds so the full tree stagger finishes
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _showLoading = false);
      }
    });
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
                    return SchoolClosedOverlay(child: child!);
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
