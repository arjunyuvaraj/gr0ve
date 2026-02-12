import 'package:flutter/material.dart';
import 'package:gr0ve/core/widgets/buttons/custom_primary_button.dart';

class NotLoggedIn extends StatelessWidget {
  final VoidCallback onSignIn;

  const NotLoggedIn({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                size: 80,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Welcome to gr0ve",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Sign in to access your favorite links and personalize your experience",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: CustomPrimaryButton(label: "Sign In", onTap: onSignIn),
            ),
          ],
        ),
      ),
    );
  }
}
