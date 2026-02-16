import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/calendar/widgets/add_event_dialog.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/features/calendar/widgets/calendar_event_card.dart';
import 'package:gr0ve/features/calendar/widgets/event_details_dialog.dart';
import 'package:gr0ve/features/calendar/services/calendar_service.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isCalendarExpanded = false;
  Timer? _refreshTimer;
  late PageController _pageController;
  final int _initialPage = 10000;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _pageController = PageController(initialPage: _initialPage);
    _initializeScreen();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await CalendarService.loadAllEvents();
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
        const SnackBar(
          content: Text('Please verify your email to add events'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) =>
          AddEventDialog(selectedDate: _selectedDay ?? _focusedDay),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => EventDetailsDialog(event: event),
    );
  }

  DateTime _getDateForPage(int page) {
    final offset = page - _initialPage;
    return DateTime.now().add(Duration(days: offset));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colors = context.colors;

    return Column(
      children: [
        const CustomHeader(title: "CALENDAR"),
        const SizedBox(height: 16),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _selectedDay = _getDateForPage(page);
                _focusedDay = _selectedDay!;
              });
            },
            itemBuilder: (context, page) {
              final selectedDate = _getDateForPage(page);
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.outline.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getMonthAbbrev(selectedDate.month),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: colors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${selectedDate.day}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: colors.primary,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getWeekday(selectedDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ValueListenableBuilder<int>(
                                  valueListenable:
                                      CalendarService.eventsVersion,
                                  builder: (_, __, ___) {
                                    final events =
                                        CalendarService.getEventsForDate(
                                          selectedDate,
                                        );
                                    return Row(
                                      children: [
                                        Icon(
                                          Icons.event_rounded,
                                          size: 14,
                                          color: colors.onSurface.withOpacity(
                                            0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${events.length} event${events.length != 1 ? 's' : ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: colors.onSurface.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.swipe_rounded,
                                size: 16,
                                color: colors.primary.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_left_rounded,
                                size: 14,
                                color: colors.primary.withOpacity(0.3),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: colors.primary.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          if (user != null && user.emailVerified)
                            Expanded(
                              child: InkWell(
                                onTap: _showAddEventDialog,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colors.primary.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Add Event',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: colors.primary,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => setState(
                              () => _isCalendarExpanded = !_isCalendarExpanded,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.outline.withOpacity(0.1),
                                ),
                              ),
                              child: AnimatedRotation(
                                turns: _isCalendarExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: colors.primary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _isCalendarExpanded
                          ? Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colors.outline.withOpacity(0.1),
                                ),
                              ),
                              child: ValueListenableBuilder<int>(
                                valueListenable: CalendarService.eventsVersion,
                                builder: (context, version, _) {
                                  return TableCalendar<CalendarEvent>(
                                    firstDay: DateTime(2024, 1, 1),
                                    lastDay: DateTime(2027, 12, 31),
                                    focusedDay: _focusedDay,
                                    selectedDayPredicate: (day) =>
                                        isSameDay(_selectedDay, day),
                                    calendarFormat: CalendarFormat.month,
                                    eventLoader:
                                        CalendarService.getEventsForDate,
                                    startingDayOfWeek: StartingDayOfWeek.sunday,
                                    daysOfWeekHeight: 20,
                                    rowHeight: 36,
                                    calendarStyle: CalendarStyle(
                                      cellMargin: const EdgeInsets.all(2),
                                      selectedDecoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      todayDecoration: BoxDecoration(
                                        color: colors.primary.withOpacity(0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      markerSize: 4,
                                      markerMargin: const EdgeInsets.symmetric(
                                        horizontal: 0.5,
                                      ),
                                      markersMaxCount: 1,
                                      markersAnchor: 1.8,
                                      markerDecoration: BoxDecoration(
                                        color: colors.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                      outsideDaysVisible: false,
                                      defaultTextStyle: const TextStyle(
                                        fontSize: 12,
                                      ),
                                      weekendTextStyle: const TextStyle(
                                        fontSize: 12,
                                      ),
                                      selectedTextStyle: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      todayTextStyle: TextStyle(
                                        fontSize: 12,
                                        color: colors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    headerStyle: HeaderStyle(
                                      formatButtonVisible: false,
                                      titleCentered: true,
                                      titleTextFormatter: (date, locale) =>
                                          '${_getMonthFull(date.month)} ${date.year}',
                                      titleTextStyle: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: colors.onSurface,
                                        letterSpacing: 0.3,
                                      ),
                                      leftChevronIcon: Icon(
                                        Icons.chevron_left_rounded,
                                        color: colors.primary,
                                        size: 22,
                                      ),
                                      rightChevronIcon: Icon(
                                        Icons.chevron_right_rounded,
                                        color: colors.primary,
                                        size: 22,
                                      ),
                                      headerPadding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                    daysOfWeekStyle: DaysOfWeekStyle(
                                      weekdayStyle: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: colors.onSurface.withOpacity(
                                          0.5,
                                        ),
                                        letterSpacing: 0.3,
                                      ),
                                      weekendStyle: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: colors.onSurface.withOpacity(
                                          0.5,
                                        ),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    onDaySelected: (selectedDay, focusedDay) {
                                      setState(() {
                                        _selectedDay = selectedDay;
                                        _focusedDay = focusedDay;
                                        _isCalendarExpanded = false;
                                        _pageController.jumpToPage(
                                          _initialPage +
                                              selectedDay
                                                  .difference(DateTime.now())
                                                  .inDays,
                                        );
                                      });
                                    },
                                    onPageChanged: (focusedDay) => setState(
                                      () => _focusedDay = focusedDay,
                                    ),
                                  );
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (_isCalendarExpanded) const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ValueListenableBuilder<int>(
                        valueListenable: CalendarService.eventsVersion,
                        builder: (context, version, _) {
                          final events = CalendarService.getEventsForDate(
                            selectedDate,
                          );
                          if (events.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.event_busy_rounded,
                                      size: 40,
                                      color: colors.primary.withOpacity(0.4),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No events',
                                    style: TextStyle(
                                      color: colors.onSurface.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getFullDate(selectedDate),
                                    style: TextStyle(
                                      color: colors.onSurface.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: events
                                .map(
                                  (event) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: CalendarEventCard(
                                      event: event,
                                      onTap: () => _showEventDetails(event),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  String _getFullDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[date.weekday - 1]}, ${_getMonthFull(date.month)} ${date.day}';
  }

  String _getMonthAbbrev(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _getMonthFull(int month) {
    const months = [
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
    return months[month - 1];
  }
}
