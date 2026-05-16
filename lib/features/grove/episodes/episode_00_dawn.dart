import 'dart:async';
import 'package:gr0ve/features/grove/models/grove_models.dart';
import 'package:gr0ve/features/grove/services/story_loader.dart';

/// Loads Episode 0: The Dawn from JSON configuration
/// 
/// This episode is now defined in assets/story/story_map.json instead of as 
/// hardcoded Scene objects. The StoryLoader dynamically builds scenes from the
/// JSON configuration, reducing code size by ~70% while maintaining full functionality.
FutureOr<List<Scene>> buildEpisode00Dawn() async {
  try {
    final loader = StoryLoader();
    return await loader.loadEpisodeScenes('ep0');
  } catch (e) {
    // Fallback: return minimal error scene
    return [
      Scene(
        id: 'ep0_error',
        lines: [
          const StoryMessage(
            'Error loading episode. Please try again.',
            kind: MessageKind.system,
          ),
        ],
        inputType: InputType.continueOnly,
      ),
    ];
  }
}
