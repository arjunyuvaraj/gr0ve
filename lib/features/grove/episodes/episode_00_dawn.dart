import 'package:gr0ve/features/grove/models/grove_models.dart';

List<Scene> buildEpisode00Dawn() {
  return [
    Scene(
      id: 'ep0_intro',
      lines: const [
        StoryMessage(
          'EPISODE 0: THE DAWN',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage('You wake on a branch of smooth, pale wood.'),
        StoryMessage(
          'The tree beneath you hums faintly — dying light trapped in bark.',
        ),
        StoryMessage('This is Dawn. And Dawn is fading.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep0_dawn_speaks',
    ),

    Scene(
      id: 'ep0_dawn_speaks',
      lines: const [
        StoryMessage(
          'Little bird. You feel it, don\'t you? The thinning air. This realm — my realm — exists between day and night. But the balance breaks. I cannot hold both anymore.',
          character: StoryCharacter.dawn,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I have one seed left. One chance. The gr0ve still stands, far from here. If you can reach it... if you can plant this seed... something of the threshold survives.',
          character: StoryCharacter.dawn,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You swallow the seed for safe-keeping. It rests heavy in your chest — warm, pulsing with fading light. It will not show in your pouch, but you carry its weight.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep0_dawn_branch',
      onEnter: (state) {
        if (!state.inventory.contains("Dawn's Seed")) {
          state.inventory.add("Dawn's Seed");
        }
      },
    ),

    Scene(
      id: 'ep0_dawn_branch',
      lines: const [
        StoryMessage(
          'And this — take my branch. It remembers the way. When you\'re lost, it will pull toward where you need to be.',
          character: StoryCharacter.dawn,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But listen carefully: The path is not straight. You will face orchards, lakes, canyons, clearings. Each will test you. Each will offer aid — or distraction.',
          character: StoryCharacter.dawn,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Trust the branch. Trust yourself. And whatever you do... reach the grove before this seed goes cold.',
          character: StoryCharacter.dawn,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Dawn\'s light flickers once — then dims to ash-gray.',
          isItalic: true,
        ),
        StoryMessage(
          '[Dawn\'s Branch obtained]\n[Dawn\'s Seed secured  |  STATUS: Warm — 100%]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep0_player_resolve',
      onEnter: (state) {
        if (!state.inventory.contains("Dawn's Branch")) {
          state.inventory.add("Dawn's Branch");
        }
      },
    ),

    Scene(
      id: 'ep0_player_resolve',
      lines: const [
        StoryMessage(
          'Before I fade, little bird... tell me. When you look at the horizon, what do you see?',
          character: StoryCharacter.dawn,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'I see a puzzle to be solved',
          nextScene: 'ep0_complete',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'I see others waiting for help',
          nextScene: 'ep0_complete',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'I see a distance to be crossed',
          nextScene: 'ep0_complete',
          statEffects: {'vitality': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'I see the beauty in the fading',
          nextScene: 'ep0_complete',
          statEffects: {'transience': 1},
        ),
      ],
    ),

    Scene(
      id: 'ep0_complete',
      lines: const [
        StoryMessage(
          'With nothing left holding you here, you launch into the air. The journey begins.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep0_stats',
    ),

    Scene(
      id: 'ep0_stats',
      lines: const [
        StoryMessage('EPISODE COMPLETE', kind: MessageKind.episodeHeader),
        StoryMessage(
          'To proceed, exit and select Episode 1 from the Chapter Menu.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.none,
    ),
  ];
}
