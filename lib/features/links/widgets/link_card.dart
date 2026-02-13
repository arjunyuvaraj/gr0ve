import 'package:flutter/material.dart';
import 'package:gr0ve/features/links/link_service.dart';

class LinkCard extends StatelessWidget {
  final QuickLink link;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onEdit;
  final bool isReordering;

  const LinkCard({
    super.key,
    required this.link,
    required this.onTap,
    required this.onRemove,
    this.onEdit,
    this.isReordering = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: isReordering
            ? Border.all(color: colors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: isReordering ? null : onTap,
        child: Row(
          children: [
            // Drag handle when reordering
            if (isReordering)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.drag_handle,
                  color: colors.onSurface.withOpacity(0.5),
                  size: 20,
                ),
              ),

            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: link.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                link.icon,
                color: link.color,
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // Title
            Expanded(
              child: Text(
                link.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.1,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),

            // Edit button
            if (!isReordering && onEdit != null)
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: colors.onSurface.withOpacity(0.4),
                ),
                onPressed: onEdit,
                tooltip: 'Edit link',
              ),

            // Remove button
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: colors.onSurface.withOpacity(0.4),
              ),
              onPressed: onRemove,
              tooltip: 'Remove link',
            ),
          ],
        ),
      ),
    );
  }
}
