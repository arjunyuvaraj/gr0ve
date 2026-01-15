import 'package:flutter/material.dart';
import 'package:gr0ve/services/link_service.dart';

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isReordering ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: isReordering
                ? Border.all(color: link.color.withOpacity(0.3), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: link.color.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      link.color.withOpacity(0.2),
                      link.color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(link.icon, color: link.color, size: 26),
              ),

              const SizedBox(width: 14),

              // Title
              Expanded(
                child: Text(
                  link.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),

              // Edit button (only show when not reordering and onEdit is provided)
              if (!isReordering && onEdit != null)
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color: colors.onSurface.withOpacity(0.5),
                  ),
                  onPressed: onEdit,
                  tooltip: 'Edit link',
                ),

              // Remove button
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: colors.onSurface.withOpacity(0.5),
                ),
                onPressed: onRemove,
                tooltip: 'Remove link',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
