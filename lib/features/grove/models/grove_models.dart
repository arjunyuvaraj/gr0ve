import 'package:flutter/material.dart';
import 'package:gr0ve/features/grove/grove_progress_service.dart';

// ─────────────────────────────────────────────────────────────
// STORY CHARACTERS
// ─────────────────────────────────────────────────────────────

enum StoryCharacter {
  narrator,
  dawn,
  newton,
  darwin,
  newtonsTree,
  darwinsTree,
  redSparrow,
  orangeSparrow,
  wall,
  system,
  player,
  graySparrow,
  salix,
  salixBaby,
  abiesBaby,
  thicketSheep,
  woolberrySheep,
  bluebellSheep,
  cediteBaby,
  abies,
  cedite,
  ash,
  london,
  squashy,
}

extension StoryCharacterX on StoryCharacter {
  String get displayName => switch (this) {
        StoryCharacter.narrator => 'Narrator',
        StoryCharacter.dawn => 'Dawn',
        StoryCharacter.newton => 'Newton',
        StoryCharacter.darwin => 'Darwin',
        StoryCharacter.newtonsTree => 'Newton',
        StoryCharacter.darwinsTree => 'Darwin',
        StoryCharacter.redSparrow => 'Red Sparrow',
        StoryCharacter.orangeSparrow => 'Orange Sparrow',
        StoryCharacter.wall => 'Wall',
        StoryCharacter.system => 'System',
        StoryCharacter.player => 'Green Sparrow',
        StoryCharacter.graySparrow => 'Gray Sparrow',
        StoryCharacter.salix => 'Salix',
        StoryCharacter.salixBaby => 'Young Salix',
        StoryCharacter.abiesBaby => 'Young Abies',
        StoryCharacter.thicketSheep => 'Thicket Sheep',
        StoryCharacter.woolberrySheep => 'Woolberry Sheep',
        StoryCharacter.bluebellSheep => 'Bluebell Sheep',
        StoryCharacter.cediteBaby => 'Young Cedite',
        StoryCharacter.abies => 'Abies',
        StoryCharacter.cedite => 'Cedite',
        StoryCharacter.ash => 'Ash',
        StoryCharacter.london => 'London',
        StoryCharacter.squashy => 'Squashy',
      };

  String avatarAsset(Brightness brightness) {
    final mode = brightness == Brightness.dark ? 'dark' : 'light';
    return switch (this) {
      StoryCharacter.dawn => 'assets/story/characters/ep0/dawn_$mode.png',
      StoryCharacter.newton ||
      StoryCharacter.newtonsTree ||
      StoryCharacter.wall =>
        'assets/story/characters/ep1/newton_$mode.png',
      StoryCharacter.darwin ||
      StoryCharacter.darwinsTree =>
        'assets/story/characters/ep1/darwin_$mode.png',
      StoryCharacter.redSparrow =>
        'assets/story/characters/ep1/red_sparrow_$mode.png',
      StoryCharacter.orangeSparrow =>
        'assets/story/characters/ep1/orange_sparrow_$mode.png',
      StoryCharacter.player => 'assets/story/characters/sparrow_$mode.png',
      StoryCharacter.graySparrow => 'assets/story/characters/ep1/gray_sparrow_$mode.png',
      StoryCharacter.salix => 'assets/story/characters/ep2/salix_$mode.png',
      StoryCharacter.salixBaby => 'assets/story/characters/ep2/baby/salix_baby_$mode.png',
      StoryCharacter.abiesBaby => 'assets/story/characters/ep2/baby/abies_baby_$mode.png',
      StoryCharacter.thicketSheep => 'assets/story/characters/ep2/sheep/thicket_sheep_$mode.png',
      StoryCharacter.woolberrySheep => 'assets/story/characters/ep2/sheep/woolberry_sheep_$mode.png',
      StoryCharacter.bluebellSheep => 'assets/story/characters/ep2/sheep/bluebell_sheep_$mode.png',
      StoryCharacter.cediteBaby => 'assets/story/characters/ep2/baby/cedite_baby_$mode.png',
      StoryCharacter.abies => 'assets/story/characters/abies_$mode.png',
      StoryCharacter.cedite => 'assets/story/characters/cedite_$mode.png',
      StoryCharacter.ash => 'assets/story/characters/ash_$mode.png',
      StoryCharacter.london => 'assets/story/characters/ep3/london_$mode.png',
      StoryCharacter.squashy => 'assets/story/characters/ep3/squashy_$mode.png',
      _ => 'assets/story/inventory/branch_$mode.png',
    };
  }

