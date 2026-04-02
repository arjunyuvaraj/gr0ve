import 'package:flutter/material.dart';
import 'package:gr0ve/features/calendar/services/calendar_service.dart';
import 'dart:ui';
import 'dart:math';

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

    // 1. Check weekends
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return true;
    }

    // 2. Check "School Closed" or "Holiday" in events
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

  @override
  Widget build(BuildContext context) {
    if (_sessionDismissed || _dismissed || !_isSchoolClosed()) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        widget.child,
        // Full screen blur + overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: colors.surface.withOpacity(0.85),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Sarcastic image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          isDark
                              ? 'assets/app_icons/png/dawn_dark.png'
                              : 'assets/app_icons/png/dawn_light.png',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 200,
                                color: colors.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.wb_sunny_rounded,
                                  size: 64,
                                  color: colors.primary,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Message
                      Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "There are zero academic reasons for you to be opening this app right now. Go live your life.",
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _dismissed = true;
                              _sessionDismissed = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Continue to gr0ve",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
