import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkTimeService {
  NetworkTimeService._();

  static Duration _offset = Duration.zero;
  static bool _isSynced = false;
  static DateTime? _lastSyncAttempt;

  static DateTime get now {
    return DateTime.now().add(_offset);
  }

  static bool get isSynced => _isSynced;

  static Future<void> sync() async {
    if (_lastSyncAttempt != null &&
        DateTime.now().difference(_lastSyncAttempt!) <
            const Duration(minutes: 5)) {
      return;
    }
    _lastSyncAttempt = DateTime.now();

    try {
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      final dateStr = response.headers['date'] ?? response.headers['Date'];
      if (dateStr != null) {
        final serverTime = HttpDate.parse(dateStr);
        _offset = serverTime.difference(DateTime.now());
        _isSynced = true;
        print(
          '[TIME] Synced with network. Offset: ${_offset.inMilliseconds}ms',
        );
      }
    } catch (e) {
      print('[TIME] Network sync failed (offline?): $e');
    }
  }

  static Future<void> forceSync() async {
    _lastSyncAttempt = null;
    await sync();
  }
}
