import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/grove/models/grove_models.dart';

/// Loads story content from JSON and text files
/// Provides a caching layer to minimize memory usage
class StoryLoader {
  static final StoryLoader _instance = StoryLoader._internal();

  factory StoryLoader() => _instance;

  StoryLoader._internal();

  /// Cache: episode ID → list of scenes
  final Map<String, List<Scene>> _sceneCache = {};

  /// Cache: file path → text content
  final Map<String, String> _textCache = {};

  /// Cache: story map JSON
  Map<String, dynamic>? _storyMapCache;

  /// Loads the main story map configuration
  Future<Map<String, dynamic>> loadStoryMap() async {
    if (_storyMapCache != null) return _storyMapCache!;

    try {
      final jsonStr = await rootBundle.loadString('assets/story/story_map.json');
      _storyMapCache = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _storyMapCache!;
    } catch (e) {
      throw Exception('Failed to load story map: $e');
    }
  }

  /// Loads a text file from assets
  Future<String> loadText(String path) async {
    if (_textCache.containsKey(path)) {
      return _textCache[path]!;
    }

    try {
      final text = await rootBundle.loadString('assets/story/$path');
      _textCache[path] = text;
      return text;
    } catch (e) {
      throw Exception('Failed to load story text from $path: $e');
    }
  }

  /// Loads scenes for an episode from JSON definition
  /// Returns cached scenes if already loaded
  Future<List<Scene>> loadEpisodeScenes(String episodeId) async {
    if (_sceneCache.containsKey(episodeId)) {
      return _sceneCache[episodeId]!;
    }

    try {
      final storyMap = await loadStoryMap();
      final episodes = storyMap['episodes'] as Map<String, dynamic>?;

      if (episodes == null || !episodes.containsKey(episodeId)) {
        throw Exception('Episode $episodeId not found in story map');
      }

      final episodeData = episodes[episodeId] as Map<String, dynamic>;
      final scenes = await _buildScenesFromJson(episodeData);

      _sceneCache[episodeId] = scenes;
      return scenes;
    } catch (e) {
      throw Exception('Failed to load episode $episodeId: $e');
    }
  }

