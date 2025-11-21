import 'package:flutter/material.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/parsing.dart'; // for parseHtmlDocument

double getLetterSpacing(int fontSize, double percentage) {
  return fontSize * (percentage / 100);
}

void displayMessageToUser(String message, BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        message,
        style: context.text.headlineSmall?.copyWith(letterSpacing: 1),
      ),
    ),
  );
}

Future<Map<String, String>> fetchGoogleDocMap(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    print("ERROR: ${response.statusCode}");
    return {};
  }

  final document = parseHtmlDocument(response.body);
  Map<String, String> absenceMap = {};
  final allText = document.body?.text ?? '';
  // Matches formats like: November 18, 2025
  final dateRegex = RegExp(
    r'(January|February|March|April|May|June|July|August|September|October|November|December) \d{1,2}, \d{4}',
  );
  final match = dateRegex.firstMatch(allText);
  if (match != null) {
    absenceMap["Date"] = match.group(0)!;
  }

  for (var table in document.querySelectorAll('table')) {
    final rows = table.querySelectorAll('tr');

    for (var i = 0; i < rows.length; i++) {
      final cells = rows[i].querySelectorAll('td');
      if (cells.length >= 2) {
        String teacher = cells[0].text!.trim();
        print(teacher.contains("Kim") && teacher.contains("Ms"));
        if (teacher.contains("Kim") && teacher.contains("Ms")) {
          teacher = "Kim, Rosalyn";
        }
        // String teacher = cells[0].text!.trim();
        String period = cells[1].text!.trim().replaceAll("Day", "");
        // Skip header row
        if (teacher.toLowerCase().contains("teacher") &&
            period.toLowerCase().contains("period")) {
          continue;
        }

        if (teacher.isNotEmpty) {
          absenceMap[teacher] = period;
        }
      }
    }
  }
  print(absenceMap);

  return absenceMap;
}
