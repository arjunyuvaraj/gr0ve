import 'package:flutter/material.dart';
import 'package:gr0ve/core/utilities/extensions/context_extensions.dart';
import 'package:gr0ve/core/utilities/helper/helper_functions.dart';
import 'package:gr0ve/core/utilities/extensions/string_extensions.dart';

class LandingCard extends StatelessWidget {
  final String title;
  final String body;
  final Color shadowColor;

  const LandingCard({
    super.key,
    required this.title,
    required this.body,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.capitalized,
            style: textStyles.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              letterSpacing: getLetterSpacing(12, 10),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: textStyles.bodyMedium?.copyWith(
              color: colors.onSurface.withAlpha(200),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
