import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';

class DawnUnlockService {
  static const _field = 'dawn_avatar_unlocked';
  
  static final ValueNotifier<bool> isUnlocked = ValueNotifier(false);

  static Future<void> init({Map<String, dynamic>? cachedUserData}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final data = cachedUserData ?? await UserDocCache.get();
      isUnlocked.value = (data?[_field] as bool?) ?? false;
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
      barrierDismissible: false,
      builder: (ctx) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: AlertDialog(
                backgroundColor: const Color(0xFF141414),
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: const Color(0xFFF1C40F).withOpacity(0.3), width: 1.5),
                ),
                content: Container(
                  width: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFF1C40F).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF1C40F).withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF1C40F).withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            )
                          ]
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFF1C40F),
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'DAWN UNLOCKED',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          color: Color(0xFFF1C40F),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          "You checked in during your free time. As a reward for prioritizing yourself, a secret Grover variant has appeared in your locker.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                        child: InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1C40F),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF1C40F).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ]
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'CLAIM AVATAR',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                color: Color(0xFF141414),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
