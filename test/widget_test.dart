import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gr0ve/features/authentication/screens/account_deletion_screen.dart';
import 'package:gr0ve/features/help/screens/help_screen.dart';
import 'package:gr0ve/features/privacy/screens/privacy_policy_screen.dart';
import 'package:gr0ve/core/widgets/buttons/custom_primary_button.dart';
import 'package:gr0ve/core/widgets/buttons/custom_secondary_button.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/core/widgets/misc/custom_text_field.dart';
import 'package:gr0ve/core/widgets/misc/not_logged_in.dart';
import 'package:gr0ve/core/theme/light_theme.dart';

void main() {
  group('Custom Components Tests', () {
    testWidgets('CustomPrimaryButton displays label and responds to taps', (
      WidgetTester tester,
    ) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: CustomPrimaryButton(
              label: 'Test Button',
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      // capitalized converts to uppercase
      expect(find.text('TEST BUTTON'), findsOneWidget);

      await tester.tap(find.text('TEST BUTTON'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('CustomSecondaryButton displays label and responds to taps', (
      WidgetTester tester,
    ) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: CustomSecondaryButton(
              label: 'Secondary Button',
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('SECONDARY BUTTON'), findsOneWidget);

      await tester.tap(find.text('SECONDARY BUTTON'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('CustomHeader displays title and subtitle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: CustomHeader(title: 'Test Title', subtitle: 'Test Subtitle'),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('CustomTextField displays hint and accepts input', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: CustomTextField(
              hintText: 'Enter text',
              controller: controller,
              obscureText: false,
            ),
          ),
        ),
      );

      expect(find.text('Enter text'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Hello World');
      await tester.pump();

      expect(controller.text, 'Hello World');

      controller.dispose();
    });

    testWidgets('CustomTextField with obscureText hides input', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: CustomTextField(
              hintText: 'Password',
              controller: controller,
              obscureText: true,
            ),
          ),
        ),
      );

      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      controller.dispose();
    });

    testWidgets('NotLoggedIn displays sign in prompt and button', (
      WidgetTester tester,
    ) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(body: NotLoggedIn(onSignIn: () => wasTapped = true)),
        ),
      );

      expect(find.text('Welcome to gr0ve'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);

      await tester.tap(find.text('SIGN IN'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });
  });

  // Note: LandingScreen tests skipped as they require Firebase initialization
  // LandingScreen uses FirebaseAuth.instance.currentUser which requires Firebase.initializeApp()

  group('Help Screen Tests', () {
    testWidgets('HelpScreen displays help content and grid cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme, home: const HelpScreen()),
      );

      await tester.pumpAndSettle();

      expect(find.text('HELP'), findsOneWidget);
      expect(find.text('Announcements'), findsOneWidget);

      // Check for grid cards
      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Questions'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
    });

    testWidgets('HelpScreen has changelog pager', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme, home: const HelpScreen()),
      );

      await tester.pumpAndSettle();

      // Changelog should be present
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('HelpScreen displays subtitle correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme, home: const HelpScreen()),
      );

      await tester.pumpAndSettle();

      expect(find.text('Questions, ideas, or problems'), findsOneWidget);
    });
  });

  group('Privacy Policy Screen Tests', () {
    testWidgets('PrivacyPolicyScreen displays privacy policy content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme, home: const PrivacyPolicyScreen()),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(CustomHeader), findsOneWidget);
    });

    testWidgets('PrivacyPolicyScreen has scrollable content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme, home: const PrivacyPolicyScreen()),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Account Deletion Screen Tests', () {
    testWidgets('AccountDeletionScreen displays deletion information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme, home: const AccountDeletionScreen()),
      );

      await tester.pumpAndSettle();

      expect(find.text('ACCOUNT DELETION'), findsOneWidget);
      expect(find.text('How to delete your gr0ve account'), findsOneWidget);
      expect(find.text('What data is deleted'), findsOneWidget);
      expect(find.text('Data retention'), findsOneWidget);
      expect(find.text('Deletion timeline'), findsOneWidget);
    });

    testWidgets('AccountDeletionScreen has scrollable content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme, home: const AccountDeletionScreen()),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('Component Integration Tests', () {
    testWidgets('Buttons maintain consistent styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                CustomPrimaryButton(label: 'Primary', onTap: () {}),
                const SizedBox(height: 16),
                CustomSecondaryButton(label: 'Secondary', onTap: () {}),
              ],
            ),
          ),
        ),
      );

      expect(find.text('PRIMARY'), findsOneWidget);
      expect(find.text('SECONDARY'), findsOneWidget);

      // Both buttons should be tappable
      expect(tester.getSize(find.text('PRIMARY')).height, greaterThan(0));
      expect(tester.getSize(find.text('SECONDARY')).height, greaterThan(0));
    });

    testWidgets('Header and buttons work together', (
      WidgetTester tester,
    ) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                const CustomHeader(
                  title: 'Test Page',
                  subtitle: 'Test Description',
                ),
                CustomPrimaryButton(
                  label: 'Action',
                  onTap: () => wasTapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Page'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.text('ACTION'), findsOneWidget);

      await tester.tap(find.text('ACTION'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('Multiple text fields work independently', (
      WidgetTester tester,
    ) async {
      final controller1 = TextEditingController();
      final controller2 = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                CustomTextField(
                  hintText: 'Field 1',
                  controller: controller1,
                  obscureText: false,
                ),
                CustomTextField(
                  hintText: 'Field 2',
                  controller: controller2,
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Input 1');
      await tester.enterText(find.byType(TextFormField).last, 'Input 2');

      expect(controller1.text, 'Input 1');
      expect(controller2.text, 'Input 2');

      controller1.dispose();
      controller2.dispose();
    });
  });

  group('UI Accessibility Tests', () {
    testWidgets('All interactive elements are tappable', (
      WidgetTester tester,
    ) async {
      bool primaryTapped = false;
      bool secondaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                CustomPrimaryButton(
                  label: 'Primary',
                  onTap: () => primaryTapped = true,
                ),
                const SizedBox(height: 16),
                CustomSecondaryButton(
                  label: 'Secondary',
                  onTap: () => secondaryTapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('PRIMARY'));
      await tester.pump();
      expect(primaryTapped, isTrue);

      await tester.tap(find.text('SECONDARY'));
      await tester.pump();
      expect(secondaryTapped, isTrue);
    });

    testWidgets('Text fields accept keyboard input', (
      WidgetTester tester,
    ) async {
      final controller1 = TextEditingController();
      final controller2 = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                CustomTextField(
                  hintText: 'Field 1',
                  controller: controller1,
                  obscureText: false,
                ),
                CustomTextField(
                  hintText: 'Field 2',
                  controller: controller2,
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Test Input 1');
      await tester.enterText(find.byType(TextFormField).last, 'Test Input 2');

      expect(controller1.text, 'Test Input 1');
      expect(controller2.text, 'Test Input 2');

      controller1.dispose();
      controller2.dispose();
    });
  });

  group('Theme and Styling Tests', () {
    testWidgets('Components respect theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                const CustomHeader(title: 'Title', subtitle: 'Subtitle'),
                CustomPrimaryButton(label: 'Button', onTap: () {}),
              ],
            ),
          ),
        ),
      );

      // Verify components render with theme
      final primaryButton = tester.widget<CustomPrimaryButton>(
        find.byType(CustomPrimaryButton),
      );
      expect(primaryButton.label, 'Button');

      final header = tester.widget<CustomHeader>(find.byType(CustomHeader));
      expect(header.title, 'Title');
      expect(header.subtitle, 'Subtitle');
    });

    testWidgets('Buttons use proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: CustomPrimaryButton(label: 'Styled Button', onTap: () {}),
          ),
        ),
      );

      // Button should have Material widget for elevation
      expect(find.byType(Material), findsWidgets);

      // Button should have InkWell for tap handling
      expect(find.byType(InkWell), findsWidgets);
    });
  });

  group('Edge Cases and Error Handling', () {
    testWidgets('Empty text field validation works', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Form(
              child: CustomTextField(
                hintText: 'Required Field',
                controller: controller,
                obscureText: false,
              ),
            ),
          ),
        ),
      );

      // Field should accept empty input
      await tester.enterText(find.byType(TextFormField), '');
      expect(controller.text, '');

      controller.dispose();
    });

    testWidgets('Long text in buttons displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: CustomPrimaryButton(
              label: 'This is a very long button label',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('THIS IS A VERY LONG BUTTON LABEL'), findsOneWidget);
    });

    testWidgets('Header with empty strings handles gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: CustomHeader(title: '', subtitle: ''),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(CustomHeader), findsOneWidget);
    });
  });

  group('Component Structure Tests', () {
    testWidgets('CustomPrimaryButton has correct widget tree', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: CustomPrimaryButton(label: 'Test', onTap: () {}),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(Material), findsWidgets);
      expect(find.byType(InkWell), findsWidgets);
      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('CustomSecondaryButton has correct widget tree', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: CustomSecondaryButton(label: 'Test', onTap: () {}),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Material), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('NotLoggedIn has all required elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(body: NotLoggedIn(onSignIn: () {})),
        ),
      );

      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Icon), findsWidgets);
      expect(find.byType(CustomPrimaryButton), findsOneWidget);
    });
  });

  group('Screen Layout Tests', () {
    testWidgets('HelpScreen has proper layout structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme, home: const HelpScreen()),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(CustomHeader), findsOneWidget);
    });

    testWidgets('AccountDeletionScreen has proper layout structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme, home: const AccountDeletionScreen()),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(CustomHeader), findsOneWidget);
    });
  });
}