  Color accent(Brightness brightness) => switch (this) {
    StoryCharacter.dawn => brightness == Brightness.dark
        ? const Color(0xFFF1C40F)
        : const Color(0xFFD4A912),
    StoryCharacter.newton ||
    StoryCharacter.newtonsTree ||
    StoryCharacter.wall =>
      brightness == Brightness.dark
          ? const Color(0xFFE55B5B)
          : const Color(0xFFC43D3D),
    StoryCharacter.darwin ||
    StoryCharacter.darwinsTree =>
      brightness == Brightness.dark
          ? const Color(0xFFFF9F43)
          : const Color(0xFFD47A1A),
    StoryCharacter.system => brightness == Brightness.dark
        ? const Color(0xFF7BA3C7)
        : const Color(0xFF3C7AB0),
    StoryCharacter.player => brightness == Brightness.dark
        ? const Color(0xFF5AE6A0)
        : const Color(0xFF1F8A5F),
    StoryCharacter.graySparrow => brightness == Brightness.dark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF808080),
    StoryCharacter.salix ||
    StoryCharacter.salixBaby => brightness == Brightness.dark
        ? const Color(0xFF0D47A1) // Darker blue for dark mode
        : const Color(0xFF002171), // Even darker for light mode
    StoryCharacter.abies ||
    StoryCharacter.abiesBaby => brightness == Brightness.dark
        ? const Color(0xFF00C8FF) // Matches CounselorPersona.primaryDark
        : const Color(0xFF00C8FF), // Matches CounselorPersona.primaryLight
    StoryCharacter.cedite ||
    StoryCharacter.cediteBaby => brightness == Brightness.dark
        ? const Color(0xFF9B59B6) // Vibrant Purple
        : const Color(0xFF8E44AD), // Deeper Purple
    StoryCharacter.ash => brightness == Brightness.dark
        ? const Color(0xFFE55B5B) // Matches CounselorPersona.primaryDark
        : const Color(0xFFC43D3D), // Matches CounselorPersona.primaryLight
    StoryCharacter.london => brightness == Brightness.dark
        ? const Color(0xFF4A7C44)
        : const Color(0xFF2D5A27),
    StoryCharacter.squashy => brightness == Brightness.dark
        ? const Color(0xFFF9A825)
        : const Color(0xFFF57F17),
    StoryCharacter.thicketSheep => brightness == Brightness.dark
        ? const Color(0xFFA1887F)
        : const Color(0xFF795548),
    StoryCharacter.woolberrySheep => brightness == Brightness.dark
        ? const Color(0xFFBA68C8)
        : const Color(0xFF8E24AA),
    StoryCharacter.bluebellSheep => brightness == Brightness.dark
        ? const Color(0xFF7986CB)
        : const Color(0xFF3949AB),
    _ => brightness == Brightness.dark
        ? const Color(0xFFD0D4D8)
        : const Color(0xFF4A5568),
  };

  bool get hasAvatar => this != StoryCharacter.narrator &&
      this != StoryCharacter.system;
}

// ─────────────────────────────────────────────────────────────
// MESSAGES & CONTEXT
// ─────────────────────────────────────────────────────────────

enum MessageKind {
  dialogue,
  narrative,
  system,
  episodeHeader,
  playerChoice,
  divider,
}

class StoryMessage {
  final String text;
  final StoryCharacter character;
  final MessageKind kind;
  final bool isItalic;
  final bool isBold;

