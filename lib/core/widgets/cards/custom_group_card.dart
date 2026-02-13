import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';

class CustomGroupCard extends StatelessWidget {
  final String name;
  final String description;
  final VoidCallback onTap;

  const CustomGroupCard({
    super.key,
    required this.name,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.groups_rounded,
                color: colors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.5),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colors.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
