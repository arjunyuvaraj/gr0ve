import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service to provide a reliable network-synced time to prevent
/// local clock manipulation (e.g. changing phone date to skip wait timers).
class NetworkTimeService {
  NetworkTimeService._();

  static Duration _offset = Duration.zero;
  static bool _isSynced = false;
  static DateTime? _lastSyncAttempt;

  /// Returns the current time, adjusted by the network offset if synced.
  /// Falls back to system time if not yet synced.
  static DateTime get now {
    return DateTime.now().add(_offset);
  }

  /// Whether the time has been successfully synced with a network source.
  static bool get isSynced => _isSynced;

  /// Attempts to sync the local clock with a reliable network source.
  /// Uses the HTTP 'Date' header from Google as a lightweight NTP alternative.
  static Future<void> sync() async {
    // Don't spam sync requests
    if (_lastSyncAttempt != null &&
        DateTime.now().difference(_lastSyncAttempt!) < const Duration(minutes: 5)) {
      return;
    }
    _lastSyncAttempt = DateTime.now();

    try {
      // We use HEAD request to minimize data usage.
      // Google is highly reliable and provides a standard RFC 1123 date header.
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      final dateStr = response.headers['date'] ?? response.headers['Date'];
      if (dateStr != null) {
        final serverTime = HttpDate.parse(dateStr);
        _offset = serverTime.difference(DateTime.now());
        _isSynced = true;
        print('[TIME] Synced with network. Offset: ${_offset.inMilliseconds}ms');
      }
    } catch (e) {
      print('[TIME] Network sync failed (offline?): $e');
      // We don't throw, just fall back to system time.
    }
  }

  /// Forces a sync even if one happened recently.
  static Future<void> forceSync() async {
    _lastSyncAttempt = null;
    await sync();
  }
}
