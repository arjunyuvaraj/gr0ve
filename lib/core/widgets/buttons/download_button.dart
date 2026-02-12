import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/helper/helper_functions.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';

class DownloadButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const DownloadButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Material(
      color: colors.surface.withOpacity(0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                label.capitalized,
                style: text.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: getLetterSpacing(12, 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
