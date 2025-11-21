import 'package:flutter/material.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/helper_functions.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const CustomHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: context.text.displayLarge?.copyWith(
            fontSize: 40,
            height: 1.0,
            letterSpacing: getLetterSpacing(40, 25),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4), // tighter
        Text(
          subtitle,
          style: context.text.displaySmall?.copyWith(
            fontSize: 14,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
