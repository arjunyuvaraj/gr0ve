import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

class BusRoute {
  final String code;
  final List<String> towns;
  final String status;

  BusRoute({required this.code, required this.towns, required this.status});
}

Future<List<BusRoute>> fetchBusRoutes(String sheetUrl) async {
  final response = await http.get(Uri.parse(sheetUrl));

  if (response.statusCode != 200) {
    print("ERROR: Failed to fetch bus routes CSV");
    return [];
  }

  final List<BusRoute> routes = [];

  final rows = const CsvToListConverter(eol: '\n').convert(response.body);
  if (rows.length <= 1) return [];

  // Column pairs: [townColumn, routeColumn]
  const columnPairs = [
    [0, 1],
    [2, 3],
  ];

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];

    for (final pair in columnPairs) {
      final townCol = pair[0];
      final routeCol = pair[1];

      if (townCol >= row.length || routeCol >= row.length) continue;

      final town = row[townCol]?.toString().trim() ?? "";
      final code = row[routeCol]?.toString().trim() ?? "";

      if (town.isEmpty || code.isEmpty) continue;

      final towns = town
          .split('/')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      routes.add(BusRoute(code: code, towns: towns, status: "Not here yet"));
    }
  }

  routes.sort((a, b) => a.towns.first.compareTo(b.towns.first));

  print("Fetched ${routes.length} bus routes");
  return routes;
}
