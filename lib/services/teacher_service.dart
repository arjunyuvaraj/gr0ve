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

      final teacherRaw = cells[0].text?.trim() ?? '';
      final periodRaw = cells[1].text?.trim() ?? '';

      if (teacherRaw.isEmpty) continue;
      if (teacherRaw.toLowerCase().contains('teacher')) continue;

      final teacherKey = googleDocTeacherKey(teacherRaw);
      final period = formatPeriods(periodRaw);

      absenceMap[teacherKey] = period.isEmpty ? 'Present' : period;
    }
  }

  return absenceMap;
}

String googleDocTeacherKey(String raw) {
  raw = raw.trim();
  raw = raw.replaceAllMapped(RegExp(r'\(\s*(.*?)\s*\)'), (m) => '(${m[1]})');
  return raw;
}

String? handleEdgeCases(String name) {
  const map = {
    'kim(mr)': 'kim, deok-yang',
    'kim(ms)': 'lee, rosalyn',
    'smith(ms)': 'smith, ericka',
    'smith(mr)': 'smith, michael',
  };

  final normalized = name
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('.', '');

  return map[normalized];
}

bool haveSameCharacters(String str1, String str2) {
  if (str1.length != str2.length) {
    return false;
  }

  List<int> list1 = str1.codeUnits.toList();
  List<int> list2 = str2.codeUnits.toList();

  list1.sort();
  list2.sort();

  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) {
      return false;
    }
  }

  return true;
}

String normalizeTeacherName(String raw) {
  raw = raw.trim();
  raw = raw.replaceAll(RegExp(r'\(.*?\)'), '');
  final titles = ['Mr.', 'Ms.', 'Mrs.', 'Dr.', 'Mr', 'Ms', 'Mrs', 'Dr'];
  for (var t in titles) {
    if (raw.startsWith(t)) raw = raw.replaceFirst(t, '').trim();
  }

  if (raw.contains(',') && raw.split(',').length == 2) return raw.trim();

  final parts = raw.split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) return '${parts.last}, ${parts.first}';

  return raw;
}

String _cleanKey(String key) {
  return key
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .toLowerCase();
}

bool matchesTeacher(String docKey, String teacherKey) {
  if (docKey == 'Date') return false;

  final edgeCase = handleEdgeCases(docKey);
  final docName = edgeCase ?? docKey;
  final normalizedTeacher = normalizeTeacherName(teacherKey);

  final docClean = _cleanKey(docName);
  final teacherClean = _cleanKey(normalizedTeacher);

  if (docClean == teacherClean) return true;

  if (!docClean.contains(',') && teacherClean.contains(',')) {
    final docLast = docClean;
    final teacherLast = teacherClean.split(',').first;
    return docLast == teacherLast;
  }

  return false;
}

String formatPeriods(String input) {
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

  final expanded = expandRange(cleaned);

  if (expanded.isEmpty) return hasIGS ? 'IGS' : 'Present';
  return expanded == "All"
      ? "All"
      : hasIGS
      ? 'Periods $expanded & IGS'
      : 'Periods $expanded';
}

String expandRange(String range) {
  if (!range.contains('-')) return range;

  final parts = range.split('-').map((e) => e.trim()).toList();
  if (parts.length != 2) return range;

  final start = int.tryParse(parts[0]);
  final end = int.tryParse(parts[1]);
  if (start == null || end == null || end < start) return range;

  return List.generate(end - start + 1, (i) => start + i).join(', ');
}

String formatStatusString(String status) {
  if (!status.startsWith("Periods ") && !status.startsWith("Period ")) {
    return status;
  }

  // Extract the periods part (everything after "Period(s) " and before any other text)
  final match = RegExp(r'Period[s]?\s+(.+)').firstMatch(status);
  if (match == null) return status;

  final periodsString = match.group(1)!;

  // Split by common separators
  final parts = periodsString
      .split(RegExp(r'[,&]'))
      .map((e) => e.trim())
      .toList();

  List<dynamic> items = []; // Can be int or String (for "IGS")

  for (final part in parts) {
    if (part.toUpperCase() == "IGS") {
      items.add("IGS");
    } else {
      final num = int.tryParse(part);
      if (num != null) items.add(num);
    }
  }

  if (items.isEmpty) return status;

  // Separate numbers and IGS
  List<int> numbers = items.whereType<int>().toList()..sort();
  bool hasIGS = items.contains("IGS");

  // Group consecutive numbers
  List<String> groups = [];
  if (numbers.isNotEmpty) {
    int rangeStart = numbers[0];
    int rangeEnd = numbers[0];

    for (int i = 1; i < numbers.length; i++) {
      if (numbers[i] == rangeEnd + 1) {
        rangeEnd = numbers[i];
      } else {
        // End current range
        if (rangeStart == rangeEnd) {
          groups.add(rangeStart.toString());
        } else {
          groups.add("$rangeStart-$rangeEnd");
        }
        rangeStart = numbers[i];
        rangeEnd = numbers[i];
      }
    }

    // Add the last range
    if (rangeStart == rangeEnd) {
      groups.add(rangeStart.toString());
    } else {
      groups.add("$rangeStart-$rangeEnd");
    }
  }

  // Add IGS to groups
  if (hasIGS) {
    groups.add("IGS");
  }

  // Format the output
  if (groups.isEmpty) return status;

  String result;
  if (groups.length == 1) {
    // Single period or range
    if (groups[0] == "IGS" || groups[0].contains("-")) {
      result = "Periods ${groups[0]}";
    } else {
      result = "Period ${groups[0]}";
    }
  } else {
    // Multiple groups - use "Periods" and join with " & "
    result = "Periods ${groups.join(' & ')}";
  }

  return result;
}
