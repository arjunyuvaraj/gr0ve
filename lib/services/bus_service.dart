import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:gsheets/gsheets.dart';

/// ----------------------------
/// Model
/// ----------------------------
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

/// ----------------------------
/// Spreadsheet Config
/// ----------------------------
const String _spreadsheetId = '1S5v7kTbSiqV8GottWVi5tzpqLdTrEgWEY4ND4zvyV3o';

const String _worksheetTitle = 'Locations';

/// ----------------------------
/// GSheets Singleton Init
/// ----------------------------
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

/// ----------------------------
/// Public API
/// ----------------------------
Future<List<BusRoute>> fetchBusRoutes() async {
  await _initGSheets();
  final List<BusRoute> routes = [];

  try {
    final spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);
    final sheet = spreadsheet.worksheetByTitle(_worksheetTitle);

    if (sheet == null) {
      debugPrint('Bus sheet "$_worksheetTitle" not found');
      return [];
    }

    final rows = await sheet.values.allColumns();
    if (rows.length < 4) {
      debugPrint('Bus sheet has insufficient rows');
      return [];
    }

    final towns1 = rows[0].skip(1).toList();
    final codes1 = rows[1].skip(1).toList();
    final towns2 = rows[2].skip(1).toList();
    final codes2 = rows[3].skip(1).toList();

    final int length = [
      towns1.length,
      codes1.length,
      towns2.length,
      codes2.length,
    ].reduce((a, b) => a < b ? a : b);

    for (int i = 0; i < length; i++) {
      _addRoute(routes, town: towns1[i], rawCode: codes1[i]);

      _addRoute(routes, town: towns2[i], rawCode: codes2[i]);
    }
  } catch (e, stack) {
    debugPrint('fetchBusRoutes error: $e');
    debugPrintStack(stackTrace: stack);
  }

  return routes;
}

/// ----------------------------
/// Helpers
/// ----------------------------
void _addRoute(
  List<BusRoute> routes, {
  required Object town,
  required Object rawCode,
}) {
  final code = rawCode.toString().trim();
  final resolvedCode = code.isEmpty ? '?' : code;

  routes.add(
    BusRoute(
      code: resolvedCode,
      town: town.toString(),
      status: resolvedCode == '?' ? 'Not here yet' : 'Arrived',
    ),
  );
}
