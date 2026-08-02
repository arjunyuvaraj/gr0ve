import 'package:gr0ve/features/grove/models/grove_models.dart';

List<Scene> buildEpisode04OpenShore() {
  return [
    // ─────────────────────────────────────────────
    // OPENING — THE SHORE
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_intro',
      lines: const [
        StoryMessage(
          'EPISODE 4: THE OPEN SHORE',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage(
          'You clear the last of the tree line, and the world opens.',
        ),
        StoryMessage(
          'Just like that. One wingbeat you are in green shadow, the next you are in blinding, unfiltered, completely indifferent sunlight. The kind of sun that does not care at all about what you\'ve been through.',
        ),
        StoryMessage('You land on the sand.'),
        StoryMessage(
          'The sand is hot. Not "warm" hot. Not "summer afternoon" hot. The kind of hot that communicates something personal about the sun\'s feelings toward you. Your talons adjust. You hop from foot to foot once, twice, then give up and stand very still with dignity.',
        ),
        StoryMessage(
          'Okay. Okay. This is fine. I have survived a misty lake of crystallized grief, a rainforest that looped in circles and also contained a philosopher, and a snake who gave me relationship advice. I can handle hot sand.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The wind picks up off the ocean. Cool and full of salt and completely unbothered by your situation.',
        ),
        StoryMessage(
          'You change your assessment. The heat is actually tolerable with the wind. More than tolerable, even. After the suffocating wet warmth of the rainforest, this open brightness feels like a reward you didn\'t know you\'d earned.',
        ),
        StoryMessage(
          'You stand at the edge of a very large ocean and look at it.',
        ),
        StoryMessage(
          'It looks back at you without expression. Oceans are like that.',
        ),
        StoryMessage(
          'You have been flying for a long time.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'You look down at what you\'re carrying. Four things. They have been with you long enough that their weight feels like part of you — the way you no longer notice the weight of your own wings.',
        ),
        StoryMessage(
          'Dawn\'s Branch: heavier than it was in the rainforest, the wood still holding moisture. In this flat coastal light you can see the grain clearly.',
        ),
        StoryMessage(
          'The Flask of Tears: warm against your side, the luminous blue liquid inside still pulsing in its slow, steady rhythm. Salix\'s gift. Four lifetimes of memory, contained.',
        ),
        StoryMessage(
          'The Warming Pouch: woven by Squashy. Inside it, Dawn\'s Seed glows red-gold. The color of late afternoon. The color of something that has not given up.',
        ),
        StoryMessage(
          'London\'s Vial (Mossy Residue): small, circular, and warm to the touch. Inside, the luminous rainforest liquid still pulses with the heat of the tangled forest, waiting for the right moment.',
        ),
        StoryMessage(
          'You stand in the sun with your four things and stare at the ocean you have no idea how to cross.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_gull_prank',
      waitDuration: const Duration(hours: 1),
      onEnter: (state) {
        state.seedWarmth = 100;
        // Seed warmth is locked to 100 thanks to the Warming Pouch!
      },
    ),

    // ─────────────────────────────────────────────
    // THE GULL PRANK
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_gull_prank',
      lines: const [
        StoryMessage('Suddenly, a shadow sweeps over the sand.'),
        StoryMessage('Before you can react, a massive seagull swoops down. It doesn\'t just graze you—it fully body-checks you into the hot sand.'),
        StoryMessage('Hey! Watch it!', character: StoryCharacter.player, kind: MessageKind.dialogue),
        StoryMessage('The gull lands a few feet away. It stares at you with pale, unblinking eyes, a half-eaten crab shell hanging out of its beak.'),
        StoryMessage('It swallows the shell whole. Then, without breaking eye contact, it screeches something utterly incomprehensible and kicks sand violently into your face.'),
        StoryMessage('You cough, flapping wildly. In the confusion, you feel something shift. The physical toll of the journey—the exhaustion, the disorientation, and the pure disrespect of this bird—finally catches up to you in a rushing wave.'),
        StoryMessage('When the sand clears, the gull is gone, but the damage is done. You feel drained. Deeply, fundamentally drained.'),
        StoryMessage('[-3 to All Stats]', kind: MessageKind.system, isBold: true, isItalic: true),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Stand up and dust yourself off.',
          nextScene: 'ep4_karl_first',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Yell at the empty sky.',
          nextScene: 'ep4_karl_first',
          statEffects: {'vitality': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Check your belongings.',
          nextScene: 'ep4_karl_first',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'Laugh. What else can you do?',
          nextScene: 'ep4_karl_first',
          statEffects: {'transience': -1},
        ),
      ],
      onEnter: (state) {
        state.stability = (state.stability - 3).clamp(0, 5);
        state.connectivity = (state.connectivity - 3).clamp(0, 5);
        state.vitality = (state.vitality - 3).clamp(0, 5);
        state.transience = (state.transience - 3).clamp(0, 5);
      },
    ),

    // ─────────────────────────────────────────────
    // KARL — FIRST APPROACH
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_karl_first',
      lines: const [
        StoryMessage('He comes sideways.'),
        StoryMessage(
          'That is the first thing you notice. Not his shell, not his eyes — the angle of his approach. He moves the way something moves when it has given up on the concept of forward entirely and has made peace with it.',
        ),
        StoryMessage(
          'He is a crab. Red-brown, the color of old wood left too long in the rain. His eyes sit on stalks that angle slightly downward, giving him the permanent expression of a creature who expected this outcome and remains unsurprised.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'He stops beside you without acknowledging he\'s stopped. He faces the ocean. You face the ocean. For a moment you are simply two beings on a beach, looking at water.',
        ),
        StoryMessage(
          '...you\'ve got a glow.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He says it like a minor grievance.',
          character: StoryCharacter.karl,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 30),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'The seed. It\'s in the pouch.',
          nextScene: 'ep4_karl_first_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'I\'ve been told that before. It hasn\'t helped much.',
          nextScene: 'ep4_karl_first_b',
          statEffects: {'stability': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Hello to you too.',
          nextScene: 'ep4_karl_first_c',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[Say nothing. Keep watching the ocean.]',
          nextScene: 'ep4_karl_first_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_karl_first_a',
      lines: const [
        StoryMessage(
          'Karl\'s eyes swivel toward the pouch. His body doesn\'t move at all.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'A seed. \'Course it is. Always something.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He clicks his claws once — a small sound, like punctuation.',
          character: StoryCharacter.karl,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_vial',
    ),

    Scene(
      id: 'ep4_karl_first_b',
      lines: const [
        StoryMessage('Karl considers this.', character: StoryCharacter.karl),
        StoryMessage(
          'No. Glowing rarely does. Makes you visible. Visibility is... a mixed outcome.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_vial',
    ),

    Scene(
      id: 'ep4_karl_first_c',
      lines: const [
        StoryMessage(
          'Hello.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause.'),
        StoryMessage(
          'You\'ve still got a glow.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_vial',
    ),

    Scene(
      id: 'ep4_karl_first_d',
      lines: const [
        StoryMessage(
          'Karl doesn\'t mind. He watches the ocean beside you for a long time. A very comfortable silence, coming from him — the silence of someone who has stood on this beach enough times that silence is simply the default state.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'Heading across, I assume.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_vial',
    ),

    Scene(
      id: 'ep4_karl_vial',
      lines: const [
        StoryMessage(
          'And that vial.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'His eyes drop from your chest to your talons.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'London\'s work. Only she would try to package the humidity of a forest into a scrap of glass.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He shifts his posture, scuttling a fraction of an inch closer. The heat radiating off his shell is intense, baked in by hours of shore sun.',
        ),
        StoryMessage(
          'Give it here. Just for a minute.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Hand him the vial.',
          nextScene: 'ep4_karl_vial_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: '"Why? What are you going to do with it?"',
          nextScene: 'ep4_karl_vial_b',
          statEffects: {'stability': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: '"It\'s London\'s gift. I should keep it safe."',
          nextScene: 'ep4_karl_vial_c',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[Keep holding it. Don\'t move.]',
          nextScene: 'ep4_karl_vial_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_karl_vial_a',
      lines: const [
        StoryMessage(
          'You place the circular vial in his large claw. It fits neatly against the flat, warm surface of his shell. He doesn\'t shake it or peer inside; he simply holds it against his carapace, letting the heat of the beach-baked stone transfer into the glass.',
        ),
        StoryMessage(
          'It needs the shore. A forest is warm, but it\'s wet-warm. Slow. The ocean requires something sharper.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '[London\'s Vial warmed | The rainforest liquid glows brighter, moving closer to activation.]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_name',
    ),

    Scene(
      id: 'ep4_karl_vial_b',
      lines: const [
        StoryMessage(
          'Because it\'s cold. Or rather, it\'s not as warm as it should be. The forest is a green blanket, but the shore is an open oven. It needs the heat if you want it to survive the ice.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He extends a claw, patient but firm.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'Okay. Just be careful.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You hand it to him. He holds it against his warm shell. The liquid inside responds, the pulse quickening, shifting to a brighter gold.',
        ),
        StoryMessage(
          '[London\'s Vial warmed | The rainforest liquid glows brighter, moving closer to activation.]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_name',
    ),

    Scene(
      id: 'ep4_karl_vial_c',
      lines: const [
        StoryMessage(
          'I\'m a crab. I move sideways and eat decaying kelp. I have no use for a bottle of warm forest air.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He clicks.', character: StoryCharacter.karl),
        StoryMessage(
          'But if you want it to freeze on the crossing, keep holding it. If you want it to last, let the sand do its work.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You hesitate, then set the vial on his broad, flat carapace. He sits perfectly still, letting the heat from his shell warm the glass. The liquid inside begins to pulse with a quicker, golden light.',
        ),
        StoryMessage(
          '[London\'s Vial warmed | The rainforest liquid glows brighter, moving closer to activation.]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_name',
    ),

    Scene(
      id: 'ep4_karl_vial_d',
      lines: const [
        StoryMessage(
          'Karl waits. Then he reaches out with his large, sun-baked claw, not touching you, but hovering just close enough that the heat from his shell radiates onto the glass.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'Stubborn. London likes that. I find it exhausting.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Even without direct contact, the heat radiating from him is enough. The circular vial warms, and the liquid inside begins to glow a brighter, steadier amber-gold.',
        ),
        StoryMessage(
          '[London\'s Vial warmed | The rainforest liquid glows brighter, moving closer to activation.]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_name',
    ),

    Scene(
      id: 'ep4_karl_name',
      lines: const [
        StoryMessage(
          'I\'m Karl.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He doesn\'t ask your name. This is not rudeness. It is simply that Karl has learned names come up when they\'re needed and not a moment before.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'I live here. On this beach. Have for a long time.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He says "a long time" the way someone says it when they mean something geological.',
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 15),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Do you like it? Living here?',
          nextScene: 'ep4_karl_name_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Are you happy here?',
          nextScene: 'ep4_karl_name_b',
          statEffects: {'transience': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'You don\'t seem very... happy.',
          nextScene: 'ep4_karl_name_c',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'I met someone who knows you. Salix.',
          nextScene: 'ep4_karl_name_d',
          statEffects: {'connectivity': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_karl_name_a',
      lines: const [
        StoryMessage(
          'Like. That\'s a word.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He clicks once.', character: StoryCharacter.karl),
        StoryMessage(
          'The beach is consistent. The ocean doesn\'t ask anything of me. The sand is hot, which I find... honest.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_directions',
    ),

    Scene(
      id: 'ep4_karl_name_b',
      lines: const [
        StoryMessage('A very long pause. The wind moves between you.'),
        StoryMessage(
          'That\'s a complicated question for a Tuesday.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Is it Tuesday?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I don\'t know. I just wanted it to sound like a reasonable objection.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_directions',
    ),

    Scene(
      id: 'ep4_karl_name_c',
      lines: const [
        StoryMessage(
          'I\'m not. But I appreciate you saying it plainly. Most people skirt around it.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He looks at you.', character: StoryCharacter.karl),
        StoryMessage(
          'You\'re direct. That\'s something.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_directions',
    ),

    Scene(
      id: 'ep4_karl_name_d',
      lines: const [
        StoryMessage(
          'Karl\'s eyes shift. Something in his posture changes — not much, but something.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'Salix. Yes.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause.'),
        StoryMessage(
          'Salix told me about Abies. The frozen one. He passes messages through travelers when he can. Trees can\'t send letters — they have to wait for someone to walk by and agree to carry the words.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I agree to carry things more than most people. I have the time.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_directions',
    ),

    // ─────────────────────────────────────────────
    // KARL — THE DIRECTIONS
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_karl_directions',
      lines: const [
        StoryMessage(
          'Eventually — not because Karl rushes, but because Karl gets there when he gets there — he tells you what he knows.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'To reach the gr0ve — the actual one, not the version people describe to make themselves feel better — you must fly far from here. North and then further north. There is a small island.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He pauses in a way that suggests he is choosing words with some care.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'I can\'t promise that\'s where the gr0ve is. Few have seen it. I\'m not one of them.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'However. I believe Abies is frozen there. On ice, north of the crossing. Salix told me. He said it years ago. He\'s still sure.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You think about this. Salix weeping beside a lake that cracked the earth open. The word "friend" sitting strangely in Karl\'s voice — like a word he doesn\'t use often and handles carefully when he does.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 45),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'You and Salix are friends? Have you ever actually met?',
          nextScene: 'ep4_karl_dir_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'I\'ve already spoken with Salix. And London, and Squashy.',
          nextScene: 'ep4_karl_dir_b',
          statEffects: {'stability': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'How do I cross the water? My wings aren\'t—',
          nextScene: 'ep4_karl_dir_c',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'You said \'however.\' Like you\'re building to something.',
          nextScene: 'ep4_karl_dir_d',
          statEffects: {'stability': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_karl_dir_a',
      lines: const [
        StoryMessage(
          'No. He doesn\'t move. I do, but only sideways, and never toward anything on purpose.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He looks at the ocean.', character: StoryCharacter.karl),
        StoryMessage(
          'We pass messages through travelers. It\'s an inefficient system. But it\'s the only one we have.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A beat.'),
        StoryMessage(
          'He\'s good. For what it\'s worth. He carries a lot of grief and he still passes it on accurately, without distorting it. That\'s rare.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_parting',
    ),

    Scene(
      id: 'ep4_karl_dir_b',
      lines: const [
        StoryMessage(
          'Karl\'s eyes move to look at you directly. Both of them. This, you realize, is the crab equivalent of turning to face someone fully.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'You talked to London.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Not a question.'),
        StoryMessage(
          'And you kept moving afterward. Interesting. She has a way of making travelers feel they should stay and think for a long time.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He clicks.', character: StoryCharacter.karl),
        StoryMessage(
          'I\'d recognize one of Squashy\'s pouches anywhere. And the snake gave you the pouch.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'How do you know about the pouch?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Squashy\'s made four of them that I know of. She only gives them to birds who\'ve already gotten here.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause.'),
        StoryMessage(
          'You\'re doing well. Better than you look.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_parting',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep4_karl_dir_c',
      lines: const [
        StoryMessage(
          'Karl\'s eyes settle on you with the patience of someone who has answered this question in the form of pointing, indirectly, many times before.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'The gulls will meet you at the tree. They know the crossing. You\'ll go together.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A beat.'),
        StoryMessage(
          'You\'ve made it this far on wings you didn\'t trust. The ocean is long but it is crossable. The atoll is real.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_parting',
    ),

    Scene(
      id: 'ep4_karl_dir_d',
      lines: const [
        StoryMessage(
          'The ghost of something passes over Karl\'s face. Not quite a smile. More like the idea of one, observed from a distance.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'However: there is a crab who lives here who knows people who have seen it. And he is talking to you now. Make of that what you will.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Also there is a pink tree down the beach. Go talk to the pink tree. And the gulls.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_karl_parting',
    ),

    // ─────────────────────────────────────────────
    // KARL — PARTING
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_karl_parting',
      lines: const [
        StoryMessage(
          'At night, seven orange fish circle the deep place below it. Never six. Never eight. Seven. They\'ve been doing it longer than I\'ve been alive.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Karl says this like a weather report.'),
        StoryMessage(
          'If you see them, do not take it personally.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He says this as if it is simply the last fact you needed and now the conversation is complete.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'Go on then. The gulls are louder than I am and considerably better at the water.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He turns sideways again, exactly as he came.'),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 10),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Thank him properly.',
          nextScene: 'ep4_karl_parting_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Will you be okay? Here. Alone.',
          nextScene: 'ep4_karl_parting_b',
          statEffects: {'vitality': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'What do you do when there is no one to talk to?',
          nextScene: 'ep4_karl_parting_c',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'Wish the beach good luck with him.',
          nextScene: 'ep4_pink_tree_sight',
          statEffects: {'stability': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_karl_parting_a',
      lines: const [
        StoryMessage(
          'Karl is already facing away. He stills for just a moment.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'Go on.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It is not nothing. It is, in Karl, the most it can be.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_pink_tree_sight',
    ),

    Scene(
      id: 'ep4_karl_parting_b',
      lines: const [
        StoryMessage('A long pause.', character: StoryCharacter.karl),
        StoryMessage(
          'I\'ve been okay on this beach for a very long time.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That\'s not a yes.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'No.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Karl agrees with this without apology.'),
        StoryMessage(
          'But it\'s accurate.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_pink_tree_sight',
    ),

    Scene(
      id: 'ep4_karl_parting_c',
      lines: const [
        StoryMessage(
          'Karl is quiet for long enough that you think he might not answer.',
          character: StoryCharacter.karl,
        ),
        StoryMessage(
          'I watch the water. I wait for the next person who comes sideways out of the tree line.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He clicks once.', character: StoryCharacter.karl),
        StoryMessage(
          'There is always a next person. Eventually.',
          character: StoryCharacter.karl,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_pink_tree_sight',
    ),

    // ─────────────────────────────────────────────
    // THE PINK TREE — FIRST SIGHT
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_pink_tree_sight',
      lines: const [
        StoryMessage(
          'You turn back toward the water, and that is when you see it.',
        ),
        StoryMessage(
          'A pink palm tree. Not pink in the light. Pink by choice. Pink all the way through.',
        ),
        StoryMessage(
          'Three seagulls are playing at its feet like the tree is the most ordinary thing in the world.',
        ),
        StoryMessage('It is not ordinary at all.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_gulls_intro',
      waitDuration: const Duration(minutes: 15),
    ),

    // ─────────────────────────────────────────────
    // THE GULLS — INTRODUCTION
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_gulls_intro',
      lines: const [
        StoryMessage(
          'Hey! Birdie! Wanna play?',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The bright one is Sunny. The steadier one beside him is Carlos. The one who speaks least but sees the most is Lemon.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 10),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Run over and join them immediately.',
          nextScene: 'ep4_shore_games',
          statEffects: {'vitality': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Walk over carefully and let them see you coming.',
          nextScene: 'ep4_shore_games',
          statEffects: {'stability': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Call out about the tree being pink.',
          nextScene: 'ep4_shore_games',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'Stand there for one more moment and process it.',
          nextScene: 'ep4_shore_games',
          statEffects: {'transience': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_shore_games',
      lines: const [
        StoryMessage(
          'The gulls do not really wait for an answer before they start moving again.',
        ),
        StoryMessage(
          'Sunny sprints toward the breaking edge of the water, then doubles back at the last second, laughing at his own feet.',
          character: StoryCharacter.sunny,
        ),
        StoryMessage(
          'Carlos walks the line where wet sand turns to dry, studying the shell fragments as if they might reveal a theorem.',
          character: StoryCharacter.carlos,
        ),
        StoryMessage(
          'Lemon watches all of it from under the pink fronds, and somehow that makes it feel organized.',
          character: StoryCharacter.lemon,
        ),
        StoryMessage(
          'For a little while, the beach is just a beach. Salt, sun, gulls, and a tree that refuses to be ordinary.',
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 20),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Join Sunny and race the edge of the surf.',
          nextScene: 'ep4_shore_a',
          statEffects: {'vitality': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Walk beside Carlos and listen to what he notices.',
          nextScene: 'ep4_shore_b',
          statEffects: {'stability': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Stand with Lemon and ask about the route ahead.',
          nextScene: 'ep4_shore_c',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'Sit under the tree and let the sun do the talking.',
          nextScene: 'ep4_shore_d',
          statEffects: {'transience': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_shore_a',
      lines: const [
        StoryMessage(
          'Sunny lets out a sound that is mostly joy and only slightly a word.',
          character: StoryCharacter.sunny,
        ),
        StoryMessage(
          'You run. The sand gives under your talons. The surf grabs at your feet and pulls back. Sunny keeps almost letting it catch him and then not, which turns out to be a game with no rules and no loser and that is the best kind.',
          character: StoryCharacter.sunny,
        ),
        StoryMessage(
          'You are breathing hard when you stop. The sun is warm. Something in your chest is slightly less knotted than it was.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_loulo_intro',
      onEnter: (state) {
        state.seedWarmth = (state.seedWarmth + 3).clamp(0, 100);
      },
    ),

    Scene(
      id: 'ep4_shore_b',
      lines: const [
        StoryMessage(
          'Carlos does not narrate. He just moves, and lets you follow.',
          character: StoryCharacter.carlos,
        ),
        StoryMessage(
          'He points a wing at a particular shell: spiral, cream-colored, worn smooth from one side only.',
          character: StoryCharacter.carlos,
        ),
        StoryMessage(
          'It\'s been here a long time.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He says this without looking away from the shell.'),
        StoryMessage(
          'But it still holds its shape. Things that hold their shape in the ocean are doing something right.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('You walk. You look at what he looks at. It is enough.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_loulo_intro',
      onEnter: (state) {
        state.stability -= 1;
      },
    ),

    Scene(
      id: 'ep4_shore_c',
      lines: const [
        StoryMessage(
          'Lemon is already thinking in angles. She gives you the first part of the route like she is reciting something she memorized a long time ago but still checks for accuracy each time.',
          character: StoryCharacter.lemon,
        ),
        StoryMessage(
          'First leg: north-northeast. Wind helps if you don\'t fight it. You\'ll see the atoll before you feel like you\'re close to anything. That\'s normal.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She doesn\'t say things to be reassuring.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Carlos notes this from behind you.'),
        StoryMessage(
          'No.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Lemon agrees.'),
        StoryMessage(
          'But it\'s still true.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_loulo_intro',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep4_shore_d',
      lines: const [
        StoryMessage(
          'You sit under the fronds and do not think about anything in particular.',
        ),
        StoryMessage(
          'The tree makes a sound like wind moving through paper. The gulls are loud in the distance. The ocean is constant. The sun, for the first time in what feels like a very long journey, is simply warm.',
        ),
        StoryMessage(
          'You will need this. Whatever you are accumulating here — rest, warmth, the shape of an ordinary afternoon — you will need it for the crossing.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_loulo_intro',
      onEnter: (state) {
        state.seedWarmth = (state.seedWarmth + 5).clamp(0, 100);
        state.transience -= 1;
      },
    ),

    // ─────────────────────────────────────────────
    // LOULO — INTRODUCTION
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_loulo_intro',
      lines: const [
        StoryMessage(
          'The tree finally speaks. Warm and steady as sun-baked sand.',
          character: StoryCharacter.loulo,
        ),
        StoryMessage(
          'Hello, little bird. I am Loulo.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She has always been pink, and she says it like a fact no one needs to argue with.',
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 15),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'How can a palm tree be pink?',
          nextScene: 'ep4_loulo_intro_a',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'It suits you.',
          nextScene: 'ep4_loulo_intro_b',
          statEffects: {'connectivity': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Do people bother you about it?',
          nextScene: 'ep4_loulo_intro_c',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'The gulls clearly love you.',
          nextScene: 'ep4_loulo_intro_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_loulo_intro_a',
      lines: const [
        StoryMessage(
          'I don\'t know.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Loulo says this easily.'),
        StoryMessage(
          'I\'ve always been this way. I stopped wondering why and started just being.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A beat.'),
        StoryMessage(
          'It\'s faster.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_carlos_flask',
    ),

    Scene(
      id: 'ep4_loulo_intro_b',
      lines: const [
        StoryMessage(
          'Loulo is warm about this in the way that only something that has made peace with itself can be warm.',
          character: StoryCharacter.loulo,
        ),
        StoryMessage(
          'Thank you. I think so too.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'No embarrassment. No deflection. Just: yes. That\'s right.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_carlos_flask',
    ),

    Scene(
      id: 'ep4_loulo_intro_c',
      lines: const [
        StoryMessage(
          'Sometimes. They want to know what\'s wrong with me.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'What do you tell them?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Nothing is wrong with me.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Loulo says this with no hesitation.'),
        StoryMessage(
          'I\'m just pink.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She says it with the finality of someone who stopped having that argument a very long time ago.',
          character: StoryCharacter.loulo,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_carlos_flask',
    ),

    Scene(
      id: 'ep4_loulo_intro_d',
      lines: const [
        StoryMessage(
          'Loulo makes a sound like fronds moving in a warm wind. It might be a laugh.',
          character: StoryCharacter.loulo,
        ),
        StoryMessage(
          'We\'ve been here together a long time, the four of us. They know where to find shade. I know when to give it.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Carlos looks up from his shells. Says nothing. That is how you know she\'s right.',
          character: StoryCharacter.carlos,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_carlos_flask',
      onEnter: (state) {
        state.vitality -= 1;
      },
    ),

    // ─────────────────────────────────────────────
    // CARLOS — THE FLASK OF TEARS
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_carlos_flask',
      lines: const [
        StoryMessage(
          'Carlos notices the Flask of Tears before anyone else does. He always seems to notice the things that are slightly harder to see.',
          character: StoryCharacter.carlos,
        ),
        StoryMessage(
          'That flask holds weight the right way.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He says it like he has been thinking about it for a while.',
        ),
        StoryMessage(
          'Things get lighter when they are held somewhere else.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(hours: 1),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'You\'re oddly philosophical for a seagull.',
          nextScene: 'ep4_carlos_flask_a',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'The weight doesn\'t go away. It\'s just held.',
          nextScene: 'ep4_carlos_flask_b',
          statEffects: {'connectivity': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Is there a container for what you can\'t put down?',
          nextScene: 'ep4_carlos_flask_c',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[Just think about it for a moment.]',
          nextScene: 'ep4_lemon_crossing',
          statEffects: {'transience': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_carlos_flask_a',
      lines: const [
        StoryMessage(
          'Possibly.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Carlos says this like a practical diagnosis.'),
        StoryMessage(
          'I\'ve had a lot of time standing at the edge of things.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He taps a shell fragment with one foot. Studies it.',
          character: StoryCharacter.carlos,
        ),
        StoryMessage(
          'The ocean teaches you things. Mostly that it\'s going to keep going regardless.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_lemon_crossing',
    ),

    Scene(
      id: 'ep4_carlos_flask_b',
      lines: const [
        StoryMessage(
          'Carlos nods. It is a slow nod — the nod of someone agreeing with a correction they already know is right.',
          character: StoryCharacter.carlos,
        ),
        StoryMessage(
          'You\'re right. I didn\'t say lighter. I said held somewhere else.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause.'),
        StoryMessage(
          'Those are different things. I\'m glad you noticed.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_lemon_crossing',
      onEnter: (state) {
        state.stability -= 1;
      },
    ),

    Scene(
      id: 'ep4_carlos_flask_c',
      lines: const [
        StoryMessage(
          'Carlos is quiet for a long time.',
          character: StoryCharacter.carlos,
        ),
        StoryMessage(
          'I think there are things made for that.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He says it finally, after the quiet has done its work.'),
        StoryMessage(
          'Not to make weight disappear. To give it a shape you can choose to carry.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He glances toward the pink fronds.',
          character: StoryCharacter.carlos,
        ),
        StoryMessage(
          'Loulo knows more about that kind of thing than I do.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_lemon_crossing',
    ),

    // ─────────────────────────────────────────────
    // LEMON — THE CROSSING
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_lemon_crossing',
      lines: const [
        StoryMessage(
          'Lemon is already mapping the water in her head. She tells you the route, the current, and the atoll like she is reading a familiar page.',
          character: StoryCharacter.lemon,
        ),
        StoryMessage(
          'The first leg is manageable. The wind helps if you respect it. The atoll will be there when you need it.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She also says there are orange lights below the atoll at night. She says the fish do not bother travelers who are honest about why they are passing through.',
          character: StoryCharacter.lemon,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 20),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Do you fly this route often?',
          nextScene: 'ep4_lemon_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'How long does the full crossing take?',
          nextScene: 'ep4_lemon_b',
          statEffects: {'stability': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'What are the orange lights?',
          nextScene: 'ep4_lemon_c',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'Will you come with me?',
          nextScene: 'ep4_lemon_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_lemon_a',
      lines: const [
        StoryMessage(
          'Often enough to know it.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She does not elaborate. You get the sense that with Lemon, the answer given is always precisely the answer she decided to give.',
          character: StoryCharacter.lemon,
        ),
        StoryMessage(
          'Sunny shouts something from forty feet away about the waves.',
          character: StoryCharacter.sunny,
        ),
        StoryMessage('Carlos watches the horizon.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_atoll_preview',
    ),

    Scene(
      id: 'ep4_lemon_b',
      lines: const [
        StoryMessage(
          'Lemon considers. It\'s the kind of consideration that involves actually running the math.',
          character: StoryCharacter.lemon,
        ),
        StoryMessage(
          'Depends on the wind. Half a day if it\'s good. Longer if it isn\'t. Rest at the atoll. Don\'t skip the rest.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She says the last part like she has watched someone skip the rest before and has opinions about it.',
          character: StoryCharacter.lemon,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_atoll_preview',
    ),

    Scene(
      id: 'ep4_lemon_c',
      lines: const [
        StoryMessage(
          'Seven fish that live very deep. They circle a thing we don\'t have a name for.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Should I be worried?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'No.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Lemon says this without softening it.'),
        StoryMessage(
          'They\'re not looking at you. They\'re looking at the thing below them. You\'re incidental.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Somehow this is both reassuring and not reassuring at all.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_atoll_preview',
    ),

    Scene(
      id: 'ep4_lemon_d',
      lines: const [
        StoryMessage(
          'Something in Lemon\'s posture changes. Becomes more settled.',
          character: StoryCharacter.lemon,
        ),
        StoryMessage(
          'We were going to anyway.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('She says it like the matter was settled long ago.'),
        StoryMessage(
          'We said we would!',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Sunny calls this from very far away.'),
        StoryMessage(
          'We did say that.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Carlos confirms this without looking up from the shells.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_atoll_preview',
      onEnter: (state) {
        state.vitality -= 1;
      },
    ),

    Scene(
      id: 'ep4_atoll_preview',
      lines: const [
        StoryMessage(
          'Lemon looks out over the water as though the atoll is already sitting there, waiting for the right angle of light to become visible.',
          character: StoryCharacter.lemon,
        ),
        StoryMessage(
          'You will not see the crossing all at once.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('She says this while watching the water.'),
        StoryMessage(
          'You see the first leg. Then the second. Then the part where you are tired enough to understand why rest matters.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Carlos says nothing for a while, which is how you know he agrees.',
          character: StoryCharacter.carlos,
        ),
        StoryMessage(
          'Sunny tilts his head toward the horizon and somehow makes the whole thing feel less impossible.',
          character: StoryCharacter.sunny,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_loulo_reflection',
      waitDuration: const Duration(minutes: 45),
    ),

    // ─────────────────────────────────────────────
    // LOULO — THE REFLECTION + POT
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_loulo_reflection',
      lines: const [
        StoryMessage(
          'The sun has gone gold by the time Loulo turns fully toward you again.',
          character: StoryCharacter.loulo,
        ),
        StoryMessage(
          'What do you hold most tightly?',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('She asks it gently.'),
        StoryMessage(
          'The seed, the branch, the flask, or the question itself?',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She does not sound like she is grading you. She sounds like she wants the true answer.',
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 20),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'The seed. Everything is about the seed.',
          nextScene: 'ep4_loulo_pot',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Probably everything, which is the problem.',
          nextScene: 'ep4_loulo_pot',
          statEffects: {'transience': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'I\'m still figuring that out.',
          nextScene: 'ep4_loulo_pot',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'The branch. It feels like the reason.',
          nextScene: 'ep4_loulo_pot',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_loulo_pot',
      lines: const [
        StoryMessage(
          'Loulo listens to your answer. Does not argue with it. Does not tell you whether you are right.',
          character: StoryCharacter.loulo,
        ),
        StoryMessage(
          'Instead, she reaches down and rolls a small pot toward you. It is sand-fired, warm, faintly gold-pink. Small enough to hold in one talon.',
          character: StoryCharacter.loulo,
        ),
        StoryMessage(
          'It holds intention.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('She says this as the pot comes to rest beside you.'),
        StoryMessage(
          'What you put inside becomes something you can carry on purpose.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'For the first time you notice a small empty hollow woven into the side of the Warming Pouch. Somehow you had never paid attention to it before. There is a shape to it, a deliberate absence. Looking at the pot, you understand without being told that the hollow was made for one vessel, not a collection.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'The gulls go very quiet, which is how you know this matters to them too.',
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 20),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Take Loulo\'s Pot now.',
          nextScene: 'ep4_pot_taken',
          addItems: ["Loulo's Pot"],
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'I\'m not sure I\'m ready.',
          nextScene: 'ep4_pot_wait',
          statEffects: {'transience': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'What do the other vessels hold?',
          nextScene: 'ep4_pot_other_vessels',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'What do you think I should do?',
          nextScene: 'ep4_pot_loulo_advice',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_pot_taken',
      lines: const [
        StoryMessage(
          'You pick it up. It is warm in a way that is not just the sun.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'Loulo does not say "good." She says nothing for a moment, which is its own kind of approval.',
          character: StoryCharacter.loulo,
        ),
        StoryMessage(
          'When you find something worth putting in it, you\'ll know.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_vessel_reflection_taken',
      onEnter: (state) {
        state.intentionVessel = 'loulo';
      },
    ),

    Scene(
      id: 'ep4_pot_wait',
      lines: const [
        StoryMessage(
          'Then don\'t take it yet.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Loulo says it simply.'),
        StoryMessage(
          'Can I... take it later?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'If you come back through, yes. Or send word with Lemon.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A pause, and then something in her voice that is very nearly amusement.',
          character: StoryCharacter.loulo,
        ),
        StoryMessage(
          'But if you leave the hollow empty, it will not stay empty forever. The road has a way of offering shapes to travelers who refuse the first one.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You think about this. About the crossing. About the fact that choosing later is still choosing.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Actually — I\'ll take it. Coming back isn\'t guaranteed.',
          nextScene: 'ep4_pot_taken',
          addItems: ["Loulo's Pot"],
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Leave the hollow empty for now.',
          nextScene: 'ep4_vessel_reflection_deferred',
          statEffects: {'transience': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_pot_other_vessels',
      lines: const [
        StoryMessage(
          'We don\'t know exactly. Rumors.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Some vessels are made where the water keeps its own secrets, from glass the tide has softened until it stops cutting.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Some are made where the cold teaches everything to hold still.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Carlos adds this from beside the shells.'),
        StoryMessage(
          'And some are made by trees who don\'t ask twice!',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Sunny somehow finds a way to make even this sound exciting.',
        ),
        StoryMessage(
          'Those are guesses.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Lemon says this to keep the map honest.'),
        StoryMessage(
          'We\'ve never carried them ourselves. Loulo\'s we know. It is gentle, which does not mean it is small.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Loulo\'s fronds shift. The pot waits in the sand. So does the empty space in the pouch.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Then I\'ll take Loulo\'s.',
          nextScene: 'ep4_pot_taken',
          addItems: ["Loulo's Pot"],
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Leave the hollow empty for now.',
          nextScene: 'ep4_vessel_reflection_deferred',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_pot_loulo_advice',
      lines: const [
        StoryMessage(
          'I think you should listen for the answer you already made.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'If this pot feels like a home, take it. If it feels like a promise you are only making because I am kind, leave it here.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The gulls are very still. Even Sunny seems to understand that this is not a choice anyone else can make for you.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Take Loulo\'s Pot.',
          nextScene: 'ep4_pot_taken',
          addItems: ["Loulo's Pot"],
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Leave the hollow empty for now.',
          nextScene: 'ep4_vessel_reflection_deferred',
          statEffects: {'connectivity': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_vessel_reflection_taken',
      lines: const [
        StoryMessage(
          'The pot sits warm in your talon, small enough to ignore and too deliberate to dismiss.',
        ),
        StoryMessage(
          'Loulo does not ask you to like it. She just waits while you learn the weight of a choice that closes other doors without making them wrong.',
          character: StoryCharacter.loulo,
        ),
        StoryMessage(
          'Carlos says the sea has a way of revealing whether you chose well.',
          character: StoryCharacter.carlos,
        ),
        StoryMessage('Lemon says that is what all long crossings are for.'),
        StoryMessage(
          'Sunny thinks that sounds dramatic and therefore excellent.',
          character: StoryCharacter.sunny,
        ),
        StoryMessage(
          'You look down at the branch, the flask, the pouch, and the pot. Each thing has a different weight. Each thing asks a different question.',
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 25),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'This is mine. I chose it.',
          nextScene: 'ep4_departure',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'I still don\'t want to choose wrong.',
          nextScene: 'ep4_departure',
          statEffects: {'transience': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Wonder what the other vessels would have asked.',
          nextScene: 'ep4_departure',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'Maybe I already know why I took it.',
          nextScene: 'ep4_departure',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_vessel_reflection_deferred',
      lines: const [
        StoryMessage(
          'Loulo draws the pot back with one frond. She does not look hurt. That almost makes it harder.',
          character: StoryCharacter.loulo,
        ),
        StoryMessage(
          'Then the hollow stays empty.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'Empty is not the same as free.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Carlos glances at Lemon, then at the water. He does not disagree.',
          character: StoryCharacter.carlos,
        ),
        StoryMessage(
          'Sunny looks briefly worried, then very determined, as if he has decided the solution is to fly extra enthusiastically.',
          character: StoryCharacter.sunny,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 25),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'I made the choice I can live with.',
          nextScene: 'ep4_departure',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'I hope the next shape is clearer.',
          nextScene: 'ep4_departure',
          statEffects: {'transience': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Ask the gulls not to let you forget.',
          nextScene: 'ep4_departure',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'Look toward the water and keep moving.',
          nextScene: 'ep4_departure',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    // ─────────────────────────────────────────────
    // FAREWELLS AND DEPARTURE
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_departure',
      lines: const [
        StoryMessage(
          'The sun is low. The water is gold. The kind of evening that doesn\'t let you delay much longer without the weight of it becoming its own thing.',
        ),
        StoryMessage(
          'Okay! We\'re flying with you! Right, Lemon? We said we would!',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'We did say that.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The wind is good tonight. We should go soon.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 30),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Thank you — all of you. For the afternoon.',
          nextScene: 'ep4_departure_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Karl was right to send me to you.',
          nextScene: 'ep4_departure_b',
          statEffects: {'stability': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: '[To Loulo]: I\'ve never met a tree like you.',
          nextScene: 'ep4_departure_c',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[To Lemon]: Take care of them.',
          nextScene: 'ep4_departure_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep4_departure_a',
      lines: const [
        StoryMessage(
          'Anytime! Come back when you\'re done with the mission!',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The ocean is patient. We\'ll meet again.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Don\'t get sentimental. You\'ll see us at the atoll in a few hours.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Come back, little bird. I\'ll still be pink.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_edge',
    ),

    Scene(
      id: 'ep4_departure_b',
      lines: const [
        StoryMessage(
          'Karl sends the ones he trusts. He doesn\'t tell them that.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He trusts most people. He just doesn\'t want them to know.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Karl is SAD but also GOOD and I love him!',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Should someone... tell him that?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He knows. It still makes him sad. Some things are like that.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_edge',
    ),

    Scene(
      id: 'ep4_departure_c',
      lines: const [
        StoryMessage(
          'There is only one of me.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Loulo says this with a last warm rustle.'),
        StoryMessage(
          'That\'s true of most things, if you look closely enough.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A last warmth, the way the sun gives warmth just before it goes.',
          character: StoryCharacter.loulo,
        ),
        StoryMessage(
          'Go. The water is waiting.',
          character: StoryCharacter.loulo,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_edge',
    ),

    Scene(
      id: 'ep4_departure_d',
      lines: const [
        StoryMessage(
          'Lemon\'s expression does something complicated. Something that has years in it.',
          character: StoryCharacter.lemon,
        ),
        StoryMessage(
          'Always.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'We don\'t need—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Always.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She\'s right. We do.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Sunny opens his beak to object and then closes it. Grins instead.',
          character: StoryCharacter.sunny,
        ),
        StoryMessage(
          'Yeah. Okay. We do.',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_edge',
      onEnter: (state) {
        state.vitality -= 1;
      },
    ),

    // ─────────────────────────────────────────────
    // THE EDGE — DEPARTURE
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_edge',
      lines: const [
        StoryMessage(
          'You stand at the tideline. The water touches your feet and pulls back. Touches and pulls back. An indifferent gesture, but rhythmic. Almost like a signal.',
        ),
        StoryMessage(
          'Behind you: the beach, Loulo\'s pink fronds visible even in the dimming light, Karl somewhere along the tideline being quietly, consistently sad and correct about things.',
        ),
        StoryMessage(
          'Beside you: three seagulls shaking out their wings, falling into a loose formation. Lemon on the left, calibrating something in her head. Carlos in the middle, watching the far horizon with the calm of someone who already knows what\'s out there. Sunny on the right, vibrating very slightly with enthusiasm.',
        ),
        StoryMessage('You look at what you\'re carrying.'),
        StoryMessage(
          'Dawn\'s Branch. The Flask of Tears. The Warming Pouch, with the Seed inside, glowing red-gold. London\'s Vial (Mossy Residue), still waiting. And now — if you took it — Loulo\'s Pot, warm in your talon, smelling faintly of salt and sun.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'You have been flying for a long time. You have met a crab who knows more than he lets on and cares more than he shows. A pink tree who has decided to be exactly herself, fully and without apology. Three gulls who are family in the deepest sense — bound not just by blood but by the specific accumulated history of watching each other fly.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'You are going across an ocean now.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage('You spread your wings.'),
        StoryMessage('The gulls rise around you.'),
        StoryMessage('The water begins.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep4_complete',
      waitDuration: const Duration(minutes: 15),
      onEnter: (state) {},
    ),

    // ─────────────────────────────────────────────
    // EPISODE COMPLETE
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep4_complete',
      lines: const [
        StoryMessage(
          'EPISODE COMPLETE: THE OPEN SHORE',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage(
          'The atoll waits in the dark water.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'Below it, in the deep places where light does not reach, seven orange lights move slowly in their eternal circle.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'Far beyond the horizon, something waits with the same patience as the sea.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.none,
      onEnter: (state) {
        state.episodeComplete = true;
        state.seedWarmth = (state.seedWarmth + 10).clamp(0, 100);
      },
    ),
  ];
}
