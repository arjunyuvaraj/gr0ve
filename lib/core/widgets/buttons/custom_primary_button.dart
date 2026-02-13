import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';

class CustomPrimaryButton extends StatelessWidget {
  final String label;
  final GestureTapCallback onTap;
  final bool fullWidth;

  const CustomPrimaryButton({
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
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: colors.primary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                label.capitalized,
                style: textStyles.labelLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
