import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, String>> fetchGoogleSheetAbsences({
  required String spreadsheetId,
  required String worksheetTitle,
}) async {
  final Map<String, String> absenceMap = {};

  final user = FirebaseAuth.instance.currentUser;
  if (user == null || !user.emailVerified) {
    if (kDebugMode) {
      print('User not authenticated or email not verified');
    }
    return {};
  }

  if (!user.email!.toLowerCase().endsWith('@bergen.org')) {
    if (kDebugMode) {
      print('User does not have a valid bergen.org email');
    }
    return {};
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('public_data')
        .doc('teacher_absences')
        .get()
        .timeout(const Duration(seconds: 4));

    if (!doc.exists) {
      if (kDebugMode) {
        print('No absence data found in Firestore');
      }
      return {};
    }

    final data = doc.data();
    if (data == null) {
      if (kDebugMode) {
        print('Absence document exists but data is null');
      }
      return {};
    }

    if (kDebugMode) {
      print('Firestore data keys: ${data.keys.toList()}');
      print('Full data: $data');
    }

    if (data.containsKey('date')) {
      absenceMap['date'] = data['date'].toString();
      if (kDebugMode) {
        print('Date found: ${absenceMap['date']}');
      }
    } else {
      if (kDebugMode) {
        print('WARNING: No date field found in Firestore document');
      }
    }

    if (data.containsKey('teachers')) {
      final teachers = data['teachers'] as Map<String, dynamic>;
      if (kDebugMode) {
        print('Teachers map has ${teachers.length} entries');
      }
      teachers.forEach((key, value) {
        absenceMap[key] = value.toString();
        if (kDebugMode) {
          print('  - $key: $value');
        }
      });
    } else {
      if (kDebugMode) {
        print('WARNING: No teachers field found in Firestore document');
      }
    }

    if (kDebugMode) {
      print('Successfully loaded ${absenceMap.length} records from Firestore');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching absences from Firestore: $e');
    }
  }

  return absenceMap;
}

Stream<Map<String, String>> streamTeacherAbsences() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null ||
      !user.emailVerified ||
      !user.email!.toLowerCase().endsWith('@bergen.org')) {
    return Stream.value({});
  }

  return FirebaseFirestore.instance
      .collection('public_data')
      .doc('teacher_absences')
      .snapshots()
      .map((doc) {
        if (!doc.exists || doc.data() == null) return <String, String>{};
        final data = doc.data()!;
        final Map<String, String> result = {};

        if (data.containsKey('date')) {
          result['date'] = data['date'].toString();
        }

        if (data.containsKey('teachers')) {
          final teachers = data['teachers'] as Map<String, dynamic>;
          teachers.forEach((key, value) {
            result[key] = value.toString();
          });
        }
        return result;
      });
}

Stream<Map<String, Map<String, dynamic>>> streamTeacherList() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null ||
      !user.emailVerified ||
      !user.email!.toLowerCase().endsWith('@bergen.org')) {
    return Stream.value({});
  }

  return FirebaseFirestore.instance.collection('teachers').snapshots().map((
    snapshot,
  ) {
    final Map<String, Map<String, dynamic>> result = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final String name = (data['name'] ?? doc.id).toString();
      result[name] = {
        'name': name,
        'department': data['department'] ?? '',
        'email': data['email'] ?? '',
      };
    }
    return result;
  });
}

Future<List<Map<String, dynamic>>> fetchAllTeachersFromFirebase() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .get()
        .timeout(const Duration(seconds: 4));

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] ?? doc.id,
        'department': data['department'] ?? '',
        'email': data['email'] ?? '',
      };
    }).toList();
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching teachers from Firebase: $e');
    }
    return [];
  }
}

String resolveTeacherStatus({
  required String teacherName,
  required Map<String, String> absenceMap,
}) {
  for (final entry in absenceMap.entries) {
    if (matchesTeacher(entry.key, teacherName)) {
      return entry.value;
    }
  }

  return 'Present';
}

String googleDocTeacherKey(String raw) {
  raw = raw.trim();
  raw = raw.replaceAllMapped(RegExp(r'\(\s*(.*?)\s*\)'), (m) => '(${m[1]})');
  return raw;
}

