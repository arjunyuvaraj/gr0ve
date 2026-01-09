import 'package:http/http.dart' as http;
import 'package:universal_html/parsing.dart';

Future<Map<String, String>> fetchGoogleDocMap(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) return {};

  final document = parseHtmlDocument(response.body);
  final Map<String, String> absenceMap = {};

  final dateRegex = RegExp(
    r'(January|February|March|April|May|June|July|August|September|October|November|December) \d{1,2}, \d{4}',
  );
  final dateMatch = dateRegex.firstMatch(document.body?.text ?? '');
  if (dateMatch != null) {
    absenceMap['Date'] = dateMatch.group(0)!;
  }

  for (final table in document.querySelectorAll('table')) {
    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 2) continue;

      String teacherRaw = cells[0].text!.trim();
      String rawPeriod = cells[1].text!.trim();

      if (teacherRaw.toLowerCase().contains('teacher') &&
          rawPeriod.toLowerCase().contains('period'))
        continue;

      if (teacherRaw.isEmpty) continue;

      final teacher = _normalizeTeacherName(teacherRaw);
      final formattedPeriod = _formatPeriods(rawPeriod);
      absenceMap[teacher] = formattedPeriod;
    }
  }

  return absenceMap;
}

String _normalizeTeacherName(String raw) {
  raw = raw.trim();

  if (raw.contains('Kim') && raw.contains('Ms')) return 'Kim, Rosalyn';

  final parts = raw.split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    final first = parts.sublist(0, parts.length - 1).join(' ');
    final last = parts.last;
    return '$last, $first';
  }
  return raw;
}

String _formatPeriods(String input) {
  final hasIGS = input.contains('IGS');

  final singlePeriodMatch = RegExp(
    r'\b(\d+)(st|nd|rd|th)?\s+Period\b',
    caseSensitive: false,
  ).firstMatch(input);

  if (singlePeriodMatch != null) {
    final periodNumber = singlePeriodMatch.group(1);
    return hasIGS ? 'Period $periodNumber & IGS' : 'Period $periodNumber';
  }

  final cleaned = input
      .replaceAll('Periods', '')
      .replaceAll('Period', '')
      .replaceAll('Day', '')
      .replaceAll('IGS', '')
      .replaceAll('&', '')
      .replaceAll('Only', '')
      .trim();

  final expanded = _expandRange(cleaned);

  if (expanded.isEmpty) return hasIGS ? 'IGS' : 'Present';
  return expanded == "All"
      ? "All"
      : hasIGS
      ? 'Periods $expanded & IGS'
      : 'Periods $expanded';
}

String _expandRange(String range) {
  if (!range.contains('-')) return range;

  final parts = range.split('-').map((e) => e.trim()).toList();
  if (parts.length != 2) return range;

  final start = int.tryParse(parts[0]);
  final end = int.tryParse(parts[1]);
  if (start == null || end == null || end < start) return range;

  return List.generate(end - start + 1, (i) => start + i).join(', ');
}
