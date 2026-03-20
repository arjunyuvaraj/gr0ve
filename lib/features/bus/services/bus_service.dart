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

/// Configuration for Google Sheets
class SheetsConfig {
  // Your Google Sheets ID
  static const String spreadsheetId =
      '1S5v7kTbSiqV8GottWVi5tzpqLdTrEgWEY4ND4zvyV3o';

  // The gid (sheet tab ID) - change if using different tab
  static const String gid = '0';

  // CSV export URL
  static String get csvUrl =>
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/export?format=csv&gid=$gid';
}

/// Stream bus routes from Firestore for real-time updates
Stream<List<BusRoute>> getBusRoutesStream() {
  return FirebaseFirestore.instance
      .collection('public_data')
      .doc('bus_routes')
      .snapshots()
      .map((snapshot) {
        final List<BusRoute> routes = [];

        if (!snapshot.exists) {
          if (kDebugMode) {
            print('No bus route data found in Firestore');
          }
          return routes;
        }

        final data = snapshot.data();
        if (data == null) {
          if (kDebugMode) {
            print('Bus routes document exists but data is null');
          }
          return routes;
        }

        // Get the routes map
        if (data.containsKey('routes')) {
          final routesMap = data['routes'] as Map<String, dynamic>;
          if (kDebugMode) {
            print('Found ${routesMap.length} bus routes in Firestore');
          }

          // Convert map to list of BusRoute objects
          // Python script keys by town name, not route_N
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
          print(
            'Successfully loaded ${routes.length} bus routes from Firestore',
          );
        }

        return routes;
      });
}

/// Refresh: Fetch from Google Sheets and update Firestore
/// This is called when user pulls to refresh or for manual sync
Future<void> refreshBusRoutesFromSheets() async {
  try {
    if (kDebugMode) {
      print('🔄 Fetching latest bus routes from Google Sheets...');
    }

    // Step 1: Fetch from Google Sheets
    final url = Uri.parse(SheetsConfig.csvUrl);
    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch from Google Sheets: ${response.statusCode}\n'
        'Make sure the sheet is public (anyone with link can view)',
      );
    }

    // Step 2: Parse CSV data
    final csvData = const CsvDecoder().convert(response.body);

    if (kDebugMode) {
      print('📊 Fetched ${csvData.length} rows from sheet');
    }

    final List<BusRoute> routes = [];

    if (kDebugMode) {
      print('Parsing CSV data:');
      for (int i = 0; i < csvData.length.clamp(0, 5); i++) {
        print('  Row $i: ${csvData[i]}');
      }
    }

    // Parse each row starting from row 1 (skip header row 0)
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];

      // Skip completely empty rows
      if (row.isEmpty) continue;

      // Skip rows where all cells are empty
      if (row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
        continue;
      }

      if (kDebugMode) {
        print('Row $i (${row.length} cells): $row');
      }

      // --- LEFT COLUMNS: A (index 0) = Town, B (index 1) = Code ---
      final town1 = (row.length > 0) ? row[0].toString().trim() : '';
      final code1 = (row.length > 1) ? row[1].toString().trim() : '';

      if (town1.isNotEmpty) {
        final status = code1.isNotEmpty ? 'Arrived' : 'Missing';
        routes.add(BusRoute(town: town1, code: code1, status: status));
        if (kDebugMode) {
          print('  → Added: $town1 ($code1) — $status');
        }
      }

      // --- RIGHT COLUMNS: C (index 2) = Town, D (index 3) = Code ---
      final town2 = (row.length > 2) ? row[2].toString().trim() : '';
      final code2 = (row.length > 3) ? row[3].toString().trim() : '';

      if (town2.isNotEmpty) {
        final status = code2.isNotEmpty ? 'Arrived' : 'Missing';
        routes.add(BusRoute(town: town2, code: code2, status: status));
        if (kDebugMode) {
          print('  → Added: $town2 ($code2) — $status');
        }
      }
    }

    if (routes.isEmpty) {
      throw Exception('No valid routes found in Google Sheets');
    }

    if (kDebugMode) {
      print('✅ Parsed ${routes.length} valid bus routes');
    }

    // Step 3: Update Firestore with new data
    // Match Python script structure - key by town name, not route_N
    final Map<String, dynamic> routesMap = {};
    for (final route in routes) {
      // Use town as key if available, otherwise use route_N
      final key = route.town.isNotEmpty
          ? route.town
          : 'route_${routes.indexOf(route)}';
      routesMap[key] = route.toJson();
    }

    // Use 'updated_at' with ISO string
    // This matches the Python script exactly
    await FirebaseFirestore.instance
        .collection('public_data')
        .doc('bus_routes')
        .set({
          'routes': routesMap,
          'updated_at': DateTime.now().toIso8601String(),
          'route_count': routes.length,
        });

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

/// Watch mode: Continuously refresh bus routes every [intervalSeconds] for [durationMinutes]
///
/// This mimics the Python script's dismissal mode:
/// - Default: 30s interval, 60min duration
/// - Fetches from Google Sheets and updates Firestore repeatedly
/// - Useful during school dismissal when bus locations change frequently
///
/// Example usage:
/// ```dart
/// // Start watch mode with callbacks
/// watchBusRoutesForDismissal(
///   intervalSeconds: 30,
///   durationMinutes: 60,
///   onSyncStart: (syncCount, nextSync) {
///     print('Sync #$syncCount scheduled for $nextSync');
///   },
///   onSyncError: (syncCount, error) {
///     print('Sync #$syncCount failed: $error');
///   },
/// );
/// ```
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

/// Fetch bus routes from Firestore (one-time fetch)
/// Kept for backward compatibility if needed elsewhere
Future<List<BusRoute>> fetchBusRoutes() async {
  final List<BusRoute> routes = [];

  try {
    // Read from Firestore
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

    // Get the routes map
    if (data.containsKey('routes')) {
      final routesMap = data['routes'] as Map<String, dynamic>;
      if (kDebugMode) {
        print('Found ${routesMap.length} bus routes in Firestore');
      }

      // Convert map to list of BusRoute objects
      // Python script keys by town name
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
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching bus routes from Firestore: $e');
    }
  }

  return routes;
}
