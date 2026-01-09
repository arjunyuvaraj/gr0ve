import 'package:flutter/services.dart';
import 'package:gsheets/gsheets.dart';

class BusRoute {
  final String code;
  final String town;
  final String status;

  BusRoute({required this.code, required this.town, required this.status});
}

const String _spreadsheetId = '1S5v7kTbSiqV8GottWVi5tzpqLdTrEgWEY4ND4zvyV3o';

const String _worksheetTitle = 'Locations';

late final GSheets _gsheets;
bool _gsheetsReady = false;

Future<void> initGSheets() async {
  if (_gsheetsReady) return;

  final json = await rootBundle.loadString('assets/credentials/gsheets.json');

  _gsheets = GSheets(json);
  _gsheetsReady = true;
}

Future<List<BusRoute>> fetchBusRoutes() async {
  List<BusRoute> finalList = [];
  if (!_gsheetsReady) {
    await initGSheets();
  }

  try {
    final spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);

    final sheet = spreadsheet.worksheetByTitle(_worksheetTitle);

    if (sheet == null) {
      return [];
    }

    final rows = await sheet.values.allColumns();
    final towns1 = rows[0].sublist(1, 24);
    final codes1 = rows[1].sublist(1, 24);
    final towns2 = rows[2].sublist(1, 24);
    final codes2 = rows[3].sublist(1, 24);

    for (int i = 0; i < towns1.length; i++) {
      finalList.add(
        BusRoute(
          code: codes1[i],
          town: towns1[i].toString(),
          status: codes1[i] == "?" ? "Not here yet" : "Arrived",
        ),
      );
      finalList.add(
        BusRoute(
          code: codes2[i],
          town: towns2[i].toString(),
          status: codes2[i] == "?" ? "Not here yet" : "Arrived",
        ),
      );
    }
    return finalList;
  } catch (e) {}
  return [];
}
