import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/grove/models/grove_models.dart';

/// A simple service to obfuscate/de-obfuscate story content.
/// This prevents casual viewing of story text when the app is unpacked.
class StoryEncryptionService {
  static const String _defaultKey = "GR0VE_SECRET_BRANCH_2026";

  /// Encrypts a string into a base64 encoded obfuscated string.
  static String encrypt(String plainText, {String? key}) {
    final k = key ?? _defaultKey;
    final bytes = utf8.encode(plainText);
    final encrypted = Uint8List(bytes.length);
    
    for (var i = 0; i < bytes.length; i++) {
      encrypted[i] = bytes[i] ^ k.codeUnitAt(i % k.length);
    }
    
    return base64.encode(encrypted);
  }

  /// Decrypts an obfuscated base64 string back to plain text.
  static String decrypt(String encryptedBase64, {String? key}) {
    final k = key ?? _defaultKey;
    final encrypted = base64.decode(encryptedBase64);
    final decrypted = Uint8List(encrypted.length);
    
    for (var i = 0; i < encrypted.length; i++) {
      decrypted[i] = encrypted[i] ^ k.codeUnitAt(i % k.length);
    }
    
    return utf8.decode(decrypted);
  }

  /// Loads an encrypted JSON asset and decrypts it into a list of Scenes.
  static Future<List<Scene>> loadFromAsset(String assetPath, {String? key}) async {
    try {
      final encryptedBase64 = await rootBundle.loadString(assetPath);
      final decryptedJson = decrypt(encryptedBase64, key: key);
      final List<dynamic> data = json.decode(decryptedJson);
      return data.map((item) => Scene.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading encrypted story: $e');
      return [];
    }
  }
}