  /// Converts JSON episode definition to Scene objects
  Future<List<Scene>> _buildScenesFromJson(
      Map<String, dynamic> episodeData) async {
    final scenes = <Scene>[];
    final sceneIds = (episodeData['scenes'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList();

    if (sceneIds == null || sceneIds.isEmpty) {
      return scenes;
    }

    final storyMap = await loadStoryMap();
    final sceneDefinitions = storyMap['scenes'] as Map<String, dynamic>?;

    if (sceneDefinitions == null) {
      throw Exception('No scenes defined in story map');
    }

    for (final sceneId in sceneIds) {
      if (!sceneDefinitions.containsKey(sceneId)) {
        throw Exception('Scene $sceneId referenced but not defined');
      }

      final sceneData =
          sceneDefinitions[sceneId] as Map<String, dynamic>;
      final scene = await _buildSceneFromJson(sceneId, sceneData);
      scenes.add(scene);
    }

    return scenes;
  }

  /// Converts a single scene JSON definition to a Scene object
  Future<Scene> _buildSceneFromJson(
      String sceneId, Map<String, dynamic> sceneData) async {
    final contentPath = sceneData['content'] as String?;
    final lines = <StoryMessage>[];

    // Load narrative content if specified
    if (contentPath != null) {
      final text = await loadText(contentPath);
      lines.add(
        StoryMessage(
          text,
          kind: MessageKind.narrative,
        ),
      );
    }

    // Parse explicit lines if provided
    final explicitLines = sceneData['lines'] as List<dynamic>?;
    if (explicitLines != null) {
      for (final lineData in explicitLines) {
        if (lineData is Map<String, dynamic>) {
          lines.add(StoryMessage.fromJson(lineData));
        }
      }
    }

    // Parse choices
    final choicesData = sceneData['choices'] as List<dynamic>?;
    final choices = <SceneChoice>[];
    if (choicesData != null) {
      for (final choiceData in choicesData) {
        if (choiceData is Map<String, dynamic>) {
          choices.add(SceneChoice.fromJson(choiceData));
        }
      }
    }

    final inputTypeStr = sceneData['inputType'] as String? ?? 'none';
    final inputType = InputType.values.firstWhere(
      (e) => e.name == inputTypeStr,
      orElse: () => InputType.none,
    );

    final nextScene = sceneData['nextScene'] as String?;
    final waitSeconds = sceneData['waitDuration'] as int?;

    return Scene(
      id: sceneId,
      lines: lines,
      inputType: inputType,
      choices: choices,
      nextScene: nextScene,
      waitDuration:
          waitSeconds != null ? Duration(seconds: waitSeconds) : null,
    );
  }

  /// Clears all caches (useful for testing or memory management)
  void clearCache() {
    _sceneCache.clear();
    _textCache.clear();
    _storyMapCache = null;
  }

  /// Validates story map for common errors
  Future<List<String>> validateStoryMap() async {
    final errors = <String>[];

    try {
      final storyMap = await loadStoryMap();

      final episodes =
          storyMap['episodes'] as Map<String, dynamic>?;
      final sceneDefinitions =
          storyMap['scenes'] as Map<String, dynamic>?;

      if (episodes == null) {
        errors.add('No episodes defined in story map');
        return errors;
      }

      if (sceneDefinitions == null) {
        errors.add('No scenes defined in story map');
        return errors;
      }

      // Check each episode references valid scenes
      for (final entry in episodes.entries) {
        final episodeId = entry.key;
        final episodeData = entry.value as Map<String, dynamic>?;

        if (episodeData == null) {
          errors.add('Episode $episodeId has null data');
          continue;
        }

        final sceneIds = episodeData['scenes'] as List<dynamic>?;
        if (sceneIds == null || sceneIds.isEmpty) {
          errors.add('Episode $episodeId has no scenes');
          continue;
        }

        for (final sceneId in sceneIds) {
          if (!sceneDefinitions.containsKey(sceneId)) {
            errors.add('Episode $episodeId references undefined scene $sceneId');
          }
        }
      }

      // Check for circular references (simplified check)
      final visited = <String>{};
      final recStack = <String>{};

      for (final sceneId in sceneDefinitions.keys) {
        if (!visited.contains(sceneId)) {
          _checkCircularRef(
            sceneId,
            sceneDefinitions,
            visited,
            recStack,
            errors,
          );
        }
      }
    } catch (e) {
      errors.add('Validation error: $e');
    }

    return errors;
  }

  /// Helper for circular reference detection
  void _checkCircularRef(
    String sceneId,
    Map<String, dynamic> sceneDefinitions,
    Set<String> visited,
    Set<String> recStack,
    List<String> errors,
  ) {
    visited.add(sceneId);
    recStack.add(sceneId);

    final sceneData =
        sceneDefinitions[sceneId] as Map<String, dynamic>?;
    if (sceneData == null) return;

    final nextScene = sceneData['nextScene'] as String?;
    if (nextScene != null) {
      if (!visited.contains(nextScene)) {
        _checkCircularRef(nextScene, sceneDefinitions, visited, recStack, errors);
      } else if (recStack.contains(nextScene)) {
        errors.add('Circular reference detected: $sceneId -> $nextScene');
      }
    }

    final choices = sceneData['choices'] as List<dynamic>?;
    if (choices != null) {
      for (final choiceData in choices) {
        if (choiceData is Map<String, dynamic>) {
          final nextSceneFromChoice = choiceData['nextScene'] as String?;
          if (nextSceneFromChoice != null && !visited.contains(nextSceneFromChoice)) {
            _checkCircularRef(
              nextSceneFromChoice,
              sceneDefinitions,
              visited,
              recStack,
              errors,
            );
          }
        }
      }
    }

    recStack.remove(sceneId);
  }
}
