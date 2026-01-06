import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/utilities/context_extensions.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              Text("More coming soon", style: context.text.headlineSmall),
              Text(
                "Sign in for features like starring teachers!",
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 6),
              CustomPrimaryButton(
                label: "Back to landing page".capitalized,
                onTap: () => Navigator.pushNamed(context, "/landing"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
