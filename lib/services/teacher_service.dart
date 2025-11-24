import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/utilities/data/teacher_list.dart';
import 'package:universal_html/parsing.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> getTeachers() async {
  final firestore = FirebaseFirestore.instance;

  final snapshot = await firestore.collection('Teachers').get();

  return snapshot.docs.map((doc) {
    return {"id": doc.id, ...doc.data()};
  }).toList();
}

Future<List<Map<String, dynamic>>> getStarredTeachers() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final user = auth.currentUser;
  if (user == null) return [];

  final uid = user.uid;

  // STEP 1 — get the user doc
  final userDoc = await firestore.collection('Students').doc(uid).get();

  if (!userDoc.exists) return [];

  final data = userDoc.data()!;
  final starredList = List<String>.from(data['starredTeachers'] ?? []);

  if (starredList.isEmpty) return [];

  // STEP 2 — fetch teacher docs matching those names/IDs
  final query = await firestore
      .collection('Teachers')
      .where('name', whereIn: starredList)
      .get();

  // STEP 3 — return list of teacher maps
  return query.docs.map((doc) => {"id": doc.id, ...doc.data()}).toList();
}

Future<List<String>> toggleStarTeacher(String teacherName) async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final user = auth.currentUser;
  if (user == null) return [];

  final uid = user.uid;
  final ref = firestore.collection('Students').doc(uid);

  // Get the current list
  final snap = await ref.get();
  if (!snap.exists) return [];

  final data = snap.data()!;
  final List<String> starred = List<String>.from(data['starredTeachers'] ?? []);
  // Toggle logic
  if (starred.contains(teacherName)) {
    starred.remove(teacherName); // un-star
  } else {
    starred.add(teacherName); // star
  }

  // Save back to Firestore
  await ref.update({'starredTeachers': starred});

  return starred;
}

Stream<List<String>> starredTeachersStream() {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final user = auth.currentUser;
  if (user == null) return Stream.value([]);

  return firestore.collection('Students').doc(user.uid).snapshots().map((doc) {
    final data = doc.data();
    if (data == null) return [];
    return List<String>.from(data['starredTeachers'] ?? []);
  });
}

String getKimStatus() {
  final kimEntries = absenceList.keys
      .where((k) => k.toLowerCase().contains("kim"))
      .toList();

  if (kimEntries.isEmpty) return "Present";

  for (var key in kimEntries) {
    final status = absenceList[key];
    if (status != null && status != "Present") {
      return status;
    }
  }

  return "Present";
}

Future<Map<String, String>> fetchGoogleDocMap(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
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
        if (teacher.contains("Kim") && teacher.contains("Ms")) {
          teacher = "Kim, Rosalyn";
        }
        // String teacher = cells[0].text!.trim();
        String period = cells[1].text!.trim().replaceAll("Day", "").trim();
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

  return absenceMap;
}
