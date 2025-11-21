import 'package:flutter/material.dart';
import 'package:gr0ve/utilities/context_extensions.dart';

class CustomPrimaryButton extends StatelessWidget {
  final String label;
  final GestureTapCallback onTap;

  const CustomPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.text;

    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(
            label.capitalized,
            style: textStyles.labelLarge?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
