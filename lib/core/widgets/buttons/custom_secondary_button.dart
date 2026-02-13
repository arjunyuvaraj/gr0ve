import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';

class CustomSecondaryButton extends StatelessWidget {
  final String label;
  final GestureTapCallback onTap;
  final bool fullWidth;

  const CustomSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.text;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(0.2), width: 1.5),
      ),
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: Text(
              label.capitalized,
              style: textStyles.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
