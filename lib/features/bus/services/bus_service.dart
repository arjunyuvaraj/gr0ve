import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';

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

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      code: json['code']?.toString() ?? '?',
      town: json['town']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Not here yet',
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'town': town, 'status': status};
  }
}

class SheetsConfig {
  static const String spreadsheetId =
      '1S5v7kTbSiqV8GottWVi5tzpqLdTrEgWEY4ND4zvyV3o';

  static const String gid = '0';

  static String get csvUrl =>
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/export?format=csv&gid=$gid';
}

List<BusRoute>? _cachedBusRoutes;
DateTime? _cachedBusRoutesAt;
String? busRoutesLastUpdated;
const _busRoutesCacheTtl = Duration(minutes: 5);

Future<void> refreshBusRoutesFromSheets() async {
  try {
    if (kDebugMode) {
      print('🔄 Fetching latest bus routes from Google Sheets...');
    }

    final url = Uri.parse(SheetsConfig.csvUrl);
    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch from Google Sheets: ${response.statusCode}\n'
        'Make sure the sheet is public (anyone with link can view)',
      );
    }

    final csvData = const CsvDecoder().convert(response.body);

    final List<BusRoute> routes = [];

    final int endRow = csvData.length.clamp(0, 24);

    for (int i = 1; i < endRow; i++) {
      final row = csvData[i];

      if (row.isEmpty) continue;

      if (row.length >= 2) {
        final town1 = row[0].toString().trim();
        if (town1.isNotEmpty) {
          String code1 = row[1].toString().trim();

          if (code1.toLowerCase() == 'missing') {
            code1 = "";
          }

          final status = code1.isNotEmpty ? 'Arrived' : 'Not here yet';
          routes.add(BusRoute(town: town1, code: code1, status: status));
        }
      }

      if (row.length >= 4) {
        final town2 = row[2].toString().trim();
        if (town2.isNotEmpty) {
          String code2 = row[3].toString().trim();

          if (code2.toLowerCase() == 'missing') {
            code2 = "";
          }

          final status = code2.isNotEmpty ? 'Arrived' : 'Not here yet';
          routes.add(BusRoute(town: town2, code: code2, status: status));
        }
      }
    }

    if (routes.isEmpty) {
      throw Exception('No valid routes found in Google Sheets');
    }

    final Map<String, dynamic> routesMap = {};
    for (final route in routes) {
      routesMap[route.town] = {
        'town': route.town,
        'code': route.code,
        'status': route.status,
      };
    }

    await FirebaseFirestore.instance
        .collection('public_data')
        .doc('bus_routes')
        .set({
          'routes': routesMap,
          'updated_at': DateTime.now().toIso8601String(),
        });
    invalidateBusRoutesCache();

    if (kDebugMode) {
      print('✓ Successfully updated Firestore with ${routes.length} routes');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error refreshing bus routes: $e');
    }
    rethrow;
  }
}

Future<void> watchBusRoutesForDismissal({
  int intervalSeconds = 30,
  int durationMinutes = 60,
  void Function(int syncCount, DateTime nextSync)? onSyncStart,
  void Function(int syncCount, Exception error)? onSyncError,
  void Function()? onComplete,
}) async {
  final endTime = DateTime.now().add(Duration(minutes: durationMinutes));
  int syncCount = 0;

  if (kDebugMode) {
    print('🚌 Dismissal watch mode started!');
    print(
      '   Syncing every ${intervalSeconds}s until ${endTime.toIso8601String()}',
    );
  }

  while (DateTime.now().isBefore(endTime)) {
    syncCount++;
    final remaining = endTime.difference(DateTime.now());
    final minutesLeft = remaining.inSeconds ~/ 60;

    if (kDebugMode) {
      print(
        '── Sync #$syncCount | ${DateTime.now().toIso8601String()} | ${minutesLeft}m remaining ──',
      );
    }

    try {
      await refreshBusRoutesFromSheets();
      if (kDebugMode) {
        print('   ✓ Sync #$syncCount completed');
      }
    } catch (e) {
      final error = Exception('Error on sync #$syncCount: $e');
      if (kDebugMode) {
        print('   ⚠ ${error.toString()} — will retry next cycle');
      }
      onSyncError?.call(syncCount, error);
    }

    final nextRun = DateTime.now().add(Duration(seconds: intervalSeconds));
    if (nextRun.isBefore(endTime)) {
      onSyncStart?.call(syncCount, nextRun);
      if (kDebugMode) {
        print('   Next sync at ${nextRun.toIso8601String()}\n');
      }
      await Future.delayed(Duration(seconds: intervalSeconds));
    }
  }

  if (kDebugMode) {
    print('✓ Dismissal watch mode complete after $syncCount syncs!');
  }

  onComplete?.call();
}

Future<List<BusRoute>> fetchBusRoutes() async {
  final cachedAt = _cachedBusRoutesAt;
  final cached = _cachedBusRoutes;
  if (cachedAt != null &&
      cached != null &&
      DateTime.now().difference(cachedAt) < _busRoutesCacheTtl) {
    return cached;
  }

  final List<BusRoute> routes = [];

  try {
    final doc = await FirebaseFirestore.instance
        .collection('public_data')
        .doc('bus_routes')
        .get();

    if (!doc.exists) {
      if (kDebugMode) {
        print('No bus route data found in Firestore');
      }
      return [];
    }

    final data = doc.data();
    if (data == null) {
      if (kDebugMode) {
        print('Bus routes document exists but data is null');
      }
      return [];
    }

    if (data.containsKey('routes')) {
      final routesMap = data['routes'] as Map<String, dynamic>;
      if (kDebugMode) {
        print('Found ${routesMap.length} bus routes in Firestore');
      }

      routesMap.forEach((key, value) {
        final routeData = value as Map<String, dynamic>;
        routes.add(BusRoute.fromJson(routeData));
      });
    } else {
      if (kDebugMode) {
        print('WARNING: No routes field found in Firestore document');
      }
    }

    if (kDebugMode) {
      print('Successfully loaded ${routes.length} bus routes from Firestore');
    }

    if (data.containsKey('updated_at')) {
      busRoutesLastUpdated = data['updated_at'].toString();
    }

    _cachedBusRoutes = routes;
    _cachedBusRoutesAt = DateTime.now();
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching bus routes from Firestore: $e');
    }
  }

  return routes;
}

void invalidateBusRoutesCache() {
  _cachedBusRoutes = null;
  _cachedBusRoutesAt = null;
}
