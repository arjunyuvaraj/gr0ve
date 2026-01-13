import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuickLink {
  final String id;
  final String title;
  final String url;
  final IconData icon;
  final Color color;

  const QuickLink({
    required this.id,
    required this.title,
    required this.url,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'url': url,
    'iconCodePoint': icon.codePoint,
    'iconFontFamily': icon.fontFamily,
    'color': color.value,
  };

  factory QuickLink.fromMap(Map<String, dynamic> map) {
    return QuickLink(
      id: map['id'] ?? 'unknown',
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      icon: IconData(
        map['iconCodePoint'] ?? Icons.link.codePoint,
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
      ),
      color: map['color'] != null ? Color(map['color']) : Colors.blue,
    );
  }
}

class LinkService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static const List<QuickLink> defaultLinks = [
    QuickLink(
      id: 'schoology',
      title: 'SCHOOLOGY',
      url: 'https://bca.schoology.com/home',
      icon: Icons.school,
      color: Color(0xFF3B5998),
    ),
    QuickLink(
      id: 'gradebook',
      title: 'GRADEBOOK',
      url: 'https://bcts.powerschool.com/public/',
      icon: Icons.book,
      color: Color(0xFF00AEEF),
    ),
    // ...repeat for other links
    QuickLink(
      id: 'teacher_absence',
      title: 'TEACHER ABSENCE',
      url:
          'https://docs.google.com/document/d/e/2PACX-1vRkhySmwAiTtY88tcshckpV4F0vRrULccaGrYl_Sf2ubWpyyXA4l8c-KAOuMzSwFe-qyAQhLqXzVsbA/pub',
      icon: Icons.description,
      color: const Color(0xFF4285F4),
    ),
    QuickLink(
      id: 'bus_locations',
      title: 'BUS LOCATIONS',
      url:
          'https://docs.google.com/spreadsheets/d/1S5v7kTbSiqV8GottWVi5tzpqLdTrEgWEY4ND4zvyV3o/edit?gid=0#gid=0',
      icon: Icons.directions_bus,
      color: const Color(0xFF0F9D58),
    ),
    QuickLink(
      id: 'counselor_booking',
      title: 'COUNSELOR BOOKING',
      url:
          'https://outlook.office365.com/book/CounselorBookings@bergen.org/?ismsaljsauthenabled=true',
      icon: Icons.event_available,
      color: const Color(0xFFFFB900),
    ),
    QuickLink(
      id: 'privacy_policy',
      title: 'PRIVACY POLICY',
      url: '/privacy_policy',
      icon: Icons.privacy_tip,
      color: const Color(0xFF6A1B9A),
    ),
  ];

  static Future<List<QuickLink>> getUserLinks() async {
    final user = _auth.currentUser;
    if (user == null) return defaultLinks;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists || doc.data()?['links'] == null) {
      await saveUserLinks(defaultLinks);
      return defaultLinks;
    }

    final saved = (doc['links'] as List)
        .map((l) => QuickLink.fromMap(Map<String, dynamic>.from(l)))
        .toList();

    return saved;
  }

  static Future<void> saveUserLinks(List<QuickLink> links) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'links': links.map((l) => l.toMap()).toList(),
    }, SetOptions(merge: true));
  }
}
