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
import 'package:gr0ve/features/authentication/services/authentication_service.dart';
import 'package:gr0ve/core/helper/landing_decider.dart';
import 'package:gr0ve/features/account/services/dawn_unlock_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'configuration/firebase_options.dart';
import 'package:gr0ve/features/onboarding/screens/loading_screen.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';

import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/features/calendar/services/calendar_service.dart';
import 'package:gr0ve/features/home/services/layout_service.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_pomodoro_card.dart'
    show PomPrefsService;
import 'package:gr0ve/features/account/services/profile_picture_service.dart';
import 'package:gr0ve/services/settings/accessibility_service.dart';
import 'package:gr0ve/services/settings/theme_color_service.dart';
import 'package:gr0ve/core/services/network_time_service.dart';
import 'package:gr0ve/features/home/widgets/school_closed_overlay.dart';
import 'package:gr0ve/features/maintenance/screens/maintenance_screen.dart';
import 'package:gr0ve/services/settings/fun_mode_service.dart';
import 'package:gr0ve/features/grove/services/grove_unlock_service.dart';
import 'package:gr0ve/features/easter_eggs/hidden_fish/hidden_fish_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

DateTime? debugDateOverride = null;
DateTime get debugNow => debugDateOverride ?? DateTime.now();

void main() async {
  final bootWatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode)
    print('[BOOT] WidgetsBinding: ${bootWatch.elapsedMilliseconds}ms');

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (kDebugMode)
          print('[BOOT] Firebase.init TIMEOUT - proceeding anyway');
        if (Firebase.apps.isNotEmpty) return Firebase.app();
        throw Exception(
          'Firebase initialization timed out. This often happens on hot restarts '
          'with a buggy emulator. Please STOP the app (press "q") and run "flutter run" again.',
        );
      },
    );
  }
  if (kDebugMode)
    print('[BOOT] Firebase.init: ${bootWatch.elapsedMilliseconds}ms');

  await Future.wait([
    AccessibilityService.init(),
    ThemeColorService.init(),
    FunModeService.init(),
  ]);
  if (kDebugMode)
    print('[BOOT] SharedPrefs init: ${bootWatch.elapsedMilliseconds}ms');

  runApp(const MyApp());
  if (kDebugMode)
    print('[BOOT] runApp called: ${bootWatch.elapsedMilliseconds}ms');

  _deferredInit(bootWatch);
}

void _deferredInit(Stopwatch bootWatch) {
  dotenv
      .load(fileName: ".env")
      .then((_) {
        if (kDebugMode) {
          print('[BOOT] dotenv ready: ${bootWatch.elapsedMilliseconds}ms');
        }
      })
      .catchError((error) {
        if (kDebugMode) {
          print('[BOOT] dotenv unavailable: $error');
        }
      });
  AppFeatureFlags.load().then((_) {
    if (kDebugMode)
      print('[BOOT] FeatureFlags ready: ${bootWatch.elapsedMilliseconds}ms');
  });

  NotificationService().initialize().then((_) {
    if (kDebugMode)
      print('[BOOT] Notifications ready: ${bootWatch.elapsedMilliseconds}ms');
  });

  NetworkTimeService.sync().then((_) {
    if (kDebugMode)
      print('[BOOT] Time sync ready: ${bootWatch.elapsedMilliseconds}ms');
  });
}

Future<void> _bootUserServices(User user) async {
  if (kDebugMode) print('[BOOT] Booting services for ${user.uid}');

  final sw = Stopwatch()..start();

  // Retry up to 3 times with a short delay to handle the race condition where
  // a newly-created Firestore document hasn't propagated by the time we boot.
  Map<String, dynamic>? userData;
  for (int attempt = 1; attempt <= 3; attempt++) {
    userData = await UserDocCache.get();
    if (userData != null) break;
    if (attempt < 3) {
      if (kDebugMode) {
        print('[BOOT] UserDoc null on attempt $attempt — retrying in 1.5s');
      }
      UserDocCache.invalidate();
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  if (kDebugMode) print('[BOOT] UserDoc fetched (${sw.elapsedMilliseconds}ms)');

  if (userData == null) {
    if (kDebugMode)
      print('[BOOT] User document missing after retries - signing out');
    AuthenticationService().signOut();
    return;
  }

  await Future.wait([
    CounselorPersonaService.init(cachedUserData: userData),
    ProfilePictureService.init(cachedUserData: userData),
    DawnUnlockService.init(cachedUserData: userData),
    GroveUnlockService.init(cachedUserData: userData),
    AppFeatureFlags.load(),
    HiddenFishService.init(cachedUserData: userData),
    StarredTeacherService.load(),
    StarredBusService.load(),
    LayoutService.load(),
    PomPrefsService.load(),
  ]).timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      if (kDebugMode) print('[BOOT] Service boot TIMEOUT - showing UI anyway');
      return [];
    },
  );

  if (kDebugMode) {
    print('[BOOT] Core services ready (${sw.elapsedMilliseconds}ms)');
  }

  if (kDebugMode)
    print('[BOOT] User services ready (${sw.elapsedMilliseconds}ms)');
}

void _teardownUserServices() {
  StarredTeacherService.reset();
  StarredBusService.reset();
  CalendarService.reset();
  NotificationService().stopListening();
  HiddenFishService.reset();
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

      if (kDebugMode)
        print(
          '[MAIN] Auth state change. User: ${user?.uid}, isFirst: $isFirst',
        );

      if (user == null) {
        _teardownUserServices();
      } else {
        if (isFirst) {
          if (kDebugMode) print('[MAIN] Starting boot for initial user...');

          await _bootUserServices(user);
          print('[MAIN] Boot complete: ${initWatch.elapsedMilliseconds}ms');
        } else {
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
                            if (!isReady)
                              return const Scaffold(
                                backgroundColor: Colors.black,
                              );

                            final user = snapshot.data;
                            // AppFeatureFlags.isBeta is populated for the
                            // currently signed-in user (see
                            // counselor_persona_service.dart) — there is no
                            // longer a bulk allowlist on the client to look
                            // arbitrary emails up against.
                            final isBeta = AppFeatureFlags.isBeta.value;

                            if (isLocked && user != null && !isBeta) {
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
                              ? const AdaptiveWebLandingScreen()
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
