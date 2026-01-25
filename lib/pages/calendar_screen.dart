import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/components/add_event_dialog.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/components/calendar_event_card.dart';
import 'package:gr0ve/components/event_details_dialog.dart';
import 'package:gr0ve/services/calendar_service.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool isLoading = true;
  Timer? _refreshTimer;

  // Add listeners to trigger rebuilds
  void _onEventsChanged() {
    if (mounted) {
      setState(() {
        // Force rebuild when events change
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeScreen();

    // Add listeners to all event notifiers
    CalendarService.bcaEvents.addListener(_onEventsChanged);
    CalendarService.personalEvents.addListener(_onEventsChanged);
    CalendarService.clubEvents.addListener(_onEventsChanged);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();

    // Remove listeners
    CalendarService.bcaEvents.removeListener(_onEventsChanged);
    CalendarService.personalEvents.removeListener(_onEventsChanged);
    CalendarService.clubEvents.removeListener(_onEventsChanged);

    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await CalendarService.loadAllEvents();
    if (mounted) {
      setState(() => isLoading = false);

      // Debug output to verify all events are loaded
      if (kDebugMode) {
        print('=== Calendar Events Summary ===');
        print('BCA Events: ${CalendarService.bcaEvents.value.length}');
        print(
          'Personal Events: ${CalendarService.personalEvents.value.length}',
        );
        print('Club Events: ${CalendarService.clubEvents.value.length}');
        print(
          'Total: ${CalendarService.bcaEvents.value.length + CalendarService.personalEvents.value.length + CalendarService.clubEvents.value.length}',
        );
      }
    }
    _scheduleNextRefresh();
  }

  void _scheduleNextRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => CalendarService.fetchBCAEvents(),
    );
  }

  void _showAddEventDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your email to add events')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) =>
          AddEventDialog(selectedDate: _selectedDay ?? _focusedDay),
    ).then((_) {
      // Refresh after dialog closes
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => EventDetailsDialog(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          CustomHeader(
            title: "Calendar".capitalized,
            subtitle: "BCA Events & Personal Schedule",
          ),
          const SizedBox(height: 12),

          // Calendar Widget - Simplified ValueListenableBuilder structure
          ValueListenableBuilder<List<CalendarEvent>>(
            valueListenable: CalendarService.bcaEvents,
            builder: (context, _, __) {
              return ValueListenableBuilder<List<CalendarEvent>>(
                valueListenable: CalendarService.personalEvents,
                builder: (context, __, ___) {
                  return ValueListenableBuilder<List<CalendarEvent>>(
                    valueListenable: CalendarService.clubEvents,
                    builder: (context, ___, ____) {
                      // Use a unique key to force calendar rebuild
                      return Container(
                        key: ValueKey(
                          'calendar_${CalendarService.bcaEvents.value.length}_${CalendarService.personalEvents.value.length}_${CalendarService.clubEvents.value.length}',
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colors.onSurface.withOpacity(0.08),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.surface.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colors.onSurface.withOpacity(0.06),
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: TableCalendar<CalendarEvent>(
                                firstDay: DateTime(2024, 1, 1),
                                lastDay: DateTime(2027, 12, 31),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) =>
                                    isSameDay(_selectedDay, day),
                                calendarFormat: CalendarFormat.month,
                                eventLoader: CalendarService.getEventsForDate,
                                startingDayOfWeek: StartingDayOfWeek.sunday,
                                daysOfWeekHeight: 32,
                                rowHeight: 44,
                                calendarStyle: CalendarStyle(
                                  cellMargin: const EdgeInsets.all(3),
                                  selectedDecoration: BoxDecoration(
                                    color: colors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  markerSize: 5,
                                  markerMargin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  markersMaxCount: 1,
                                  markersAnchor: 1.75,
                                  markerDecoration: BoxDecoration(
                                    color: colors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  outsideDaysVisible: false,
                                  defaultTextStyle: const TextStyle(
                                    fontSize: 14,
                                  ),
                                  weekendTextStyle: const TextStyle(
                                    fontSize: 14,
                                  ),
                                  selectedTextStyle: TextStyle(
                                    fontSize: 14,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  todayTextStyle: TextStyle(
                                    fontSize: 14,
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                headerStyle: HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  titleTextFormatter: (date, locale) {
                                    final months = [
                                      'JAN',
                                      'FEB',
                                      'MAR',
                                      'APR',
                                      'MAY',
                                      'JUN',
                                      'JUL',
                                      'AUG',
                                      'SEP',
                                      'OCT',
                                      'NOV',
                                      'DEC',
                                    ];
                                    return '${months[date.month - 1]}, ${date.year}';
                                  },
                                  titleTextStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                  leftChevronIcon: Icon(
                                    Icons.chevron_left,
                                    color: colors.onSurface,
                                    size: 24,
                                  ),
                                  rightChevronIcon: Icon(
                                    Icons.chevron_right,
                                    color: colors.onSurface,
                                    size: 24,
                                  ),
                                  headerPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                daysOfWeekStyle: DaysOfWeekStyle(
                                  weekdayStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface.withOpacity(0.6),
                                    letterSpacing: 0.5,
                                  ),
                                  weekendStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface.withOpacity(0.6),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  });
                                },
                                onPageChanged: (focusedDay) {
                                  setState(() {
                                    _focusedDay = focusedDay;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // Add Event Button
          if (user != null && user.emailVerified)
            ElevatedButton.icon(
              onPressed: _showAddEventDialog,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Personal Event'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Events List - Simplified ValueListenableBuilder structure
          Expanded(
            child: ValueListenableBuilder<List<CalendarEvent>>(
              valueListenable: CalendarService.bcaEvents,
              builder: (context, _, __) {
                return ValueListenableBuilder<List<CalendarEvent>>(
                  valueListenable: CalendarService.personalEvents,
                  builder: (context, __, ___) {
                    return ValueListenableBuilder<List<CalendarEvent>>(
                      valueListenable: CalendarService.clubEvents,
                      builder: (context, ___, ____) {
                        final selectedDate = _selectedDay ?? _focusedDay;
                        final events = CalendarService.getEventsForDate(
                          selectedDate,
                        );

                        if (events.isEmpty) {
                          return Center(
                            child: Text(
                              'No events for ${_formatDate(selectedDate)}',
                              style: TextStyle(
                                color: colors.onSurface.withOpacity(0.6),
                                fontSize: 15,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          key: ValueKey(
                            'events_list_${events.length}_${selectedDate.toIso8601String()}',
                          ),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CalendarEventCard(
                                event: event,
                                onTap: () => _showEventDetails(event),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
