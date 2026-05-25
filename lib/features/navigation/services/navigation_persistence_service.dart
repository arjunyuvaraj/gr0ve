import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';

class NavigationPersistenceService {
  static const String _storageKey = 'nav_item_order';
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<List<String>?> getSavedOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final localOrder = prefs.getStringList(_storageKey);

    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final data = await UserDocCache.get();
        if (data != null) {
          final remoteOrder = (data['navigation_order'] as List?)
              ?.cast<String>();
          if (remoteOrder != null) {
            if (localOrder == null ||
                _listEquals(localOrder, remoteOrder) == false) {
              await prefs.setStringList(_storageKey, remoteOrder);
            }
            return remoteOrder;
          }
        }
      } catch (e) {
        print('[NAV_SERVICE] Error fetching remote order: $e');
      }
    }

    return localOrder;
  }

  Future<void> saveOrder(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, order);

    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'navigation_order': order,
        });
      } catch (e) {
        print('[NAV_SERVICE] Error saving remote order: $e');
      }
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
