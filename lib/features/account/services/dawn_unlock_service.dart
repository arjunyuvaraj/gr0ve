import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DawnUnlockService {
  static const _field = 'dawn_avatar_unlocked';
  
  static final ValueNotifier<bool> isUnlocked = ValueNotifier(false);

  static Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      isUnlocked.value = (doc.data()?[_field] as bool?) ?? false;
    } catch (_) {}
  }

  /// Called when user opens the app or "checks in".
  /// Returns true if it was just unlocked during this exact call.
  static Future<bool> checkAndUnlock(BuildContext context) async {
    if (isUnlocked.value) return false;

    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    
    // Simplistic holiday check (e.g. Christmas, New Year, Thanksgiving estimation)
    final isHoliday = (now.month == 12 && now.day >= 24) || 
                      (now.month == 1 && now.day == 1) || 
                      (now.month == 11 && now.day >= 25 && now.day <= 28) ||
                      (now.month == 7 && now.day == 4);

    if (isWeekend || isHoliday) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {_field: true}, 
            SetOptions(merge: true),
          );
          isUnlocked.value = true;
          
          if (context.mounted) {
            _showDawnUnlockedDialog(context);
          }
          return true;
        } catch (_) {}
      }
    }
    return false;
  }

  static void _showDawnUnlockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2124),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF1C40F), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.wb_sunny_rounded, color: Color(0xFFF1C40F)),
            SizedBox(width: 12),
            Text('Secret Unlocked!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "You checked in on a weekend!\n\nAs a reward for taking time for yourself, you've unlocked the special Dawn avatar for Grover.",
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Awesome!', style: TextStyle(color: Color(0xFFF1C40F))),
          ),
        ],
      ),
    );
  }
}
