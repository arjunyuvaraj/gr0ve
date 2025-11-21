import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