String? handleEdgeCases(String name) {
  const map = {
    'kim(dr)': 'kim, deok-yang',
    'drkim': 'kim, deok-yang',
    'dr.kim': 'kim, deok-yang',
    'kim(ms)': 'kim, rosalyn',
    'mskim': 'kim, rosalyn',
    'ms.kim': 'kim, rosalyn',

    'smith(ms)': 'smith, ericka',
    'mssmith': 'smith, ericka',
    'ms.smith': 'smith, ericka',
    'smith(dr)': 'smith, michael',
    'drsmith': 'smith, michael',
    'dr.smith': 'smith, michael',

    'crane(ms)': 'crane, laura',
    'mscrane': 'crane, laura',
    'ms.crane': 'crane, laura',
    'crane(mr)': 'crane, todd',
    'mrcrane': 'crane, todd',
    'mr.crane': 'crane, todd',

    'drapcznski': 'drapczynski, anna',
    'msdrapcznski': 'drapczynski, anna',
    'ms.drapcznski': 'drapczynski, anna',
    'drapcznski(ms)': 'drapczynski, anna',
  };

  final normalized = name
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('.', '')
      .replaceAll(',', '');

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

  final titles = ['Dr.', 'Mr.', 'Ms.', 'Mrs.'];
  for (var t in titles) {
    if (raw.startsWith(t + ' ') || raw == t) {
      raw = raw.replaceFirst(t, '').trim();
    }
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
  if (docKey == 'date' || docKey == 'Date') return false;

  final edgeCase = handleEdgeCases(docKey);
  final docName = edgeCase ?? docKey;
  final normalizedTeacher = normalizeTeacherName(teacherKey);

  final docClean = _cleanKey(docName);
  final teacherClean = _cleanKey(normalizedTeacher);

  if (docClean == teacherClean) {
    return true;
  }

  if (!docClean.contains(',') && teacherClean.contains(',')) {
    final docLast = docClean;
    final teacherLast = teacherClean.split(',').first;

    if (docLast == teacherLast) {
      return true;
    }
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

  final match = RegExp(r'Period[s]?\s+(.+)').firstMatch(status);
  if (match == null) return status;

  final periodsString = match.group(1)!;

  final parts = periodsString
      .split(RegExp(r'[,&]'))
      .map((e) => e.trim())
      .toList();

  List<dynamic> items = [];

  for (final part in parts) {
    if (part.toUpperCase() == "IGS") {
      items.add("IGS");
    } else if (part.contains('-')) {
      final rangeParts = part.split('-').map((e) => e.trim()).toList();
      if (rangeParts.length == 2) {
        final start = int.tryParse(rangeParts[0]);
        final end = int.tryParse(rangeParts[1]);
        if (start != null && end != null && end >= start) {
          for (int n = start; n <= end; n++) {
            items.add(n);
          }
        }
      }
    } else {
      final num = int.tryParse(part);
      if (num != null) items.add(num);
    }
  }

  if (items.isEmpty) return status;

  List<int> numbers = items.whereType<int>().toList()..sort();
  bool hasIGS = items.contains("IGS");

  List<String> groups = [];
  if (numbers.isNotEmpty) {
    int rangeStart = numbers[0];
    int rangeEnd = numbers[0];

    for (int i = 1; i < numbers.length; i++) {
      if (numbers[i] == rangeEnd + 1) {
        rangeEnd = numbers[i];
      } else {
        if (rangeStart == rangeEnd) {
          groups.add(rangeStart.toString());
        } else {
          groups.add("$rangeStart-$rangeEnd");
        }
        rangeStart = numbers[i];
        rangeEnd = numbers[i];
      }
    }

    if (rangeStart == rangeEnd) {
      groups.add(rangeStart.toString());
    } else {
      groups.add("$rangeStart-$rangeEnd");
    }
  }

  if (hasIGS) {
    groups.add("IGS");
  }

  if (groups.isEmpty) return status;

  String result;
  if (groups.length == 1) {
    if (groups[0] == "IGS" || groups[0].contains("-")) {
      result = "Periods ${groups[0]}";
    } else {
      result = "Period ${groups[0]}";
    }
  } else {
    result = "Periods ${groups.join(' & ')}";
  }

  return result;
}

Future<Map<String, Map<String, dynamic>>> fetchTeacherListFromFirebase() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .get()
        .timeout(const Duration(seconds: 4));

    final Map<String, Map<String, dynamic>> result = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final String name = (data['name'] ?? doc.id).toString();

      result[name] = {
        'name': name,
        'department': data['department'] ?? '',
        'email': data['email'] ?? '',
      };
    }

    return result;
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching teacher list from Firebase: $e');
    }
    return {};
  }
}
