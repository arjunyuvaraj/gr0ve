import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gsheets/gsheets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/services/calendar_service.dart';

@immutable
class BusRoute {
  final String code;
  final String town;
  final String status;

  const BusRoute({
    required this.code,
    required this.town,
    required this.status,
  });
}

const _spreadsheetId = '1S5v7kTbSiqV8GottWVi5tzpqLdTrEgWEY4ND4zvyV3o';
const _worksheetTitle = 'Locations';

late final GSheets _gsheets;
Future<void>? _initFuture;

Future<void> _initGSheets() {
  _initFuture ??= _loadGSheets();
  return _initFuture!;
}

Future<void> _loadGSheets() async {
  final json = await rootBundle.loadString('assets/credentials/gsheets.json');
  _gsheets = GSheets(json);
}

/// Check if today is a minimum day by looking at calendar events
Future<bool> _isMinimumDay() async {
  try {
    final today = DateTime.now();
    final todayEvents = CalendarService.getEventsForDate(today);

    // Check if any event title contains "minimum day" (case insensitive)
    return todayEvents.any(
      (event) =>
          event.title.toLowerCase().contains('minimum day') ||
          event.description?.toLowerCase().contains('minimum day') == true,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error checking minimum day: $e');
    }
    return false;
  }
}

/// Get the bus arrival time from Firestore override or calculate based on schedule
Future<DateTime> _getBusArrivalTime() async {
  try {
    // Check for Firestore override
    final doc = await FirebaseFirestore.instance
        .collection('config')
        .doc('bus_schedule')
        .get();

    if (doc.exists) {
      final overrideTime = doc.data()?['override_arrival_time'] as Timestamp?;
      if (overrideTime != null) {
        final overrideDate = overrideTime.toDate();
        final now = DateTime.now();

        // Combine today's date with the override time
        return DateTime(
          now.year,
          now.month,
          now.day,
          overrideDate.hour,
          overrideDate.minute,
        );
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error reading bus schedule override: $e');
    }
  }

  // No override - use default schedule
  final isMinDay = await _isMinimumDay();
  final now = DateTime.now();

  if (isMinDay) {
    // Minimum day: buses arrive at 12:30 PM
    return DateTime(now.year, now.month, now.day, 12, 30);
  } else {
    // Regular day: buses arrive at 3:45 PM
    return DateTime(now.year, now.month, now.day, 15, 45);
  }
}

/// Check if buses should be marked as arrived
Future<bool> areBusesArriving() async {
  final arrivalTime = await _getBusArrivalTime();
  final now = DateTime.now();
  return now.isAfter(arrivalTime);
}

Future<List<BusRoute>> fetchBusRoutes() async {
  await _initGSheets();
  final List<BusRoute> routes = [];

  // Check if buses are arriving yet
  final busesArriving = await areBusesArriving();

  try {
    final spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);
    final sheet = spreadsheet.worksheetByTitle(_worksheetTitle);
    if (sheet == null) return [];

    final rows = await sheet.values.allColumns();
    if (rows.length < 4) return [];

    final towns1 = rows[0].skip(1).toList();
    final codes1 = rows[1].skip(1).toList();
    final towns2 = rows[2].skip(1).toList();
    final codes2 = rows[3].skip(1).toList();

    final length = [
      towns1.length,
      codes1.length,
      towns2.length,
      codes2.length,
    ].reduce((a, b) => a < b ? a : b);

    for (int i = 0; i < length; i++) {
      _addRoute(routes, towns1[i], codes1[i], busesArriving);
      _addRoute(routes, towns2[i], codes2[i], busesArriving);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching bus routes: $e');
    }
  }

  return routes;
}

void _addRoute(
  List<BusRoute> routes,
  Object town,
  Object rawCode,
  bool busesArriving,
) {
  final code = rawCode.toString().trim();

  // If buses haven't started arriving, mark everything as missing
  if (!busesArriving) {
    routes.add(
      BusRoute(code: '?', town: town.toString(), status: 'Not here yet'),
    );
    return;
  }

  // Buses are arriving - use actual status
  final resolved = code.isEmpty ? '?' : code;

  routes.add(
    BusRoute(
      code: resolved,
      town: town.toString(),
      status: resolved == '?' ? 'Not here yet' : 'Arrived',
    ),
  );
}
