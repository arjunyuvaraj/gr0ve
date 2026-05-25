import 'package:flutter/material.dart';
import 'package:gr0ve/core/theme/persona_theme.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_shared.dart';
import 'package:gr0ve/features/calendar/services/calendar_service.dart';

Color _urgC(CalendarEvent r, ColorScheme c) {
  final d = r.date.difference(DateTime.now()).inDays;
  return d <= 0
      ? const Color(0xFFF87171)
      : d <= 3
      ? const Color(0xFFFBBF24)
      : c.success;
}

String _dayL(CalendarEvent r) {
  final now = DateTime.now();
  final target = DateTime(r.date.year, r.date.month, r.date.day);
  final today = DateTime(now.year, now.month, now.day);
  final d = target.difference(today).inDays;
  return d == 0
      ? 'Today'
      : d == 1
      ? 'Tmrw'
      : d < 7
      ? '${d}d'
      : '${r.date.month}/${r.date.day}';
}

IconData _tIcon(String? t) => switch (t) {
  'test' => Icons.quiz_outlined,
  'quiz' => Icons.help_outline_rounded,
  'hw' => Icons.assignment_outlined,
  'project' => Icons.folder_outlined,
  _ => Icons.event_outlined,
};

class SnapshotUpcomingCard extends StatefulWidget {
  final bool compact;
  const SnapshotUpcomingCard({super.key, this.compact = false});

  @override
  State<SnapshotUpcomingCard> createState() => _SnapshotUpcomingCardState();
}

class _SnapshotUpcomingCardState extends State<SnapshotUpcomingCard> {
  @override
  Widget build(BuildContext ctx) {
    final c = Theme.of(ctx).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        StreamBuilder<List<CalendarEvent>>(
          stream: CalendarService.upcomingEventsStream(days: 7, limit: 5),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return SnapshotTile(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.success,
                    ),
                  ),
                ),
              );
            }

            final items = snap.data ?? [];

            if (items.isEmpty) {
              return SnapshotTile(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Text(
                  'No upcoming events or deadlines.',
                  style: TextStyle(
                    fontSize: 13,
                    color: c.onSurface.withOpacity(0.4),
                  ),
                ),
              );
            }

            return Column(
              children: items.map((r) {
                final col = _urgC(r, c);
                final isPersonal = r.category == 'personal';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: isPersonal
                      ? Dismissible(
                          key: ValueKey(r.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          onDismissed: (_) =>
                              CalendarService.deletePersonalEvent(r.id),
                          child: _buildEventTile(r, col, c),
                        )
                      : _buildEventTile(r, col, c),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventTile(CalendarEvent r, Color col, ColorScheme c) {
    return SnapshotTile(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: widget.compact ? 10 : 14,
      ),
      child: Row(
        children: [
          Icon(
            _tIcon(r.category == 'personal' ? r.personalCategory : r.category),
            size: 18,
            color: col.withOpacity(0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.compact ? 13.0 : 16.0,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                  ),
                ),
                if (!widget.compact &&
                    (r.description != null && r.description!.isNotEmpty))
                  Text(
                    r.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.onSurface.withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: SnapshotPill(_dayL(r), col),
          ),
        ],
      ),
    );
  }
}
