import 'package:dotenv/dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'package:gr0ve/features/privacy/screens/privacy_policy_screen.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:gr0ve/features/absence/services/teacher_service.dart';
import 'package:gr0ve/core/helper/landing_decider.dart';
import 'package:flutter/foundation.dart';
import 'package:gr0ve/core/helper/teacher_utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'configuration/firebase_options.dart';

// Global navigator key for handling notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load teacher list from Firestore
  try {
    teacherList = await fetchTeacherListFromFirebase();
  } catch (e) {
    if (kDebugMode) {
      print('Error loading teachers: $e');
    }
    teacherList = {};
  }
  absenceList = {};

  // Initialize notification service
  await NotificationService().initialize();
  await CounselorPersonaService.init();
  DotEnv().load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // User logged in - start listening for notifications
        NotificationService().startListening();
      } else {
        // User logged out - stop listening
        NotificationService().stopListening();
      }
    });

    // Set up notification tap handler
    _setupNotificationTapHandler();
  }

  void _setupNotificationTapHandler() {
    // Set the notification tap callback in the NotificationService
    NotificationService().setNotificationTapCallback(_handleNotificationTap);
  }

  void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) {
      print('[MAIN] Notification tapped with no payload');
      return;
    }

    print('[MAIN] Notification tapped with payload: $payload');

    // Wait a bit to ensure navigation is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      final context = navigatorKey.currentContext;
      if (context == null) {
        print('[MAIN] No navigation context available');
        return;
      }

      // Parse payload and navigate
      if (payload.startsWith('bus:')) {
        // Bus notification - navigate to bus screen (index 2 for @bergen.org users)
        print('[MAIN] Navigating to bus screen');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const NavigationScreen(initialIndex: 2),
          ),
          (route) => false,
        );
      } else if (payload.startsWith('qa_reply:') ||
          payload.startsWith('qa_question:')) {
        // Q&A Notification: qa_reply:$groupId:$announcementId:$questionId
        final parts = payload.split(':');
        if (parts.length >= 4) {
          final groupId = parts[1];
          final announcementId = parts[2];
          final questionId = parts[3];

          print('[MAIN] Navigating to Q&A: $groupId -> $announcementId');
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
        // Announcement notification - navigate to club detail
        final groupId = payload.substring('announcement:'.length);
        print('[MAIN] Navigating to Club: $groupId');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ClubDetailScreen(groupId: groupId),
          ),
          (route) => false,
        );
      } else if (payload.startsWith('join_request:')) {
        // Join request - navigate to join requests screen
        final groupId = payload.substring('join_request:'.length);
        print('[MAIN] Navigating to join requests for group: $groupId');
        Navigator.of(
          context,
        ).pushNamed('/club/join-requests', arguments: groupId);
      } else if (payload.startsWith('club_request:')) {
        // Club creation request - navigate to admin panel
        print('[MAIN] Navigating to admin panel');
        Navigator.of(context).pushNamed('/admin');
      } else {
        print('[MAIN] Unknown payload type: $payload');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CounselorPersona>(
      valueListenable: CounselorPersonaService.activePersona,
      builder: (context, persona, _) {
        return MaterialApp(
          title: 'Gr0ve',
          navigatorKey: navigatorKey, // Set the global navigator key
          theme: PersonaTheme.light(persona),
          darkTheme: PersonaTheme.dark(persona),
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) => LandingDecider(
              landingPage: kIsWeb
                  ? const LandingWebsiteScreen()
                  : const LandingScreen(),
              loginPage: const LoginScreen(),
              navigationRoute: '/navigation',
            ),
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
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/club/join-requests') {
              final groupId = settings.arguments as String;

              return MaterialPageRoute(
                builder: (context) => JoinRequestsScreen(groupId: groupId),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
