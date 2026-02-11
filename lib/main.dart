import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gr0ve/features/authentication/account_deletion_screen.dart';
import 'package:gr0ve/features/admin/admin_panel_screen.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/features/absence/absence_screen.dart';
import 'package:gr0ve/features/home/home_screen.dart';
import 'package:gr0ve/pages/join_requests_screen.dart';
import 'package:gr0ve/landing/landing_screen.dart';
import 'package:gr0ve/landing/landing_screen_web.dart';
import 'package:gr0ve/features/authentication/login_screen.dart';
import 'package:gr0ve/features/lunch_menu/lunch_menu_screen.dart';
import 'package:gr0ve/features/authentication/register_screen.dart';
import 'package:gr0ve/features/navigation/navigation_screen.dart';
import 'package:gr0ve/features/privacy/privacy_policy_screen.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:gr0ve/features/absence/teacher_service.dart';
import 'package:gr0ve/core/theme/dark_theme.dart';
import 'package:gr0ve/core/theme/light_theme.dart';
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
      } else if (payload.startsWith('announcement:')) {
        // Announcement notification - navigate to clubs screen
        // final groupId = payload.substring('announcement:'.length);
        print('[MAIN] Navigating to home/clubs');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const NavigationScreen(initialIndex: 0),
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
    return MaterialApp(
      title: 'Gr0ve',
      navigatorKey: navigatorKey, // Set the global navigator key
      darkTheme: darkTheme,
      theme: lightTheme,
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
        '/account_deletion': (context) => const AccountDeletionInfoScreen(),
        '/lunch_menu': (context) => const LunchMenuScreen(),
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
  }
}
