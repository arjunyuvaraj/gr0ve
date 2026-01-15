import 'package:flutter/material.dart';
import 'package:gr0ve/services/calendar_service.dart';

class EventDetailsDialog extends StatelessWidget {
  final CalendarEvent event;

  const EventDetailsDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isBCA = event.category == 'bca';
    const primaryGreen = Color(0xFF2D6A4F);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildInfoRow(Icons.calendar_today, _formatDate(event.date)),

            if (!event.isAllDay && event.startTime != null)
              _buildInfoRow(
                Icons.access_time,
                '${_formatTime(event.startTime!)}${event.endTime != null ? ' - ${_formatTime(event.endTime!)}' : ''}',
              ),

            _buildInfoRow(
              Icons.category,
              isBCA ? 'BCA Event' : _getCategoryLabel(event.personalCategory),
            ),

            if (event.description != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(event.description!, style: const TextStyle(fontSize: 15)),
            ],

            if (!isBCA) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      CalendarService.deletePersonalEvent(event.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Event deleted')),
                      );
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'test':
        return 'Test';
      case 'quiz':
        return 'Quiz';
      case 'homework':
        return 'Homework';
      case 'project':
        return 'Project';
      case 'social':
        return 'Social';
      default:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
