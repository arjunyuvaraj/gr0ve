import 'package:gr0ve/features/grove/models/grove_models.dart';

List<Scene> buildEpisode05UnnamedWaters() {
  return [
    // ─────────────────────────────────────────────
    // OPENING — DAYS ADRIFT
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_intro',
      lines: const [
        StoryMessage(
          'EPISODE 5: THE UNNAMED WATERS',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage('The land stopped being an option a while ago.'),
        StoryMessage(
          'Not suddenly. Gradually, the way most important things stop. First the shore was a line. Then the shore was a smudge. Then the shore was a memory of a line, and now there is nothing behind you and nothing ahead of you except more of the same flat, endless, entirely unbothered blue.',
        ),
        StoryMessage(
          'You have been flying for three days.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'Your wings have developed a rhythm that no longer feels like effort so much as habit — the body doing the thing the body has decided it will do, without consulting you further. Lemon flies point, correcting course by degrees so small you can\'t see them, only feel them, the way you feel a held note change key. Carlos flies with the calm of someone who made peace with the ocean around day one. Sunny flies like the ocean personally invited him and he intends to make the most of the invitation.',
        ),
        StoryMessage(
          'How are you three not tired.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'We are tired.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Very tired.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I\'m not tired even a LITTLE—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He yawns so hard his whole body tips sideways for a second before he rights himself.',
        ),
        StoryMessage(
          '—bit.',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Dawn\'s Seed Warmth: stable. Holding steady, for now.',
          kind: MessageKind.system,
        ),
        StoryMessage(
          'You look down at what you\'re carrying. Dawn\'s Branch, worn smooth against your side. The Flask of Tears, its blue light pulsing slow and patient. The Warming Pouch, Dawn\'s Seed glowing low but even inside it. London\'s Vial, waiting for whatever it\'s waiting for.',
        ),
        StoryMessage(
          'The water beneath you has gone a color you don\'t have a name for. Not blue exactly. Deeper than blue. The color water gets when it stops being about the sky and starts being about what\'s underneath it.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_fishing_contest',
      waitDuration: const Duration(days: 3),
      onEnter: (state) {
        // Seed warmth is maintained at 100 thanks to the Warming Pouch
        if (state.inventory.contains('Warming Pouch')) {
          state.seedWarmth = 100;
        } else {
          state.seedWarmth = state.seedWarmth.clamp(0, 100);
        }
      },
    ),

    // ─────────────────────────────────────────────
    // THE FISHING CONTEST
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_fishing_contest',
      lines: const [
        StoryMessage('It is Sunny\'s idea. Of course it\'s Sunny\'s idea.'),
        StoryMessage(
          'Okay. New rule. Whoever catches the biggest fish gets to not do the evening flight check-in.',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That\'s not a prize. That\'s just a chore we invented so you could avoid it.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Exactly! I\'m very smart!',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I\'m too tired to argue with the logic of that, which is somehow worse than if it made sense.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 45),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'I\'m in. What are the rules?',
          nextScene: 'ep5_fishing_a',
          statEffects: {'vitality': 1},
        ),
        SceneChoice(
          letter: 'B',
          label:
              'I\'ll judge. I don\'t think my wings can take a dive right now.',
          nextScene: 'ep5_fishing_b',
          statEffects: {'stability': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'This feels like a bad idea over open ocean.',
          nextScene: 'ep5_fishing_c',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[Just watch. See how this goes.]',
          nextScene: 'ep5_fishing_d',
          statEffects: {'connectivity': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_fishing_a',
      lines: const [
        StoryMessage(
          'YES! Okay, rules: biggest fish wins, style points for anything caught upside down, and Carlos isn\'t allowed to use "the fish came to me philosophically" as an excuse again.',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It happened once.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It happened TWICE.',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_fishing_contest_start',
    ),

    Scene(
      id: 'ep5_fishing_b',
      lines: const [
        StoryMessage(
          'Thank you. Someone sane needs to hold the results.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Judging is for people who are SCARED—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Judging is for people whose wings have earned a rest, which none of you respect.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_fishing_contest_start',
    ),

    Scene(
      id: 'ep5_fishing_c',
      lines: const [
        StoryMessage(
          'It probably is.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It definitely is.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It\'s FINE, we do this every crossing!',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'We do this every crossing and every crossing I say the same thing, which is that it\'s fine right up until it isn\'t.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_fishing_contest_start',
    ),

    Scene(
      id: 'ep5_fishing_d',
      lines: const [
        StoryMessage(
          'Sunny is already stripping off toward the water before anyone answers you, which seems to be how most of Sunny\'s plans get approved — not through consensus, through momentum.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_fishing_contest_start',
    ),

    Scene(
      id: 'ep5_fishing_contest_start',
      lines: const [
        StoryMessage(
          'What follows is, against all odds, one of the more purely enjoyable twenty minutes of your entire journey.',
        ),
        StoryMessage(
          'Carlos catches a small silver fish on his first pass and holds it up with the quiet satisfaction of someone who does not need to celebrate loudly to feel the win. Sunny catches nothing on four consecutive attempts and grows more committed with each failure, diving at increasingly improbable angles. Lemon, technically judging, keeps "accidentally" catching fish herself and holding them up for comparison, which everyone agrees is cheating and no one stops her because arguing takes energy none of you have.',
        ),
        StoryMessage(
          'For the record, mine is bigger.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You\'re the judge. You can\'t enter.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I can absolutely enter. I wrote the rules in my head just now and they favor me.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I MEANT TO DO THAT—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Sunny says this mid-air, upside down, missing a fish entirely.',
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 20),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Try your own dive. Go for a fish.',
          nextScene: 'ep5_fishing_dive',
          statEffects: {'vitality': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Cheer Sunny on. He needs it.',
          nextScene: 'ep5_fishing_cheer',
          statEffects: {'connectivity': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Point out a strange one — a fish that\'s the wrong color.',
          nextScene: 'ep5_fishing_pink',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[Just laugh. Let them have this.]',
          nextScene: 'ep5_fishing_laugh',
          statEffects: {'stability': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_fishing_dive',
      lines: const [
        StoryMessage(
          'You fold your wings and drop. The water rushes up. For one weightless second you are entirely inside the dive and nothing else exists — not the crossing, not the seed, not the ocean\'s total indifference to your problems. You come up with a fish half the size of Carlos\'s, and it feels, absurdly, like one of the better moments of the week.',
        ),
        StoryMessage(
          'Respectable. Not winning. But respectable.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_pink_fish_sighting',
      onEnter: (state) {
        state.vitality += 1;
      },
    ),

    Scene(
      id: 'ep5_fishing_cheer',
      lines: const [
        StoryMessage(
          'You\'ve got this! Just — commit to an angle!',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I AM COMMITTING—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He does not catch a fish. But he comes up grinning anyway, because commitment, to Sunny, is its own kind of victory.',
        ),
        StoryMessage(
          'He\'ll go again in ten seconds.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'In ten seconds I\'m going again!',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_pink_fish_sighting',
      onEnter: (state) {
        state.connectivity += 1;
      },
    ),

    Scene(
      id: 'ep5_pink_fish_sighting',
      lines: const [
        StoryMessage(
          'Then you see it. Low in the water, moving slow. A fish, bright and wrong — a saturated, unnatural pink, the pink of a warning sign, the pink of something that wants very badly to be noticed.',
        ),
        StoryMessage(
          'Hey — that one. That fish.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Lemon\'s head turns. All the exhaustion drops out of her posture at once, replaced by something sharper.',
        ),
        StoryMessage(
          'Don\'t.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_whale',
    ),

    Scene(
      id: 'ep5_fishing_pink',
      lines: const [
        StoryMessage(
          'You see it before anyone else does, mostly because you\'re the only one not currently mid-dive or mid-argument. A fish, low in the water, moving slow.',
        ),
        StoryMessage('It is bright pink.'),
        StoryMessage(
          'Not the muted rose of something dying. Not the pale flush of something young. A saturated, unnatural, wrong pink — the pink of a warning sign, the pink of something that wants very badly to be noticed for reasons that are almost certainly not good ones.',
        ),
        StoryMessage(
          'Hey — that one. That fish.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Lemon\'s head turns. All the exhaustion drops out of her posture at once, replaced by something sharper.',
        ),
        StoryMessage(
          'Don\'t.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_whale',
    ),

    Scene(
      id: 'ep5_fishing_laugh',
      lines: const [
        StoryMessage(
          'You watch them for a while, letting the sound of it — Sunny\'s increasingly theatrical failures, Carlos\'s dry commentary, Lemon\'s shameless self-officiating — settle into you like warmth. It is the first time in days you\'ve laughed without also, somewhere underneath, thinking about the seed.',
        ),
        StoryMessage('Then you see it. Low in the water. Bright, wrong pink.'),
        StoryMessage(
          '...Lemon. That fish.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_whale',
    ),

    // ─────────────────────────────────────────────
    // THE PINK FISH / THE WHALE
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_whale',
      lines: const [
        StoryMessage(
          'Everyone up. Now. That\'s not a fish you eat, that\'s a fish that\'s telling you something ate near it recently and is probably still nearby.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She says it fast, flat, completely without the warmth she\'s had all afternoon. This is a different Lemon. The oldest-sibling Lemon. The one who has, somewhere in her feathers, an emergency setting the rest of them don\'t have.',
        ),
        StoryMessage(
          'Sunny—',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('But Sunny is already diving.'),
        StoryMessage(
          'IT\'S JUST A FISH, I\'M NOT SCARED OF A COLOR—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'SUNNY—',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He hits the water.'),
        StoryMessage(
          'For one full second, nothing happens. The ocean is flat and quiet and gives absolutely no indication that anything is wrong, in the specific way oceans have of hiding enormous, terrible things directly beneath a calm surface.',
        ),
        StoryMessage('Then the ocean stops being flat.'),
        StoryMessage('It comes up like the sea itself decided to stand.'),
        StoryMessage(
          'Gray. Enormous. Water sheeting off a back the size of a hillside, a fin cutting the air like something drawn wrong on purpose, too large, too sudden, too much. The sound of it — a crack and a roar of displaced ocean — hits you a full second after the sight does, which somehow makes it worse. Your brain has to process the impossible thing twice.',
        ),
        StoryMessage(
          'SUNNY—',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Lemon doesn\'t say anything at all, which is the most frightening part of the whole thing. Lemon always says something. Lemon has something to say about everything. Right now there is nothing coming out of her at all, just her wings locked mid-beat and her eyes fixed on the space where her brother used to be.',
        ),
        StoryMessage('The whale crests, turns, and comes down.'),
        StoryMessage('Where Sunny was.'),
        StoryMessage(
          'The water closes over the space. White foam. Then nothing. Then just ocean again, rocking gently, exactly as indifferent as it was thirty seconds ago, as if it hadn\'t just done anything at all.',
        ),
        StoryMessage('Hold here.', kind: MessageKind.system, isItalic: true),
        StoryMessage('Nobody moves.'),
        StoryMessage(
          '...Lemon.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Carlos says nothing.'),
        StoryMessage('Lemon says nothing.'),
        StoryMessage(
          'The silence stretches. It stretches the way silence stretches when everyone in it is doing the same math and getting the same answer and nobody wants to be the one who says it first.',
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(seconds: 10),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'We have to go down there. Now.',
          nextScene: 'ep5_whale_a',
          statEffects: {'vitality': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: '[Say nothing. Just stare at the water.]',
          nextScene: 'ep5_whale_b',
          statEffects: {'stability': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Lemon. Say something. Please.',
          nextScene: 'ep5_whale_c',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'Maybe he\'s — maybe he swam clear—',
          nextScene: 'ep5_whale_d',
          statEffects: {'transience': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_whale_a',
      lines: const [
        StoryMessage(
          'You\'re already dropping toward the water before finishing the sentence, every instinct overriding the very reasonable fact that you cannot breathe underwater and have no plan whatsoever.',
        ),
        StoryMessage(
          'WAIT—',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Lemon snaps out of it, grabbing your wing.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_whale_rescue',
    ),

    Scene(
      id: 'ep5_whale_b',
      lines: const [
        StoryMessage(
          'You stare at the water with the other two. Nobody breathes right. The ocean rocks, patient and unbothered, the way it has been unbothered this entire journey, and for the first time that indifference feels less like scenery and more like something you might genuinely hate.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_whale_rescue',
    ),

    Scene(
      id: 'ep5_whale_c',
      lines: const [
        StoryMessage('Lemon\'s beak opens. Closes. Opens again.'),
        StoryMessage(
          'I don\'t—',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('She stops. Tries again.'),
        StoryMessage(
          'He\'s my—',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She doesn\'t finish that either. Carlos moves closer to her, wordless, and puts his wing against hers.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_whale_rescue',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_whale_d',
      lines: const [
        StoryMessage(
          'No.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He says it quietly. Not cruelly. Just factually, the way Carlos says most things.',
        ),
        StoryMessage(
          'I was watching. He didn\'t.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_whale_rescue',
    ),

    Scene(
      id: 'ep5_whale_rescue',
      lines: const [
        StoryMessage('The water breaks again.'),
        StoryMessage(
          'The whale surfaces slower this time — not lunging, just rising, the way something enormous rises when it has decided there is no hurry left in the situation. Water sheets off gray skin the texture of old riverbed stone. One small, dark eye rolls toward you with an expression that is, unmistakably, apologetic.',
        ),
        StoryMessage(
          'And there — held sideways, entirely unharmed, halfway inside a mouth the size of a rowboat, feathers soaked flat and eyes enormous with outrage — is Sunny.',
        ),
        StoryMessage(
          'SUNNY.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I\'m FINE, I\'m just — this is very WET—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The whale makes a low, apologetic sound, somewhere between a moan and a hum, and does not close its mouth any further. If anything, it seems slightly embarrassed, in the specific way an enormous creature can look embarrassed while holding a bird hostage in its jaw by accident.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_petalblack_intro',
      onEnter: (state) {
        state.connectivity += 1;
      },
    ),

    // ─────────────────────────────────────────────
    // PETALBLACK — INTRODUCTION
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_petalblack_intro',
      lines: const [
        StoryMessage('Something small breaks the surface beside the whale.'),
        StoryMessage(
          'It is a fish. The fish, in fact — the bright, wrong pink one that started all of this — except up close it isn\'t wrong at all. It\'s simply small, calm, and entirely unbothered by the fact that it is floating next to a creature roughly four thousand times its size.',
        ),
        StoryMessage(
          'Hubert.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Her voice is quiet. Even. The kind of quiet that somehow carries further than shouting.',
        ),
        StoryMessage(
          'Spit him out.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The whale — Hubert, apparently — makes a small, pleading sound, and his enormous eye swivels toward her.',
        ),
        StoryMessage(
          'Can I keep just a little of him—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'No.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A wing—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Hubert.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'There is a pause. Hubert\'s whole enormous body seems to deflate slightly, the way something the size of a hill deflates — slowly, and with a great deal of feeling.',
        ),
        StoryMessage('He opens his mouth.'),
        StoryMessage(
          'Sunny drops out into the water with a splash and immediately resurfaces, coughing, indignant, and entirely, gloriously unharmed.',
        ),
        StoryMessage(
          'I have BEEN EATEN—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You have NOT been eaten, you were HELD, there\'s a difference, and the difference is you\'re going to hear about for the rest of your LIFE—',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Lemon drops to the water beside him, voice cracking with relief she is trying very hard to convert into anger.',
        ),
        StoryMessage(
          'I was IN A MOUTH, Lemon, that COUNTS—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I\'m glad you\'re okay.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Carlos lands beside them both, very quietly.'),
        StoryMessage(
          'I\'M GLAD I\'M OKAY TOO—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 5),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '...what just happened.',
          nextScene: 'ep5_petalblack_a',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: '[To the small pink fish] Thank you. For that.',
          nextScene: 'ep5_petalblack_b',
          statEffects: {'connectivity': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: '[To the whale] Are you — are you okay?',
          nextScene: 'ep5_petalblack_c',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'Just watch the siblings for a moment. Let them have it.',
          nextScene: 'ep5_petalblack_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_petalblack_a',
      lines: const [
        StoryMessage(
          'Hubert happened. It happens more than it should.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I said sorry.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You always say sorry. Saying sorry isn\'t the same as not doing it.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...that\'s fair.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_introductions',
    ),

    Scene(
      id: 'ep5_petalblack_b',
      lines: const [
        StoryMessage(
          'Petalblack looks at you properly for the first time. Small, orange-pink, entirely unhurried.',
        ),
        StoryMessage(
          'You\'re welcome. Though it wasn\'t really a favor. He does this. I fix it. It\'s less "thank you" and more "Tuesday."',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_introductions',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_petalblack_c',
      lines: const [
        StoryMessage(
          'Hubert\'s huge eye turns toward you, surprised, like nobody usually asks him that.',
        ),
        StoryMessage(
          'Oh! Yes! I\'m always okay. I\'m very big, not much bothers me. Except her.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He tilts his head very slightly toward Petalblack.'),
        StoryMessage(
          'She bothers me. In a — a good way. A respectful way.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Hubert.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I\'ll stop talking now.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_introductions',
    ),

    Scene(
      id: 'ep5_petalblack_d',
      lines: const [
        StoryMessage(
          'You watch Lemon hold both her brothers at once — one talon on each, an old, practiced gesture, the gesture of someone who has been the one holding on since before she can remember choosing to. Sunny is still talking. Carlos has gone very quiet, the quiet of someone recalibrating how afraid he\'d actually been.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_introductions',
    ),

    // ─────────────────────────────────────────────
    // INTRODUCTIONS
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_introductions',
      lines: const [
        StoryMessage(
          'I\'m Hubert! I\'m a whale!',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He announces this the way you\'d announce good news, with the open, unguarded enthusiasm of a creature who has never once considered that anyone might already know he\'s a whale.',
        ),
        StoryMessage(
          'I\'m Petalblack.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She doesn\'t elaborate. She doesn\'t need to. There\'s a settledness to how she says it — like a name that has been the same name for a very, very long time, and has stopped needing an introduction to feel complete.',
        ),
        StoryMessage(
          'You two — you know this water?',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'We live in this water.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Can I eat one of them—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He says it hopefully, nodding toward Carlos.'),
        StoryMessage(
          'No.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Just the small one—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'They\'re all the small one, Hubert. You\'re enormous. Everything is the small one to you.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...that\'s true. That\'s a fair point.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He does not look at all discouraged by this. If anything, he looks pleased to have learned something.',
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 15),
      choices: const [
        SceneChoice(
          letter: 'A',
          label:
              '[To Petalblack] Does he ask permission before eating everything?',
          nextScene: 'ep5_intro_a',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: '[To Hubert] Do you ever get a yes?',
          nextScene: 'ep5_intro_b',
          statEffects: {'vitality': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'You two seem like you\'ve been doing this a while.',
          nextScene: 'ep5_intro_c',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[To Petalblack] Why was your color a warning?',
          nextScene: 'ep5_intro_d',
          statEffects: {'stability': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_intro_a',
      lines: const [
        StoryMessage(
          'Every time. It\'s very tedious.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I like to CHECK. Checking is polite.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Checking every four minutes is not politeness, Hubert, it\'s a hobby.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It\'s a POLITE hobby.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_lemon_falters',
    ),

    Scene(
      id: 'ep5_intro_b',
      lines: const [
        StoryMessage('Hubert considers this with real, visible effort.'),
        StoryMessage(
          '...once. It was a very old piece of kelp. Nobody wanted it.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That doesn\'t count. I say yes to kelp because kelp doesn\'t have a family.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It still counts to ME.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_lemon_falters',
    ),

    Scene(
      id: 'ep5_intro_c',
      lines: const [
        StoryMessage(
          'A long while.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Longer than the coral! Longer than the — what\'s the — the thing with the current, the—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The trench.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Longer than the trench!',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That one isn\'t true, Hubert.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It FEELS true.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_lemon_falters',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_intro_d',
      lines: const [
        StoryMessage('Petalblack\'s expression, small as it is, goes serious.'),
        StoryMessage(
          'Because in these waters, pink this bright usually means something\'s been hunting nearby and left the wrong kind of shine on the water. Your friend read it correctly. Most travelers don\'t. It\'s why I surface when I see birds circling — to warn them off before Hubert gets curious.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I get curious A LOT.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You get curious constantly, yes.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Well. Thank you both. Genuinely. I thought—',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She stops. Doesn\'t finish it. She doesn\'t need to; everyone present did the same math a few minutes ago.',
        ),
        StoryMessage(
          'You\'re welcome.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Her gaze moves, unhurried, across the four of you — Lemon, Carlos, Sunny, and you. It lingers on you a beat longer than the others. Specifically, it lingers on the Warming Pouch at your side, where Dawn\'s Seed glows low and steady beneath the woven cloth.',
        ),
        StoryMessage(
          'Something changes in her stillness. Not alarm. Attention.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_lemon_falters',
    ),

    // ─────────────────────────────────────────────
    // LEMON FALTERS
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_lemon_falters',
      lines: const [
        StoryMessage('It happens fast, the way these things do.'),
        StoryMessage(
          'One moment Lemon is standing on the water\'s edge of Hubert\'s enormous flank, scolding Sunny with the last of her adrenaline. The next, her wings buckle beneath her — not folding on purpose, just failing, the way something fails when it\'s been running on nothing but momentum for three straight days and the momentum finally runs out.',
        ),
        StoryMessage('She goes down into the water.'),
        StoryMessage(
          'LEMON—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'LEMON!',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Carlos is faster than you\'ve ever seen him move, wedging himself under her wing before she goes fully under, holding her head above the surface with a strength you wouldn\'t have guessed a seagull his size could manage.',
        ),
        StoryMessage(
          'Is she — did I do that? I didn\'t touch her, I promise, I\'ve been very still—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You didn\'t do it, Hubert. Nobody did it. She\'s been carrying too much for too long, same as the rest of them — except she\'s the one who never puts any of it down.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 5),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Is she breathing? Is she okay?',
          nextScene: 'ep5_lemon_a',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: '[Help Carlos hold her up.]',
          nextScene: 'ep5_lemon_b',
          statEffects: {'connectivity': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Petalblack — can you help her?',
          nextScene: 'ep5_lemon_c',
          statEffects: {'vitality': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[To Sunny] Hey. Look at me. She\'s going to be okay.',
          nextScene: 'ep5_lemon_d',
          statEffects: {'transience': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_lemon_a',
      lines: const [
        StoryMessage(
          'She\'s breathing. Slow. But breathing.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('His voice is steadier than his eyes are.'),
        StoryMessage(
          'She\'s exhausted, not hurt. There\'s a difference, and it matters which one this is.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_lemon_petalblack_plan',
    ),

    Scene(
      id: 'ep5_lemon_b',
      lines: const [
        StoryMessage(
          'You slide in beside Carlos, wedging your own wing under Lemon\'s far side. Between the two of you she stays afloat easily — she weighs almost nothing, you realize, in the specific, alarming way tired things weigh nothing.',
        ),
        StoryMessage(
          'Thank you.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He says it quietly.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_lemon_petalblack_plan',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_lemon_c',
      lines: const [
        StoryMessage(
          'I can get her somewhere calm and warm faster than anywhere else in this ocean. That happens to also be exactly where I was already planning to take you.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_lemon_petalblack_plan',
    ),

    Scene(
      id: 'ep5_lemon_d',
      lines: const [
        StoryMessage(
          'Sunny\'s eyes are enormous, all the earlier bravado gone out of him completely.',
        ),
        StoryMessage(
          'Hey. Look at me. She\'s going to be okay.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She\'s never the one who — she\'s always the one who\'s FINE, she doesn\'t get to—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She\'s still fine. She\'s just tired. Tired isn\'t the same as not fine.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...okay.',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_lemon_petalblack_plan',
    ),

    Scene(
      id: 'ep5_lemon_petalblack_plan',
      lines: const [
        StoryMessage(
          'Petalblack\'s stillness sharpens into something closer to command.',
        ),
        StoryMessage(
          'Hubert. Keep her against your side, out of the swell. Gently.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Gently! I can do gently! I\'m very gentle when it matters—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He rolls, carefully, achingly slowly for something his size, until Lemon rests in the calm water pooled against his flank, cradled out of the current.',
        ),
        StoryMessage(
          'There\'s no faster rest anywhere in this water than the roots of the tree I watch over. It\'s the stillest place this ocean has. No current, no swell, no weather at all — just old, patient dark.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She looks at you — at the Warming Pouch, at the glow beneath the cloth — and something in her settles, a decision reached.',
        ),
        StoryMessage(
          'That\'s where we\'re taking all of you. Her, because she needs it. You, because I think you need to meet the tree regardless. Sometimes the ocean hands you one reason to do something, and it turns out to be two.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_seed_noticed',
      waitDuration: const Duration(minutes: 5),
    ),

    // ─────────────────────────────────────────────
    // THE SEED, NOTICED
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_seed_noticed',
      lines: const [
        StoryMessage(
          'That glow, on you. What is it?',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 10),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'It\'s a seed. Dawn gave it to me.',
          nextScene: 'ep5_seed_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'It\'s a long story.',
          nextScene: 'ep5_seed_b',
          statEffects: {'transience': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Why does it matter to you?',
          nextScene: 'ep5_seed_c',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[Open the pouch. Show her.]',
          nextScene: 'ep5_seed_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_seed_a',
      lines: const [
        StoryMessage(
          'Petalblack goes very still — stiller than before, which you wouldn\'t have thought possible.',
        ),
        StoryMessage(
          'Dawn.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Not a question. A word she\'s turning over, checking its weight.',
        ),
        StoryMessage(
          'I haven\'t heard that name spoken by a traveler in longer than you\'d believe.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_seed_explanation',
    ),

    Scene(
      id: 'ep5_seed_b',
      lines: const [
        StoryMessage(
          'I have time. I live at the bottom of an ocean. Time is not something I\'m short on.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Fair.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You tell her. The short version — Dawn, the branch, the fading light, the seed, the gr0ve. She listens without interrupting, the way something listens when it has heard a thousand stories and still gives each one full attention.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_seed_explanation',
    ),

    Scene(
      id: 'ep5_seed_c',
      lines: const [
        StoryMessage(
          'Because very few things still glow like that. And the ones that do tend to be looking for one particular place.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause.'),
        StoryMessage(
          'I need to know which place, before I decide what to do about you.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_seed_explanation',
    ),

    Scene(
      id: 'ep5_seed_d',
      lines: const [
        StoryMessage(
          'You loosen the Warming Pouch and let her see. Dawn\'s Seed pulses in the low light, red-gold, patient.',
        ),
        StoryMessage(
          'Petalblack\'s small pink body goes rigid — not with fear. With recognition.',
        ),
        StoryMessage(
          '...oh.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Ooh! Pretty! Can I—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'No, Hubert.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I wasn\'t going to EAT it, I was going to LOOK at it—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You look with your mouth open. The answer is still no.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_seed_explanation',
    ),

    Scene(
      id: 'ep5_seed_explanation',
      lines: const [
        StoryMessage(
          'Petalblack is quiet for a moment, watching Lemon\'s slow, steady breathing against Hubert\'s side. Beneath her, unseen, you get the sense of something enormous already moving — the decision made, the ocean floor turning over in agreement with it.',
        ),
        StoryMessage(
          'There is a tree. Deep below here, past where the light gives up. She has no name — or she has one and has simply stopped telling anyone what it is, which amounts to the same thing after enough centuries.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I am one of seven who watch over her. We don\'t often bring travelers down. Most who come this far are looking for something they wouldn\'t survive finding.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Am I one of those?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I don\'t know yet.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('She says it plainly. Not unkindly. Just honestly.'),
        StoryMessage(
          'But you carry Dawn\'s Seed, and Dawn doesn\'t hand that seed to just anyone. And your friend needs the calmest water in this ocean, and I already told you where that is. I\'d rather bring all of you down and be wrong about one of those reasons than turn you away and be wrong about both.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 15),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Thank you. I won\'t waste her time, or yours.',
          nextScene: 'ep5_seed_choice_a',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'What happens if she decides I shouldn\'t have come?',
          nextScene: 'ep5_seed_choice_b',
          statEffects: {'transience': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Will Lemon be okay, down there?',
          nextScene: 'ep5_seed_choice_c',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'You said seven of you. Where are the other six?',
          nextScene: 'ep5_seed_choice_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_seed_choice_a',
      lines: const [
        StoryMessage(
          'See that you don\'t. She has had a very long time to grow patient. I would rather not test the edges of it.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_seven',
    ),

    Scene(
      id: 'ep5_seed_choice_b',
      lines: const [
        StoryMessage(
          'Then you go back up, and Hubert carries you somewhere less interesting, and this whole afternoon becomes a strange thing that happened once.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I\'m very good at carrying people places! Even sad places!',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That is not the comfort you think it is, Hubert.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_seven',
    ),

    Scene(
      id: 'ep5_seed_choice_c',
      lines: const [
        StoryMessage(
          'Better than okay. Down there, nothing pulls at her. No wind, no current, no need to hold anything up — not even her own wings, if she doesn\'t want to. It\'s the closest thing to stillness this ocean has to offer, and stillness is exactly what she\'s out of.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Thank you for that.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Carlos says it quietly, still holding her steady.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_seven',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_seed_choice_d',
      lines: const [
        StoryMessage(
          'Around. Somewhere. They\'ll show themselves if they feel like it, which is not something any of them can be convinced to do faster than they choose to.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A small, dry note enters her voice.'),
        StoryMessage(
          'I\'m the one who actually gets things done. That\'s not vanity. It\'s just accurate.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_seven',
    ),

    // ─────────────────────────────────────────────
    // THE SEVEN
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_the_seven',
      lines: const [
        StoryMessage(
          'Petalblack gives a low, rippling call — a sound that travels through the water in a way you feel more than hear, a pressure against your feathers where they trail the surface.',
        ),
        StoryMessage('One by one, they come.'),
        StoryMessage(
          'The first is slow. Achingly slow, a fish moving as if the current itself is optional and mostly not worth the effort. His eyes are half-lidded, his fins drift more than swim.',
        ),
        StoryMessage(
          '...mm. Visitors.',
          character: StoryCharacter.somnus,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He says it like a fact he\'s noticing rather than a greeting.',
        ),
        StoryMessage(
          'Is it still today.',
          character: StoryCharacter.somnus,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It\'s still today, Somnus.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...good. I\'d hate to have slept through an entire visitor.',
          character: StoryCharacter.somnus,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He drifts, unbothered, already half-closing his eyes again.',
        ),
        StoryMessage(
          'Next comes a fish with fins that fan out into something between a threat and a decoration — sharp-edged, faintly barbed, held at an angle that suggests she\'s ready to be offended at any moment.',
        ),
        StoryMessage(
          'Why is there a whale-sized problem near the tree grounds.',
          character: StoryCharacter.stinger,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I didn\'t MEAN to—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You never mean to. That\'s the entire pattern of your existence, Hubert.',
          character: StoryCharacter.stinger,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...that\'s kind of harsh.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It\'s accurate. Petalblack likes accurate. I\'m just delivering it with less patience.',
          character: StoryCharacter.stinger,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A third arrives facing the wrong way — angled due north with a rigidity that suggests he\'d rather stay pointed that way than greet anyone properly.',
        ),
        StoryMessage(
          'North is that way.',
          character: StoryCharacter.polaro,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...okay?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I felt you should know. Most travelers don\'t know which way is north down here. It matters more than people think.',
          character: StoryCharacter.polaro,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Polaro. Say hello properly.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Hello. North is that way.',
          character: StoryCharacter.polaro,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 20),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Thank you, Polaro. That\'s good to know.',
          nextScene: 'ep5_seven_a',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: '[To Petalblack] Is he always like this?',
          nextScene: 'ep5_seven_b',
          statEffects: {'transience': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Why does north matter this deep down?',
          nextScene: 'ep5_seven_c',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[Just nod and let it be strange.]',
          nextScene: 'ep5_seven_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_seven_a',
      lines: const [
        StoryMessage(
          'Polaro turns, briefly, fully toward you — the first time he\'s fully faced anyone. It seems to cost him something.',
        ),
        StoryMessage(
          'You\'re welcome.',
          character: StoryCharacter.polaro,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause. Then he turns back north.'),
        StoryMessage(
          'It\'s still that way.',
          character: StoryCharacter.polaro,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_seven_halves',
    ),

    Scene(
      id: 'ep5_seven_b',
      lines: const [
        StoryMessage(
          'Always. He\'s been oriented north since before I can remember. Nobody\'s sure why. He\'s stopped being sure why.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I have my reasons. I just don\'t discuss them facing sideways.',
          character: StoryCharacter.polaro,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Polaro says this still facing away.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_seven_halves',
    ),

    Scene(
      id: 'ep5_seven_c',
      lines: const [
        StoryMessage(
          'Because everything eventually needs it. Currents. Migrations. Travelers who think they\'re lost and aren\'t, they\'re just facing the wrong way.',
          character: StoryCharacter.polaro,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause.'),
        StoryMessage(
          'You\'ll need it too. Later. Remember that north is patient. It doesn\'t move to find you. You have to move to find it.',
          character: StoryCharacter.polaro,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_seven_halves',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_seven_d',
      lines: const [
        StoryMessage(
          'You nod. Polaro, satisfied, does not turn back around, and somehow this feels like the correct outcome for everyone involved.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_seven_halves',
    ),

    Scene(
      id: 'ep5_seven_halves',
      lines: const [
        StoryMessage(
          'The fourth arrives already mid-sentence, as if he started talking before he\'d finished deciding what to say, and still hasn\'t quite managed to catch up with himself.',
        ),
        StoryMessage(
          '—so I heard there was a whale incident, hang on, wait, I already said that part—',
          character: StoryCharacter.halves,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '—whale incident, yes, that\'s what I meant, I heard there was a whale incident, did I say that already?',
          character: StoryCharacter.halves,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...twice, actually.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That happens. My thoughts arrive, and then they arrive again a moment later to make sure the first one landed properly. It\'s very efficient. It just sounds inefficient.',
          character: StoryCharacter.halves,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'This is Halves. Don\'t try to point out when he repeats himself. It only makes him do it slower, on purpose, to prove he meant it both times.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I absolutely do that. I did it just now. Did you catch it? I\'ll do it again—',
          character: StoryCharacter.halves,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Halves.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '—again, if you\'d like.',
          character: StoryCharacter.halves,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The fifth of the seven arrives late, small even by the standards of the others, darting in quick, excitable loops around the group before settling.',
        ),
        StoryMessage(
          'Wait wait wait, are these the SURFACE BIRDS? Real actual surface birds? I\'ve never seen a real one up close, is that a WING, can I touch the wing—',
          character: StoryCharacter.neofin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Neofin.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I\'m not gonna touch it! I\'m just gonna ask if I CAN, and then not do it, probably, unless they say yes, in which case I definitely will—',
          character: StoryCharacter.neofin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I like this one. This one\'s my favorite.',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The sixth of the seven doesn\'t come close at all. He hangs back at the very edge of the gold light, half-obscured by the tree\'s roots, close enough to be counted and no closer.',
        ),
        StoryMessage(
          'Solito. Come say hello properly.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I said it from here.',
          character: StoryCharacter.solito,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You didn\'t say anything from there.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I said it where I could hear myself say it. That should count for something.',
          character: StoryCharacter.solito,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He doesn\'t move any closer, and after a moment, nobody pushes him to.',
        ),
        StoryMessage(
          'Hello. Welcome. I hope it goes well for you, whatever it is you\'re here for.',
          character: StoryCharacter.solito,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That\'s the whole of it. He drifts back another few inches into the dark at the roots, watching, present, entirely unwilling to be any nearer than that.',
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '[To Neofin] You can touch the wing. Go ahead.',
          nextScene: 'ep5_seven_neofin_a',
          statEffects: {'vitality': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: '[To Neofin] How long have you been the youngest?',
          nextScene: 'ep5_seven_neofin_b',
          statEffects: {'connectivity': -1},
        ),
        SceneChoice(
          letter: 'C',
          label:
              '[To Petalblack] Seven of you, all this different. How does that work?',
          nextScene: 'ep5_seven_neofin_c',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[To the group] Thank you all for coming up to meet us.',
          nextScene: 'ep5_seven_neofin_d',
          statEffects: {'transience': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_seven_neofin_a',
      lines: const [
        StoryMessage(
          'Neofin darts forward and brushes a fin along your feathers with the reverent care of someone touching something they\'ve only heard about in stories.',
        ),
        StoryMessage(
          'It\'s SO SOFT, oh my gosh, Petalblack, feel this—',
          character: StoryCharacter.neofin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I\'m going to pass, but I appreciate the offer.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_descent',
    ),

    Scene(
      id: 'ep5_seven_neofin_b',
      lines: const [
        StoryMessage(
          'Forever! I mean — not forever forever, everyone else was around before me, but by the time you\'re down here long enough it stops mattering how long "forever" actually was.',
          character: StoryCharacter.neofin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...she\'s the newest by at least two centuries.',
          character: StoryCharacter.somnus,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'SEE, this is what I mean, "two centuries" is basically nothing to these guys!',
          character: StoryCharacter.neofin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_descent',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_seven_neofin_c',
      lines: const [
        StoryMessage(
          'We don\'t ask why we\'re each the way we are. We just are it, and it turns out seven different ways of paying attention cover more ground than one way would. Somnus notices what\'s slow to change. Stinger notices what\'s dangerous. Polaro notices direction. Halves notices everything twice, just to be sure the first time counted. Solito notices from far enough away that he sees the whole of a thing instead of just the part closest to him. Neofin notices what\'s new.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'What do you notice?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Whether something is worth the risk of bringing down. That\'s usually the last question, and someone has to ask it.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_descent',
    ),

    Scene(
      id: 'ep5_seven_neofin_d',
      lines: const [
        StoryMessage(
          '...mm. Welcome.',
          character: StoryCharacter.somnus,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Somnus says this already drifting off again.'),
        StoryMessage(
          'Don\'t make it a whole thing.',
          character: StoryCharacter.stinger,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You\'re welcome. North is still that way.',
          character: StoryCharacter.polaro,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I wouldn\'t have missed a whale incident for anything — did I already say "whale incident"? I feel like I already said "whale incident."',
          character: StoryCharacter.halves,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You\'re welcome.',
          character: StoryCharacter.solito,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Solito says this from the dark. Nothing more. That\'s the whole reply, and it\'s enough.',
        ),
        StoryMessage(
          'THIS IS THE BEST DAY OF MY LIFE.',
          character: StoryCharacter.neofin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_descent',
    ),

    // ─────────────────────────────────────────────
    // THE DESCENT
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_the_descent',
      lines: const [
        StoryMessage(
          'Petalblack gives a single low note, and the water around all of you begins to change.',
        ),
        StoryMessage(
          'It doesn\'t part so much as agree to hold still. A vast, trembling sphere of pressure and light forms around all of you — pushing the ocean back into a curved wall through which you can see the water without being in it. Lemon rests curled in the center of it, still asleep, her breathing slower and easier than it\'s been in days. Somewhere beyond the bubble\'s skin, seven small shapes flank its edges, guiding it down like something being lowered on an invisible thread. Above, blotting out what\'s left of the daylight, Hubert follows at a respectful distance, careful, for once, not to bump anything.',
        ),
        StoryMessage(
          'The bubble begins to sink.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'The light goes first. Not suddenly — gradually, the way the shore disappeared three days ago, the blue thinning by degrees until there is no blue left at all, only the deep, textured black of water that has never once been touched by sun.',
        ),
        StoryMessage('And then, in that black, things begin to glow.'),
        StoryMessage(
          'Small drifting motes, blue-green, pulsing faintly, rising past the bubble like slow inverted snow. Larger shapes further out — long, trailing things with lights strung along their length like something built rather than born. Once, far below, a shape passes that might be enormous and might simply be the dark playing games with your eyes; you don\'t ask, and nobody offers.',
        ),
        StoryMessage(
          'She hasn\'t stopped moving in three days. I don\'t think I\'ve seen her sleep since the shore.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Carlos says this quiet, watching Lemon sleep.'),
        StoryMessage(
          'Is it bad that this is the calmest I\'ve felt about her in a while?',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Sunny says this unusually subdued.'),
        StoryMessage(
          'No. I think it\'s just honest.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You pass what might be ruins — pale shapes half-buried in silt, too regular to be stone by accident, worn smooth by a weight of time you don\'t have a word large enough for. Nobody comments on them. It\'s possible even Petalblack doesn\'t know what they were.',
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 40),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Petalblack — how far down does she live?',
          nextScene: 'ep5_descent_a',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Are those ruins? Down there?',
          nextScene: 'ep5_descent_b',
          statEffects: {'stability': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: '[Say nothing. Just watch.]',
          nextScene: 'ep5_descent_c',
          statEffects: {'vitality': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'Does it get any less dark than this?',
          nextScene: 'ep5_descent_d',
          statEffects: {'connectivity': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_descent_a',
      lines: const [
        StoryMessage(
          'Far enough that the sun is a rumor. Far enough that most things that live nearer the surface would call this place the bottom of everything.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause.'),
        StoryMessage(
          'It isn\'t, of course. It\'s just the bottom of what they know.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_unnamed_tree_arrival',
    ),

    Scene(
      id: 'ep5_descent_b',
      lines: const [
        StoryMessage(
          'Something like that. Older than the tree, maybe. Older than us. We don\'t disturb them. Some questions aren\'t ours to answer, and I\'ve learned not to mind that.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_unnamed_tree_arrival',
    ),

    Scene(
      id: 'ep5_descent_c',
      lines: const [
        StoryMessage(
          'You watch the dark go by, glowing and slow, and something in you goes quiet in a way it hasn\'t since Dawn\'s branch first appeared in your inventory. Not fear. Something closer to reverence.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_unnamed_tree_arrival',
    ),

    Scene(
      id: 'ep5_descent_d',
      lines: const [
        StoryMessage(
          'You\'ll see.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She doesn\'t explain further, and a moment later, you understand why.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_unnamed_tree_arrival',
    ),

    // ─────────────────────────────────────────────
    // THE UNNAMED TREE — ARRIVAL
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_unnamed_tree_arrival',
      lines: const [
        StoryMessage(
          'A light appears ahead — not blue-green like the drifting motes, but warm. Gold. Old.',
        ),
        StoryMessage(
          'The bubble tilts, following it down, and slowly, the shape resolves.',
        ),
        StoryMessage(
          'An enormous tree, rooted not in soil but in stone, in silt, in the accumulated weight of centuries of ocean floor. Its trunk is wider than the widest ancient oak you\'ve ever seen or heard described, pale where the light touches it, fading to black where it doesn\'t. Its branches spread not upward — there is no upward here, no sky to reach for — but outward, sideways, a slow and patient sprawl across the sea floor, hung with the same soft gold light that drew you in, glowing faintly from within the bark itself, like something that has been quietly burning for longer than fire has had a name.',
        ),
        StoryMessage(
          'The Unnamed Tree.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'The bubble settles gently at the base of her roots, and for a long moment, nobody speaks. Even Sunny, remarkably, has nothing to say.',
        ),
        StoryMessage(
          'Beside you, Lemon stirs. Her eyes open slowly, unhurried, the gold light of the roots moving across her face before she\'s even fully awake.',
        ),
        StoryMessage(
          '...why does it smell like warm stone. Where are we. Why is there a tree the size of the sky.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You fainted. We\'re at the bottom of the ocean. There\'s a tree the size of the sky.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...that tracks, actually.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She pushes herself upright, steadier already than she has any right to be, and goes quiet — properly quiet, taking in the size and the age and the gold light of the thing in front of her, the way everyone eventually goes quiet in front of the Unnamed Tree.',
        ),
        StoryMessage(
          'Then the tree\'s voice arrives — not sound exactly, more a kind of warmth that moves through the water the way heat moves through still air, felt before it\'s heard.',
        ),
        StoryMessage(
          'Little bird.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You\'ve come a long way to stand in the dark and look at an old tree.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I — yes. Petalblack brought us. I have—',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I know what you have. I\'ve known since before Petalblack surfaced to check on that pink fish of hers.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'There\'s no unkindness in the interruption. Just the calm certainty of something that has stopped needing to wait for information to arrive; it simply already has.',
        ),
        StoryMessage(
          'Dawn\'s Seed. Still warm. Still asking. That\'s rarer than you\'d think — most seeds that travel this far have gone cold by now, in one way or another.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 20),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'You know Dawn?',
          nextScene: 'ep5_tree_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Petalblack said you don\'t have a name. Is that true?',
          nextScene: 'ep5_tree_b',
          statEffects: {'transience': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Can you help me reach the gr0ve?',
          nextScene: 'ep5_tree_c',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'You said "in one way or another." What does that mean?',
          nextScene: 'ep5_tree_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_tree_a',
      lines: const [
        StoryMessage(
          'I know of him. I know of most things that have burned for a long time in one place. I never met him directly — he kept to his threshold, and I keep to my dark, and the world is large enough that even old things don\'t cross every path.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_tree_witnessed',
    ),

    Scene(
      id: 'ep5_tree_b',
      lines: const [
        StoryMessage(
          'It\'s true that I don\'t offer one. Whether that\'s the same as not having one — I\'ve stopped being certain, and I\'ve had a very long time to become certain of things, which should tell you something.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause, gentle, almost amused.'),
        StoryMessage(
          'Names are for being found. I stopped needing to be found a long time before your kind of bird existed.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_tree_witnessed',
    ),

    Scene(
      id: 'ep5_tree_c',
      lines: const [
        StoryMessage(
          'Bird. You ask the wrong question.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The words land soft, but they land completely — the way water finds every gap in a container, not by force, simply by patience.',
        ),
        StoryMessage(
          'You\'ll understand why, before we\'re done talking.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_tree_witnessed',
    ),

    Scene(
      id: 'ep5_tree_d',
      lines: const [
        StoryMessage(
          'Some seeds go cold because they\'re forgotten. Left somewhere and never carried further. Others go cold because they were carried too fast, by someone who never once stopped to ask what they were carrying, or why. Yours is still warm because you keep asking. Keep doing that.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_tree_witnessed',
    ),

    // ─────────────────────────────────────────────
    // WHAT SHE HAS WITNESSED
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_tree_witnessed',
      lines: const [
        StoryMessage(
          'I am not like the willow who wept beside the frozen lake. I do not hold memory the way she holds it — sharp, precise, aching. And I am not like the tree who read your branch and told you its story in growth rings. I do not hold history that way either — organized, countable, explainable.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I have simply watched. For longer than either of them has existed. I watched the first forests take root. I watched every ancient tree be born, grow, and become whatever it was going to become. I watched the gr0ve, once, when it still let itself be watched.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'What happened to it? The gr0ve?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A long pause. The gold light along her bark pulses once, slow, like a held breath.',
        ),
        StoryMessage(
          'The gr0ve was never lost.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It simply stopped allowing itself to be found.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 30),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Why would it hide from the world?',
          nextScene: 'ep5_witnessed_a',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Was it always hidden? Even at the beginning?',
          nextScene: 'ep5_witnessed_b',
          statEffects: {'transience': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Is there something guarding it?',
          nextScene: 'ep5_witnessed_c',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'What was it like? Before it hid?',
          nextScene: 'ep5_witnessed_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_witnessed_a',
      lines: const [
        StoryMessage(
          'Because for a very long time, every river, every current, every path in this world led toward it. That kind of centrality is a kind of power. And power, little bird, is rarely left alone by those who want it for themselves.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause, heavier.'),
        StoryMessage(
          'It was abused. Not by strangers. By those closest to it, who convinced themselves closeness was the same thing as right. The gr0ve chose, in the end, to close itself rather than keep being taken from.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_tree_mystery',
    ),

    Scene(
      id: 'ep5_witnessed_b',
      lines: const [
        StoryMessage(
          'No. Once, you could walk toward it from anywhere and eventually arrive. That\'s not true anymore, and hasn\'t been for longer than most living things can measure.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_tree_mystery',
    ),

    Scene(
      id: 'ep5_witnessed_c',
      lines: const [
        StoryMessage(
          'Yes.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She doesn\'t elaborate immediately. The silence that follows feels deliberate — the silence of someone choosing, carefully, exactly how much to say.',
        ),
        StoryMessage(
          'A guardian still watches over what remains. I won\'t tell you who. Not because I\'m testing you — I\'ve simply learned that some things are only understood correctly when they\'re found rather than told.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_tree_mystery',
    ),

    Scene(
      id: 'ep5_witnessed_d',
      lines: const [
        StoryMessage(
          'Alive in a way I don\'t have words generous enough to give you. Aspen connected everything that touched her roots. Rowan illuminated the roads that led travelers home. Grover endured at the center of it all, holding the shape of the place together simply by continuing to exist. Sakura understood endings before they arrived — she always knew a season was closing before anyone else could feel the chill of it.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A pause, wistful in a way that doesn\'t quite fit a being this old and this calm, which makes it land harder.',
        ),
        StoryMessage(
          'I watched all of that. I don\'t expect you to understand it from four sentences. I mention it so you know it existed. So you know what was lost, even if you never learn all of how.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_tree_mystery',
    ),

    // ─────────────────────────────────────────────
    // THE MYSTERY / THE TWIST
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_tree_mystery',
      lines: const [
        StoryMessage(
          'There is something else. Something you should know before you go further, though I suspect it will only give you more questions than it answers.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Long after the gr0ve closed itself, something found it anyway. Not tree. Not bird. Not beast — not anything I have a clean word for. It came from somewhere I did not watch closely enough to name, and it still rests beneath the guardian\'s shade, even now.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'What is it?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I don\'t know.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She says this plainly, without embarrassment — the flat honesty of something that has never once needed to pretend at knowledge it doesn\'t have.',
        ),
        StoryMessage(
          'That may be the only true mystery I\'ve kept in all my centuries of watching. I offer it to you not as an answer, but as a warning: whatever waits beneath the guardian\'s shade, it is old, it is patient, and it has been resting there since before your kind had a word for patience at all.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 15),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'That\'s not very reassuring.',
          nextScene: 'ep5_mystery_a',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Should I be afraid of it?',
          nextScene: 'ep5_mystery_b',
          statEffects: {'stability': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Does the guardian know what it is?',
          nextScene: 'ep5_mystery_c',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[Sit with that for a moment before responding.]',
          nextScene: 'ep5_mystery_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_mystery_a',
      lines: const [
        StoryMessage(
          'I\'m not in the business of reassurance, little bird. I\'m in the business of having watched things happen. Reassurance is a kindness I leave to trees who deal in comfort. I deal in what\'s true.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_twist',
    ),

    Scene(
      id: 'ep5_mystery_b',
      lines: const [
        StoryMessage(
          'I don\'t know that either. Fear is a useful thing when it\'s pointed at the right target and a wasted thing when it isn\'t. I can\'t tell you yet which this is.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_twist',
    ),

    Scene(
      id: 'ep5_mystery_c',
      lines: const [
        StoryMessage(
          'Better than I do, certainly. The guardian has stood closer to it for longer than I\'ve had reason to think about it at all. But that\'s a question for when you meet the guardian. Not for now, and not for me.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_twist',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_mystery_d',
      lines: const [
        StoryMessage(
          'You don\'t say anything for a while. Something not-tree, not-bird, not-beast, resting under a guardian\'s shade for longer than "patience" has had a name. You decide, quietly, that you\'ll think about this again later — probably at night, probably when you\'re trying to sleep, probably for the rest of your life.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_the_twist',
    ),

    // ─────────────────────────────────────────────
    // THE TWIST — THREE LIGHTS
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_the_twist',
      lines: const [
        StoryMessage(
          'You asked, earlier, if I could help you reach the gr0ve. I told you that was the wrong question. Here is why.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Countless birds have carried seeds this far. Some carried them further than you have. A few carried them all the way to where the gr0ve should be, by every measure and every direction available to them.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'None of them succeeded.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...why not?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Because what you seek is not the gr0ve. Not yet. If I showed it to you now — if I gave you the exact place, the exact path, and set you flying straight toward it — you would fail all the same.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 20),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Then what am I actually looking for?',
          nextScene: 'ep5_twist_a',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Why would I fail? I\'ve made it this far.',
          nextScene: 'ep5_twist_b',
          statEffects: {'vitality': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Is the seed not enough on its own?',
          nextScene: 'ep5_twist_c',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label:
              'How do you know all those birds failed, if the gr0ve doesn\'t let itself be found?',
          nextScene: 'ep5_twist_d',
          statEffects: {'connectivity': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_twist_a',
      lines: const [
        StoryMessage(
          'Dawn\'s Seed is incomplete. It carries the light of the threshold — the space between day and night, which is a true and important light, but only one of several the gr0ve was built from.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_twist_reveal',
    ),

    Scene(
      id: 'ep5_twist_b',
      lines: const [
        StoryMessage(
          'Because a door built for four keys does not open for one, no matter how bright that one key burns. You\'ve made it this far on Dawn\'s light alone. That was never going to be enough to finish the journey — only enough to begin it.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_twist_reveal',
    ),

    Scene(
      id: 'ep5_twist_c',
      lines: const [
        StoryMessage(
          'Not alone. It was never meant to be carried alone, not truly — it was meant to be carried alongside what the other ancient trees still hold, each of them their own fading light.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_twist_reveal',
    ),

    Scene(
      id: 'ep5_twist_d',
      lines: const [
        StoryMessage(
          'Because the gr0ve is still closed, little bird. If any of them had opened it, you would already know. The world would look different than it does.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_twist_reveal',
    ),

    Scene(
      id: 'ep5_twist_reveal',
      lines: const [
        StoryMessage(
          'Three others still hold a light of their own, though each of them has faded, in their own way, over time. You\'ve already begun to hear their names, I think, carried to you on other tongues.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'One keeps what came before. One understands what is, plainly and without illusion. One still imagines what has not yet happened. Each once held a piece of what the gr0ve needs to open again. Each still holds it now, buried under whatever the years have done to them.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Find them. Gather what they carry, alongside what Dawn already gave you. Only then will the question of reaching the gr0ve be worth asking me, or anyone.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...that\'s a lot more than I thought I was doing when I picked up one seed.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Most important things are.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 15),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Where do I start? Who\'s closest?',
          nextScene: 'ep5_twist_where',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Do you know their names?',
          nextScene: 'ep5_twist_names',
          statEffects: {'connectivity': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'Will you tell me more, if I come back?',
          nextScene: 'ep5_twist_comeback',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[Just nod. Let it settle.]',
          nextScene: 'ep5_twist_nod',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_twist_where',
      lines: const [
        StoryMessage(
          'Hubert will take you as far as the frozen ocean. There is ice there, and something frozen within it that has waited a very long time for someone to arrive who still remembers how to ask the right question. Beyond that, I can\'t carry you further. My roots don\'t reach that far, even in the dark.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_vessel_branch',
    ),

    Scene(
      id: 'ep5_twist_names',
      lines: const [
        StoryMessage(
          'I know pieces. I\'ve heard them carried by travelers over centuries, the way a current carries silt — worn down, incomplete, but not entirely lost. You\'ll find the full shape of each name where you find each tree. That\'s how names work, I\'ve noticed. They complete themselves in the presence of the thing they belong to.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_vessel_branch',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_twist_comeback',
      lines: const [
        StoryMessage(
          'Perhaps. I don\'t make many promises, little bird — I\'ve watched too many go unkept by things far grander than me to trust my own easily. But I will say this: I don\'t often let the same traveler through my dark twice without reason. If you come back, it will mean something happened worth hearing about.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_vessel_branch',
    ),

    Scene(
      id: 'ep5_twist_nod',
      lines: const [
        StoryMessage(
          'You nod, slowly, feeling the shape of the task settle onto you the way the Warming Pouch settled against your side back on the beach — heavier than you expected, and somehow also exactly the right weight to carry.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_vessel_branch',
    ),

    // ─────────────────────────────────────────────
    // VESSEL BRANCH — checks if player has Loulo's Pot
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_vessel_branch',
      lines: const [
        StoryMessage(
          'The Unnamed Tree\'s attention shifts, briefly, to the space at your side.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_vessel',
      onEnter: (state) {
        // Branch based on whether player already has Loulo's Pot
        if (state.inventory.contains("Loulo's Pot")) {
          state.pendingScene = 'ep5_vessel_final';
        } else {
          state.pendingScene = 'ep5_vessel_offer';
        }
      },
    ),

    // ─────────────────────────────────────────────
    // THE VESSEL — has Loulo's Pot path
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_vessel',
      lines: const [
        StoryMessage(
          'The Unnamed Tree\'s attention shifts, briefly, to the sea-glass warmth of the pot at your side.',
        ),
        StoryMessage(
          'You already carry a vessel. Loulo\'s, unless I misjudge the pink of it — and I rarely do, even down here, even after all this time.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Yes. She gave it to me before the crossing.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Then I won\'t offer you another. A traveler who carries two vessels for the same purpose usually ends up trusting neither of them fully. Keep hers. Intention is not a small thing to carry, and she chose well in choosing you to carry it.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_vessel_final',
    ),

    // ─────────────────────────────────────────────
    // THE VESSEL — no vessel path (offer)
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_vessel_offer',
      lines: const [
        StoryMessage(
          'The Unnamed Tree is quiet for a moment, and then something shifts among her lowest roots — a small motion, patient, unhurried.',
        ),
        StoryMessage(
          'You carry no vessel yet. I have one to offer, if you\'ll take it.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A shape rises from the silt at the base of her trunk — round, translucent, the pale blue-green of deep water caught and cooled into something solid. Sea glass, worn smooth by centuries of current, glowing faintly from whatever light still lives inside her roots.',
        ),
        StoryMessage(
          'Loulo\'s held intention. Mine holds something else. A witness learns, eventually, that the rarest thing in this world isn\'t wanting something, or knowing something. It\'s simply staying to see how it turns out. This holds attention — the choosing, over and over, to keep watching something through to its end, instead of looking away when it gets difficult.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 15),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'That\'s a strange thing to put in a pot.',
          nextScene: 'ep5_vessel_strange',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Why give it to me, and not keep it yourself?',
          nextScene: 'ep5_vessel_why',
          statEffects: {'connectivity': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: '[Say nothing. Just look at it.]',
          nextScene: 'ep5_vessel_look',
          statEffects: {'stability': 1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_vessel_strange',
      lines: const [
        StoryMessage(
          'Most true things are strange until you\'ve carried them a while.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_vessel_decision',
    ),

    Scene(
      id: 'ep5_vessel_why',
      lines: const [
        StoryMessage(
          'Because I\'ve already spent my attention on everything, little bird. That\'s what watching for this long means. I have none left over to concentrate — only the wide, general kind. You\'re going somewhere that will need the narrow kind. The kind that fixes on one small, difficult thing and does not let it go.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_vessel_decision',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_vessel_look',
      lines: const [
        StoryMessage(
          'You look at it a while longer instead of answering — the pale blue-green of it, the faint light moving inside. The Unnamed Tree doesn\'t rush you.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_vessel_decision',
    ),

    Scene(
      id: 'ep5_vessel_decision',
      lines: const [
        StoryMessage(
          'Well, little bird? Will you carry it?',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'I\'ll take it. Thank you.',
          nextScene: 'ep5_vessel_take',
          addItems: ["Sea-Glass Vessel"],
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'No, thank you. I don\'t think I should carry it.',
          nextScene: 'ep5_vessel_decline',
          statEffects: {'transience': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_vessel_take',
      lines: const [
        StoryMessage(
          'Then it\'s yours.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '[Sea-Glass Vessel obtained | Cool, pale blue-green, worn smooth by centuries of current. Holds attention. Remembers what you chose not to look away from.]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_vessel_final',
      onEnter: (state) {
        state.intentionVessel = 'unnamedTree';
      },
    ),

    Scene(
      id: 'ep5_vessel_decline',
      lines: const [
        StoryMessage(
          'The Unnamed Tree doesn\'t press you. If anything, something in her stillness seems to approve of the refusal itself.',
        ),
        StoryMessage(
          'That\'s an answer too. Not every bird is meant to carry every vessel offered to them — sometimes the honest thing is knowing which ones aren\'t yours to hold yet. Keep going as you are. There will be another chance, further north, if you find you want one after all.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'No vessel obtained. You continue on carrying only what you already had.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_vessel_final',
    ),

    Scene(
      id: 'ep5_vessel_final',
      lines: const [
        StoryMessage(
          'One more thing, before Hubert takes you north.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You will be offered another vessel before this is over. Whichever one you carry now, you may set it down for that one, if it doesn\'t feel right when you\'re holding it. That choice will still be yours to make.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A pause. The gold light along her bark dims, just slightly — the closest thing to solemn you\'ve seen from her yet.',
        ),
        StoryMessage(
          'But I don\'t believe you\'ll be given the choice to refuse the last one. Some things, by the time you reach them, insist on being carried whether you agree to it or not. I only tell you now so it doesn\'t surprise you later. Surprise is wasted on things you could have been told in advance.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_huberts_task',
      waitDuration: const Duration(minutes: 15),
    ),

    // ─────────────────────────────────────────────
    // HUBERT'S TASK
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_huberts_task',
      lines: const [
        StoryMessage(
          'Hubert.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Yes! Hello! Present!',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Hubert says this immediately attentive, in the particular way of someone who has been waiting the whole conversation to be given a job.',
        ),
        StoryMessage(
          'Carry them north. As far as the ice allows you. You know the place — Frigid Landfall, where the water stops being water and starts being something harder.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I know it! I go there every year! Well — I go NEAR there. I don\'t love the cold part.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Nobody loves the cold part, Hubert. That\'s why it\'s called the cold part.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I can take them right up to where it starts! And then — after that, they have to keep going without me, because I don\'t have legs, or feet, or any part that works well on ice, I\'ve thought about this a lot—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 15),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '[To Hubert] Thank you. I mean it.',
          nextScene: 'ep5_hubert_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: '[To Petalblack] Will you come too? Any of you?',
          nextScene: 'ep5_hubert_b',
          statEffects: {'vitality': -1},
        ),
        SceneChoice(
          letter: 'C',
          label:
              '[To Hubert] Can you eat anything along the way, or is that still a no?',
          nextScene: 'ep5_hubert_c',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[To the Unnamed Tree] Will I see you again?',
          nextScene: 'ep5_hubert_d',
          statEffects: {'stability': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_hubert_a',
      lines: const [
        StoryMessage(
          'You\'re WELCOME! This is the most important job I\'ve ever had! Well — second most important. The first was the time Petalblack asked me to guard a rock for a whole afternoon.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That rock was very important, Hubert.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'IT WAS.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_farewells',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_hubert_b',
      lines: const [
        StoryMessage(
          'No. We stay with the tree. That\'s the whole of what we are — we don\'t leave her, not for long, not for anyone. But Hubert can go further than any of us. He always has. It\'s why we ask him.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I go EVERYWHERE! Within reason! Within the reason of a whale, which is a slightly different reason than most reasons!',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_farewells',
    ),

    Scene(
      id: 'ep5_hubert_c',
      lines: const [
        StoryMessage(
          'Can I—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Hubert says this hopefully.'),
        StoryMessage(
          'No.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You didn\'t even let me FINISH—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I didn\'t need to. I know every version of that sentence you\'re capable of building, Hubert. The answer is no to all of them.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Hubert says this quietly, to you:'),
        StoryMessage(
          '...she\'s usually right. It\'s very annoying.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_farewells',
    ),

    Scene(
      id: 'ep5_hubert_d',
      lines: const [
        StoryMessage(
          'Perhaps. As I said — I don\'t make promises easily. But the dark down here is patient, and so am I, and if your path brings you back this way, I\'ll know before Petalblack even surfaces to check.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause, almost gentle.'),
        StoryMessage(
          'Go well, little bird. Carry what you\'re carrying carefully. And remember — the wrong question, asked honestly, is still worth more than a right question asked out of habit.',
          character: StoryCharacter.unnamedTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_farewells',
    ),

    // ─────────────────────────────────────────────
    // FAREWELLS IN THE DARK
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_farewells',
      lines: const [
        StoryMessage('The bubble begins to climb.'),
        StoryMessage(
          'The seven of them gather to watch you go — or six of them gather, and Solito stays exactly where he was, at the very edge of the gold light, watching from there instead. Somnus drifting half-asleep at the edge, Stinger holding her fins at their usual sharp angle, Polaro still faithfully oriented north, Halves quietly repeating his own last sentence to make sure it landed, Neofin darting in one last excited loop, Solito watching silently from the dark at the roots, and Petalblack, still, at the center of all of it, exactly where she\'s clearly been standing — figuratively, since fish don\'t stand — for longer than anyone else has been alive.',
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 20),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Petalblack — thank you. For all of this.',
          nextScene: 'ep5_farewell_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'I don\'t think I ever thanked Somnus for waking up.',
          nextScene: 'ep5_farewell_b',
          statEffects: {'transience': -1},
        ),
        SceneChoice(
          letter: 'C',
          label:
              '[To Stinger] You never really said much. Was that on purpose?',
          nextScene: 'ep5_farewell_c',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'D',
          label:
              '[To Neofin] I hope you get to see more surface birds someday.',
          nextScene: 'ep5_farewell_d',
          statEffects: {'vitality': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_farewell_a',
      lines: const [
        StoryMessage(
          'You\'re welcome. Come back if you need to. We\'ll be here. We\'re always here. That\'s rather the arrangement.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A pause, and something that might be the fish equivalent of a small smile.',
        ),
        StoryMessage(
          'Try not to let Hubert eat anything important on the way.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I HEARD THAT—',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Hubert says this distantly, already swimming ahead.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_back_to_light',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_farewell_b',
      lines: const [
        StoryMessage(
          '...you\'re welcome. For whatever it was.',
          character: StoryCharacter.somnus,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Somnus says this barely opening his eyes.'),
        StoryMessage(
          'He wasn\'t awake for most of the conversation.',
          character: StoryCharacter.stinger,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I was awake for the important parts. I sleep selectively.',
          character: StoryCharacter.somnus,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_back_to_light',
    ),

    Scene(
      id: 'ep5_farewell_c',
      lines: const [
        StoryMessage(
          'Mostly. Someone has to notice what\'s dangerous instead of talking about it. Talking is Petalblack\'s job. Noticing is mine.',
          character: StoryCharacter.stinger,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('A pause, almost warmer than her usual tone.'),
        StoryMessage(
          'You weren\'t dangerous. That\'s why I let you get this close without saying anything about it.',
          character: StoryCharacter.stinger,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_back_to_light',
    ),

    Scene(
      id: 'ep5_farewell_d',
      lines: const [
        StoryMessage(
          'ME TOO! Tell them all about me if you see any more! Tell them Neofin says hi! Tell them the wings are SO SOFT—',
          character: StoryCharacter.neofin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Neofin. Let them go.',
          character: StoryCharacter.petalblack,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Right, sorry, bye, GOOD LUCK, COME BACK SOMETIME—',
          character: StoryCharacter.neofin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_back_to_light',
    ),

    // ─────────────────────────────────────────────
    // BACK TO THE LIGHT
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_back_to_light',
      lines: const [
        StoryMessage(
          'The bubble climbs the way it descended — slow, patient, guided by unseen fins somewhere far below. The glowing motes drift past you again, this time rising alongside you rather than past you going down. The pale ruins fall away into the dark behind. And eventually, gradually, the black begins to soften.',
        ),
        StoryMessage(
          'Blue returns first as a suggestion. Then a certainty. Then, all at once, the surface breaks around you and the world is bright and loud and full of wind again, and you are floating on open ocean with Lemon, Carlos, and Sunny beside you, all of you blinking against a sun that feels, after the deep, almost too honest to look at directly.',
        ),
        StoryMessage(
          'That was the BEST DAY. I got eaten AND I met an underwater tree. Nobody is going to believe this.',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You weren\'t eaten.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I was HELD IN A MOUTH—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'We know, Sunny.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I fainted. In front of a whale. And a tree older than the concept of time.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Lemon says this quieter, mostly to herself.'),
        StoryMessage(
          'You needed it.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I know. That doesn\'t make it less embarrassing.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'IT WAS A LITTLE FUNNY—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Sunny.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '—a little!',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Hubert\'s back breaks the surface nearby, an entire gray hillside of a creature turning gently, carefully, so as not to splash anyone this time.',
        ),
        StoryMessage(
          'Everyone ready? I go slow at first! And I ask permission before I dive, so nobody gets a surprise whale-mouth situation again!',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'We appreciate that.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...how do we get on him?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'However you\'d like! I have a very large back! There\'s room for opinions!',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 40),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Land on Hubert\'s back and settle in.',
          nextScene: 'ep5_board_a',
          statEffects: {'vitality': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Are you sure this is comfortable for you?',
          nextScene: 'ep5_board_b',
          statEffects: {'connectivity': -1},
        ),
        SceneChoice(
          letter: 'C',
          label:
              '[To Lemon, Carlos, and Sunny] This is where you three turn back, isn\'t it?',
          nextScene: 'ep5_board_c',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '[Take one last look down at the water before boarding.]',
          nextScene: 'ep5_board_d',
          statEffects: {'transience': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_board_a',
      lines: const [
        StoryMessage(
          'You drop onto the wide gray plain of Hubert\'s back. It\'s warm, in an odd way — sun-heated skin over something enormous and alive — and surprisingly stable, like standing on a very slow-moving island.',
        ),
        StoryMessage(
          'Comfortable? Say the word if you need anything adjusted! I can flex certain areas!',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '...I\'ll let you know.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_departure',
    ),

    Scene(
      id: 'ep5_board_b',
      lines: const [
        StoryMessage(
          'Oh, very! I love having passengers! It gets lonely, being this big. Petalblack says I take up too much room for company most of the time. It\'s nice when someone doesn\'t mind.',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_departure',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_board_c',
      lines: const [
        StoryMessage('Lemon\'s expression does something complicated.'),
        StoryMessage(
          'It is. We fly the southern water. This is as far north as we go.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You\'ll be fine with Hubert. He\'s slow, but he\'s careful, and careful matters more than fast out here.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Come back and tell us EVERYTHING! Especially the whale parts, since I have the most experience with those—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You have exactly one experience with those, Sunny.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'One GREAT experience.',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_departure',
    ),

    Scene(
      id: 'ep5_board_d',
      lines: const [
        StoryMessage(
          'You look down at the water one more time before boarding — flat, blue, giving nothing away, exactly as unreadable now as it was three days ago. Somewhere far beneath it, seven small lights are already settling back into their slow, eternal circle around a tree that has watched everything and told you only some of it.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_departure',
    ),

    // ─────────────────────────────────────────────
    // DEPARTURE
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_departure',
      lines: const [
        StoryMessage(
          'We\'ll tell Karl and Loulo you made it this far. They\'ll want to know.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Tell whatever you meet next that a seagull sends regards. It rarely helps, but it\'s never once hurt.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'And tell THEM about the whale thing! In detail! Accurately, meaning: very dramatically!',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      waitDuration: const Duration(minutes: 15),
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'I will. Thank you — for the crossing, for all of it.',
          nextScene: 'ep5_departure_a',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'B',
          label: 'Lemon — take care of them.',
          nextScene: 'ep5_departure_b',
          statEffects: {'vitality': -1},
        ),
        SceneChoice(
          letter: 'C',
          label: 'I\'ll come back this way. I mean that.',
          nextScene: 'ep5_departure_c',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'D',
          label:
              '[Say nothing. Just look at the three of them for a long moment.]',
          nextScene: 'ep5_departure_d',
          statEffects: {'transience': -1},
        ),
      ],
    ),

    Scene(
      id: 'ep5_departure_a',
      lines: const [
        StoryMessage(
          'You\'re welcome. Fly safe, little bird. The cold ahead doesn\'t forgive mistakes the way the ocean sometimes does.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_edge',
      onEnter: (state) {
        state.connectivity -= 1;
      },
    ),

    Scene(
      id: 'ep5_departure_b',
      lines: const [
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
          'Just let her have this one. It\'s easier.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Fine. Yeah. We do.',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Sunny says this grinning.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_edge',
    ),

    Scene(
      id: 'ep5_departure_c',
      lines: const [
        StoryMessage(
          'Good. We\'ll hold you to that.',
          character: StoryCharacter.lemon,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The ocean\'s patient. It\'ll still be here.',
          character: StoryCharacter.carlos,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'AND SO WILL WE, PROBABLY, UNLESS WE\'RE FISHING—',
          character: StoryCharacter.sunny,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_edge',
      onEnter: (state) {
        state.connectivity += 1;
      },
    ),

    Scene(
      id: 'ep5_departure_d',
      lines: const [
        StoryMessage(
          'You look at the three of them — Lemon, steady and tired and endlessly responsible; Carlos, quiet and noticing everything; Sunny, still damp, still grinning, somehow entirely unbothered by having been recently inside a whale. You don\'t say anything, because there isn\'t really anything better to say than the moment itself.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_edge',
    ),

    // ─────────────────────────────────────────────
    // THE EDGE — NORTHWARD
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_edge',
      lines: const [
        StoryMessage(
          'The three gulls lift off the water together, circling once above you and Hubert, and then bank south — back toward the beach, toward Karl and his sideways patience, toward Loulo standing pink and certain against the tide.',
        ),
        StoryMessage(
          'You watch them go until they\'re small. Then smaller. Then gone.',
        ),
        StoryMessage(
          'You have been flying — and now riding — for a long time. You have met a fish who leads by simply being the one who decides, and a whale who asks permission for everything and receives it almost never. You have met six other guardians who each notice a different piece of the world, and a tree older than memory itself, who told you the truth by telling you what she didn\'t know.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'You are going north now. Toward the ice. Toward whatever is frozen there, waiting, the way Petalblack said it would be — for someone who still remembers how to ask the right question.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage('Hubert turns, patient and enormous, and begins to swim.'),
        StoryMessage(
          'North! I know the way! Mostly! Polaro would be so proud of me right now!',
          character: StoryCharacter.hubert,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The wind picks up. The water streams past Hubert\'s sides in long white lines. Somewhere behind you, the warm gold-lit dark keeps its slow, ancient watch. Somewhere ahead, the ocean is already beginning, by degrees too small to notice yet, to turn cold.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep5_complete',
      waitDuration: const Duration(minutes: 10),
    ),

    // ─────────────────────────────────────────────
    // EPISODE COMPLETE
    // ─────────────────────────────────────────────
    Scene(
      id: 'ep5_complete',
      lines: const [
        StoryMessage(
          'EPISODE COMPLETE: THE UNNAMED WATERS',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage(
          'The ice is close now. Closer than it has ever been.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'Somewhere within it, something frozen still remembers how to wait.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'Frigid Landfall awaits...',
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
