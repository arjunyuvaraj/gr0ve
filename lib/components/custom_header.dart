import 'package:flutter/material.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/helper_functions.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const CustomHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Main Title
        Text(
          title,
          style: context.text.displayLarge?.copyWith(
            fontSize: 36,
            height: 1.1,
            letterSpacing: getLetterSpacing(36, 24),
            fontWeight: FontWeight.w800,
            color: colors.primary, // accent color for the title
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6), // slightly more breathing room
        // Subtitle
        Text(
          subtitle,
          style: context.text.displaySmall?.copyWith(
            fontSize: 15,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
            color: colors.onSurface.withAlpha(160), // subtle muted tone
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16), // separates header from content
      ],
    );
  }
}
