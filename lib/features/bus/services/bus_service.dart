import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

/// Stream bus routes from Firestore for real-time updates
/// Data is uploaded by admins using the Python upload script
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
            routes.add(
              BusRoute(
                code: routeData['code']?.toString() ?? '?',
                town: routeData['town']?.toString() ?? '',
                status: routeData['status']?.toString() ?? 'Not here yet',
              ),
            );
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

/// Fetch bus routes from Firestore (one-time fetch)
/// Kept for backward compatibility if needed elsewhere
Future<List<BusRoute>> fetchBusRoutes() async {
  final List<BusRoute> routes = [];

  try {
    // Read from Firestore instead of Google Sheets
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
        routes.add(
          BusRoute(
            code: routeData['code']?.toString() ?? '?',
            town: routeData['town']?.toString() ?? '',
            status: routeData['status']?.toString() ?? 'Not here yet',
          ),
        );
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
