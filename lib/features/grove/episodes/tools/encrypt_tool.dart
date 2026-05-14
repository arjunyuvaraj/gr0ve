import 'dart:convert';
import 'dart:io';
import 'package:gr0ve/features/grove/services/story_encryption_service.dart';

/// Run this script from the project root to encrypt a story JSON file.
/// Usage: dart lib/features/grove/episodes/tools/encrypt_tool.dart <input_json> <output_file>
void main(List<String> args) {
  if (args.length < 2) {
    print(
      'Usage: dart lib/features/grove/episodes/tools/encrypt_tool.dart <input_json> <output_file>',
    );
    return;
  }

  final inputFile = File(args[0]);
  final outputFile = File(args[1]);

  if (!inputFile.existsSync()) {
    print('Input file not found: ${args[0]}');
    return;
  }

  final jsonString = inputFile.readAsStringSync();
  final encrypted = StoryEncryptionService.encrypt(jsonString);

  outputFile.writeAsStringSync(encrypted);
  print('Successfully encrypted ${args[0]} to ${args[1]}');
}
