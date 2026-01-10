import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:gsheets/gsheets.dart';

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

Future<List<BusRoute>> fetchBusRoutes() async {
  await _initGSheets();
  final List<BusRoute> routes = [];

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
      _addRoute(routes, towns1[i], codes1[i]);
      _addRoute(routes, towns2[i], codes2[i]);
    }
  } catch (e) {}

  return routes;
}

void _addRoute(List<BusRoute> routes, Object town, Object rawCode) {
  final code = rawCode.toString().trim();
  final resolved = code.isEmpty ? '?' : code;

  routes.add(
    BusRoute(
      code: resolved,
      town: town.toString(),
      status: resolved == '?' ? 'Not here yet' : 'Arrived',
    ),
  );
}
