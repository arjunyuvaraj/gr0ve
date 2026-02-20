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
/// This is called when user pulls to refresh
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
    // final csvData = const CsvToListConverter().convert(response.body);
    final csvData = const CsvDecoder().convert(response.body);

    if (kDebugMode) {
      print('📊 Fetched ${csvData.length} rows from sheet');
    }

    final List<BusRoute> routes = [];

    // Parse each row starting from row 1 (skip header row 0)
    // Parse each row starting from row 1 (skip header row 0)
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty) continue;

      // --- LEFT COLUMNS: A (index 0) = Town, B (index 1) = Code ---
      if (row.length > 0 && row[0] != null && row[0].toString().isNotEmpty) {
        final town = row[0].toString().trim();
        final code =
            (row.length > 1 && row[1] != null && row[1].toString().isNotEmpty)
            ? row[1].toString().trim()
            : '';
        // Bus has arrived if the code cell (B) is filled
        final status = code.isNotEmpty ? code : 'Not here yet';
        routes.add(BusRoute(town: town, code: code, status: status));
      }

      // --- RIGHT COLUMNS: C (index 2) = Town, D (index 3) = Code ---
      if (row.length > 2 && row[2] != null && row[2].toString().isNotEmpty) {
        final town = row[2].toString().trim();
        final code =
            (row.length > 3 && row[3] != null && row[3].toString().isNotEmpty)
            ? row[3].toString().trim()
            : '';
        // Bus has arrived if the code cell (D) is filled
        final status = code.isNotEmpty ? code : 'Not here yet';
        routes.add(BusRoute(town: town, code: code, status: status));
      }
    }

    if (routes.isEmpty) {
      throw Exception('No valid routes found in Google Sheets');
    }

    if (kDebugMode) {
      print('✅ Parsed ${routes.length} valid bus routes');
    }

    // Step 3: Update Firestore with new data
    final Map<String, dynamic> routesMap = {};
    for (int i = 0; i < routes.length; i++) {
      routesMap['route_$i'] = routes[i].toJson();
    }

    await FirebaseFirestore.instance
        .collection('public_data')
        .doc('bus_routes')
        .set({
          'routes': routesMap,
          'last_updated': FieldValue.serverTimestamp(),
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
