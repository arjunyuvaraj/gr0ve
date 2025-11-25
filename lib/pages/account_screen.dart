// IMPORTS
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/services/authentication_service.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/helper_functions.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({super.key});

  // USER: The currently signed-in Firebase user
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // THEME
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Widget userLoggedIn() {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: FutureBuilder<Map<String, dynamic>>(
            // FIRESTORE: Get the document reference for the current user
            future: AuthenticationService().getCurrentUserDocument(context),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docRef = snapshot.data!;

              return Padding(
                padding: EdgeInsetsGeometry.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // HEADER: Profile header with name and profile picture
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_rounded,
                        size: 52,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "WELCOME",
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (docRef['name'] ?? 'Unknown').toString().capitalized,
                      style: textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (docRef['email'] ?? 'unknown').toString().capitalized,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: getLetterSpacing(14, 10),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // FOOTER: All of the actions
                    const SizedBox(height: 12),
                    CustomPrimaryButton(
                      label: "Sign Out".capitalized,
                      onTap: () =>
                          AuthenticationService().signOutWithGoogle(context),
                    ),
                    const SizedBox(height: 8),
                    CustomPrimaryButton(
                      label: "Delete Account".capitalized,
                      onTap: () =>
                          AuthenticationService().deleteAccount(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    Widget userNotLoggedIn() {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ICON
                CircleAvatar(
                  radius: 42,
                  backgroundColor: context.colors.primaryContainer,
                  child: Icon(
                    Icons.person_off_rounded,
                    size: 52,
                    color: context.colors.onPrimaryContainer,
                  ),
                ),

                const SizedBox(height: 16),
                Text("You're Not Signed In", style: context.text.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  "Sign in for features like starring teachers!",
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 20),
                CustomPrimaryButton(
                  label: "Sign In".capitalized,
                  onTap: () =>
                      AuthenticationService().signInWithGoogle(context),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, "/navigation"),
                  child: Text("Continue without an account".capitalized),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return !(AuthenticationService().userLoggedIn())
        ? userLoggedIn()
        : userNotLoggedIn();
  }
}
