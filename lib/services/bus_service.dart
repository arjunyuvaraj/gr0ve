import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

class BusRoute {
  final String code;
  final List<String> towns;
  final String status;

  BusRoute({required this.code, required this.towns, required this.status});
}

Future<List<BusRoute>> fetchBusRoutes(String sheetUrl) async {
  final csvUrl = sheetUrl.replaceAll('/pubhtml', '/gviz/tq?tqx=out:csv');

  final response = await http.get(Uri.parse(csvUrl));

  if (response.statusCode != 200) {
    print("ERROR: Failed to fetch bus routes CSV");
    return [];
  }

  final List<BusRoute> routes = [];

  // Parse CSV safely (handles quotes + commas)
  final rows = const CsvToListConverter(eol: '\n').convert(response.body);

  if (rows.isEmpty) return [];

  // Columns that actually contain town data in your sheet
  const townColumns = [0, 2];

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];

    for (final col in townColumns) {
      if (col >= row.length) continue;

      final cell = row[col]?.toString().trim() ?? "";
      if (cell.isEmpty) continue;

      final towns = cell
          .split('/')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (towns.isEmpty) continue;

      routes.add(
        BusRoute(
          code: "?", // no codes exist in this CSV
          towns: towns,
          status: "Not here yet",
        ),
      );
    }
  }
  print("Fetched ${routes.length} bus routes");
  return routes;
}
