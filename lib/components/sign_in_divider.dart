import 'package:flutter/material.dart';

class SignInDivider extends StatelessWidget {
  final String text;

  const SignInDivider({super.key, this.text = "or sign in with"});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withAlpha(80);

    return Row(
      children: [
        Expanded(child: Divider(thickness: 1, color: color)),
        const SizedBox(width: 12),
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(thickness: 1, color: color)),
      ],
    );
  }
}