  const StoryMessage(
    this.text, {
    this.character = StoryCharacter.narrator,
    this.kind = MessageKind.narrative,
    this.isItalic = false,
    this.isBold = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'character': character.name,
        'kind': kind.name,
        'isItalic': isItalic,
        'isBold': isBold,
      };

  factory StoryMessage.fromJson(Map<String, dynamic> json) {
    return StoryMessage(
      json['text'] as String,
      character: StoryCharacter.values.firstWhere(
        (e) => e.name == json['character'],
        orElse: () => StoryCharacter.narrator,
      ),
      kind: MessageKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => MessageKind.narrative,
      ),
      isItalic: json['isItalic'] as bool? ?? false,
      isBold: json['isBold'] as bool? ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INTERACTIVITY
// ─────────────────────────────────────────────────────────────

enum InputType { choices, freeText, number, continueOnly, none }

class SceneChoice {
  final String label;
  final String letter;
  final String nextScene;
  final Map<String, int> statEffects;
  final List<String> addItems;
  final int warmthChange;
  final String? setPath;
  final Duration? waitDuration;

  const SceneChoice({
    required this.label,
    required this.letter,
    required this.nextScene,
    this.statEffects = const {},
    this.addItems = const [],
    this.warmthChange = 0,
    this.setPath,
    this.waitDuration,
  });
}

typedef FreeTextHandler = String? Function(String input, GroveGameState state);

class Scene {
  final String id;
  final List<StoryMessage> lines;
  final InputType inputType;
  final List<SceneChoice> choices;
  final FreeTextHandler? onFreeText;
  final String? nextScene;
  final Duration? waitDuration;
  final void Function(GroveGameState state)? onEnter;

  const Scene({
    required this.id,
    required this.lines,
    this.inputType = InputType.none,
    this.choices = const [],
    this.onFreeText,
    this.nextScene,
    this.waitDuration,
    this.onEnter,
  });
}

class TravelNarrative {
  static const List<String> appleQuotes = [
    "The air becomes colder. The wind seems to hum in a perfect, steady frequency.",
    "The horizon is a perfectly level boundary. You fly toward it in rhythmic sync.",
    "The clouds above have begun to form into neat, white clusters. Not a single wisp is out of place.",
    "Below, silver threads of perfectly straight paths begin to cut through the greenery.",
    "The air temperature drops. It doesn't feel like weather; it feels calculated.",
    "A group of sparrows passes by in a precise V-formation, whistling a single, pure note.",
    "The apple trees appear below, identical in height and spaced exactly ten feet apart.",
    "The Branch pulses with a steady, rhythmic tap against your claw. 1-2, 1-2.",
    "You pass a shimmering sign: 'RESTRICTED SPACE — GEOMETRY IN PROGRESS'.",
    "The white gate looms ahead, a monumental structure of marble and silver.",
  ];

  static const List<String> orangeQuotes = [
    "The air is thick with the scent of blossoming citrus. It feels electric.",
    "The humidity rises, smelling of sun-warmed earth and ripe, heavy fruit.",
    "The canopy below is a chaotic riot of orange, green, and deep purple vines.",
    "Massive orange shapes shift through the leaves below like underwater giants.",
    "The wind is unpredictable, carrying sudden bursts of warmth that prickle your feathers.",
    "A swarm of neon hummingbirds zips past, chirping in a dozen different keys.",
    "The smell of orange blossoms is overwhelming now, a physical weight in the air.",
    "The Branch is flickering wildly, trying to keep up with the vibrant energy below.",
    "A booming sound echoes—like heavy fruit falling into a deep pool of water.",
    "The vibrant orange rooftops of the center peeking out from under massive leaves.",
  ];

  static String getQuote(String? path, Duration remaining) {
    int index = 9 - (remaining.inMinutes / 30).floor().clamp(0, 9);
    if (path == 'apple') return appleQuotes[index];
    if (path == 'orange') return orangeQuotes[index];
    return "Traveling toward your next destination...";
  }
}

// ─────────────────────────────────────────────────────────────
// EPISODE STRUCTURE
// ─────────────────────────────────────────────────────────────

class Episode {
  final String id;
  final int number;
  final String title;
  final String description;
  final List<Scene> Function() buildScenes;
  final bool isComingSoon;

  const Episode({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.buildScenes,
    this.isComingSoon = false,
  });
}
