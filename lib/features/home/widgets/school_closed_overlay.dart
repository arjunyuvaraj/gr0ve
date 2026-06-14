import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gr0ve/features/calendar/services/calendar_service.dart';

class SchoolClosedOverlay extends StatefulWidget {
  final Widget child;

  const SchoolClosedOverlay({super.key, required this.child});

  @override
  State<SchoolClosedOverlay> createState() => _SchoolClosedOverlayState();
}

class _SchoolClosedOverlayState extends State<SchoolClosedOverlay> {
  static bool _sessionDismissed = false;
  bool _dismissed = false;

  final List<String> _messages = [
    "School's closed... why are you here?",
    "Go touch some grass. School is out.",
    "It's a holiday! Shouldn't you be sleeping?",
    "Gr0ve is taking a nap. You should too.",
    "Access denied. Just kidding, but seriously, no school today.",
    "Error 404: School Not Found. Enjoy your day off!",
  ];

  late final String _message;

  @override
  void initState() {
    super.initState();
    _message = _messages[Random().nextInt(_messages.length)];
  }

  bool _isSchoolClosed() {
    final now = DateTime.now();

    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return true;
    }

    final todayEvents = CalendarService.getEventsForDate(now);
    for (final event in todayEvents) {
      final title = event.title.toLowerCase();
      if (title.contains('school closed') ||
          title.contains('holiday') ||
          title.contains('no school')) {
        return true;
      }
    }

    return false;
  }

  void _dismiss() {
    setState(() {
      _dismissed = true;
      _sessionDismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionDismissed || _dismissed || !_isSchoolClosed()) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            type: MaterialType.transparency,
            child: _SchoolClosedBanner(
              message: _message,
              onDismiss: _dismiss,
            ),
          ),
        ),
      ],
    );
  }
}

class _SchoolClosedBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _SchoolClosedBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Material(
            elevation: 10,
            shadowColor: Colors.black.withOpacity(0.16),
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.primary.withOpacity(0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.weekend_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "School looks closed today, but gr0ve is still available.",
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(0.62),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.onSurface.withOpacity(0.64),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
