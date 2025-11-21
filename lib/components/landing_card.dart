import 'package:flutter/material.dart';
import 'package:gr0ve/utilities/context_extensions.dart';

class LandingCard extends StatelessWidget {
  final String title;
  final String body;

  const LandingCard({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title.capitalized, style: context.text.headlineSmall),
        Text(
          body,
          style: context.text.bodyMedium,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
