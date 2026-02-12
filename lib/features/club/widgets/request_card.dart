import 'package:flutter/material.dart';
import 'package:gr0ve/models/group_creation_request.dart';

class RequestCard extends StatelessWidget {
  final GroupCreationRequest request;

  const RequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final color = request.isPending
        ? Colors.orange
        : request.isApproved
        ? Colors.green
        : Colors.red;

    final icon = request.isPending
        ? Icons.schedule
        : request.isApproved
        ? Icons.check_circle
        : Icons.cancel;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.groupName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.status.name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (request.rejectionReason != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      request.rejectionReason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
