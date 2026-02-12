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

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(14),
      shadowColor: colors.onSurface.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: colors.surface,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (event.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        style: TextStyle(
                          color: colors.onSurface.withOpacity(0.65),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (!event.isAllDay && event.startTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(event.startTime!),
                        style: TextStyle(
                          color: colors.onSurface.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isBCA)
                Icon(
                  Icons.chevron_right,
                  color: colors.onSurface.withOpacity(0.3),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPersonalCategoryColor(BuildContext context) {
    final colors = context.colors;
    switch (event.personalCategory) {
      case 'test':
        return Colors.red;
      case 'quiz':
        return Colors.orange;
      case 'homework':
        return Colors.blue;
      case 'project':
        return Colors.purple;
      case 'social':
        return Colors.green;
      default:
        return colors.secondary;
    }
  }

  IconData _getPersonalCategoryIcon() {
    switch (event.personalCategory) {
      case 'test':
        return Icons.assignment;
      case 'quiz':
        return Icons.quiz;
      case 'homework':
        return Icons.book;
      case 'project':
        return Icons.work;
      case 'social':
        return Icons.people;
      default:
        return Icons.event;
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
