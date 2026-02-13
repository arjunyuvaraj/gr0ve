import 'package:flutter/material.dart';
import 'package:gr0ve/features/calendar/services/calendar_service.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';

class CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;

  const CalendarEventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isBCA = event.category == 'bca';

    Color categoryColor = isBCA
        ? colors.primary
        : _getPersonalCategoryColor(context);
    IconData categoryIcon = isBCA ? Icons.school : _getPersonalCategoryIcon();

    return Container(
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
      ),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getRoundedIcon(categoryIcon),
                color: categoryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description!,
                      style: TextStyle(
                        color: colors.onSurface.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (!event.isAllDay && event.startTime != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(event.startTime!),
                      style: TextStyle(
                        color: colors.onSurface.withOpacity(0.4),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isBCA)
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurface.withOpacity(0.3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getRoundedIcon(IconData icon) {
    if (icon == Icons.school) return Icons.school_rounded;
    if (icon == Icons.assignment) return Icons.assignment_rounded;
    if (icon == Icons.quiz) return Icons.quiz_rounded;
    if (icon == Icons.book) return Icons.book_rounded;
    if (icon == Icons.work) return Icons.work_rounded;
    if (icon == Icons.people) return Icons.people_rounded;
    return Icons.event_available_rounded;
  }

  Color _getPersonalCategoryColor(BuildContext context) {
    return context.colors.onSurface.withOpacity(0.4);
  }

  IconData _getPersonalCategoryIcon() {
    switch (event.personalCategory) {
      case 'test':
        return Icons.assignment_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'homework':
        return Icons.book_rounded;
      case 'project':
        return Icons.work_rounded;
      case 'social':
        return Icons.people_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
