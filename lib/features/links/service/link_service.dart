import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';

class QuickLink {
  final String id;
  final String title;
  final String url;
  final String iconKey;
  final Color color;

  const QuickLink({
    required this.id,
    required this.title,
    required this.url,
    required this.iconKey,
    required this.color,
  });

  IconData get icon => _iconMap[iconKey] ?? Icons.link;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'url': url,
    'iconKey': iconKey,
    'color': color.value,
  };

  factory QuickLink.fromMap(Map<String, dynamic> map) {
    return QuickLink(
      id: map['id'] ?? 'unknown',
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      iconKey: map['iconKey'] ?? 'link',
      color: map['color'] != null ? Color(map['color']) : Colors.blue,
    );
  }

  // Icon mapping - all const IconData references
  static const Map<String, IconData> _iconMap = {
    'school': Icons.school,
    'book': Icons.book,
    'description': Icons.description,
    'directions_bus': Icons.directions_bus,
    'event_available': Icons.event_available,
    'privacy_tip': Icons.privacy_tip,
    'link': Icons.link,
    'home': Icons.home,
    'settings': Icons.settings,
    'favorite': Icons.favorite,
    'email': Icons.email,
    'phone': Icons.phone,
    'calendar': Icons.calendar_today,
    'map': Icons.map,
    'shopping': Icons.shopping_cart,
    'sports': Icons.sports,
    'music': Icons.music_note,
    'video': Icons.video_library,
    'games': Icons.games,
    'work': Icons.work,
    // Add more icons as needed
  };
}

class LinkService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static const List<QuickLink> defaultLinks = [
    QuickLink(
      id: 'schoology',
      title: 'Schoology',
      url: 'https://bca.schoology.com/home',
      iconKey: 'school',
      color: Color(0xFF3B5998),
    ),
    QuickLink(
      id: 'gradebook',
      title: 'Powerschool',
      url: 'https://bcts.powerschool.com/public/',
      iconKey: 'book',
      color: Color(0xFF00AEEF),
    ),
    QuickLink(
      id: 'teacher_absence',
      title: 'Class Cancellation',
      url:
          'https://docs.google.com/document/d/e/2PACX-1vRkhySmwAiTtY88tcshckpV4F0vRrULccaGrYl_Sf2ubWpyyXA4l8c-KAOuMzSwFe-qyAQhLqXzVsbA/pub',
      iconKey: 'description',
      color: Color(0xFF4285F4),
    ),
    QuickLink(
      id: 'bus_locations',
      title: 'Buses',
      url:
          'https://docs.google.com/spreadsheets/d/1S5v7kTbSiqV8GottWVi5tzpqLdTrEgWEY4ND4zvyV3o/edit?gid=0#gid=0',
      iconKey: 'directions_bus',
      color: Color(0xFF0F9D58),
    ),
    QuickLink(
      id: 'counselor_booking',
      title: 'Counselor Bookings',
      url:
          'https://outlook.office365.com/book/CounselorBookings@bergen.org/?ismsaljsauthenabled=true',
      iconKey: 'event_available',
      color: Color(0xFFFFB900),
    ),
    QuickLink(
      id: 'privacy_policy',
      title: 'Pirvacy Policy',
      url: '/privacy_policy',
      iconKey: 'privacy_tip',
      color: Color(0xFF6A1B9A),
    ),
  ];

  static Future<List<QuickLink>> getUserLinks() async {
    final user = _auth.currentUser;
    if (user == null) return defaultLinks;

    try {
      final docData = await UserDocCache.get();
      final linksData = docData?['links'] ?? docData?['inks'];

      if (docData == null || linksData == null) {
        if (docData != null) {
          await saveUserLinks(defaultLinks);
        }
        return defaultLinks;
      }

      final saved = (linksData as List)
          .map((l) => QuickLink.fromMap(Map<String, dynamic>.from(l)))
          .toList();

      return saved;
    } catch (e) {
      debugPrint('[LinkService] Error fetching links: $e');
      return defaultLinks;
    }
  }

  static Future<void> saveUserLinks(List<QuickLink> links) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'links': links.map((l) => l.toMap()).toList(),
    }, SetOptions(merge: true));
  }
}
