import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';

class CustomContactCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDestructive;

  const CustomContactCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final bgColor = isDestructive ? colors.error.withAlpha(30) : colors.surface;

    final textColor = isDestructive ? colors.error : colors.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.onSurface.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 26, color: textColor.withAlpha(220)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: context.text.bodyMedium?.copyWith(
                        color: textColor.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textColor.withAlpha(160),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
