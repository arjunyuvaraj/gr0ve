import 'package:gr0ve/features/grove/models/grove_models.dart';

List<Scene> buildEpisode02WeepingWillow() {
  return [
    Scene(
      id: 'ep2_intro',
      lines: const [
        StoryMessage(
          'EPISODE 2: THE WEEPING WILLOW',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage(
          'You follow the river out of the orchard. It\'s a lovely flight! The wind is at your back, the sun is shining... until it suddenly isn\'t.',
        ),
        StoryMessage(
          'Wait, where did the sun go? Why does the water look like liquid gloom?',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The river dumps you out onto the shores of a massive, misty lake. And wow, the landscaping here is terrible.',
        ),
        StoryMessage(
          'Massive chasms cut through the ground like someone dropped a giant, heavy sadness bomb right in the center of the lake.',
        ),
        StoryMessage(
          '10/10 would not recommend this place for a vacation.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Near the shore, an ancient weeping willow bows its branches over the water. It looks like it needs a hug. Or a really big tissue.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep2_sheep_encounter_1',
      waitDuration: const Duration(minutes: 30),
    ),

    Scene(
      id: 'ep2_sheep_encounter_1',
      lines: const [
        StoryMessage(
          'As you settle onto the damp grass, you hear the soft rustle of hooves.',
        ),
        StoryMessage(
          'A small flock of sheep emerges from the meadow. Three of them trot forward, entirely unafraid. They have strange, colorful coats.',
        ),
        StoryMessage(
          'A bird! And it\'s glowing! Look, Woolberry, it has a glowing stick.',
          character: StoryCharacter.bluebellSheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I see it, Bluebell. Don\'t crowd the poor thing. It looks exhausted. What brings a bird of dawn to Lake Lament?',
          character: StoryCharacter.woolberrySheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Lake Lament! Lake of sorrow, lake of tears, lake of broken things!',
          character: StoryCharacter.thicketSheep,
          kind: MessageKind.dialogue,
          isItalic: true,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"I\'m searching for the gr0ve. I have a seed to plant."',
          nextScene: 'ep2_sheep_grove_talk',
        ),
        SceneChoice(
          letter: 'B',
          label: '"What happened to this land? Why is it broken?"',
          nextScene: 'ep2_sheep_broken_talk',
        ),
      ],
    ),

    Scene(
      id: 'ep2_sheep_grove_talk',
      lines: const [
        StoryMessage(
          'The gr0ve! Oh, my. That\'s a long way from here.',
          character: StoryCharacter.bluebellSheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'We know the grass. We know the streams. We know where the sweetest clover grows before the frost hits.',
          character: StoryCharacter.woolberrySheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But the deep places? The roots of the world? That\'s ancient business! Tree business!',
          character: StoryCharacter.thicketSheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'If you seek the gr0ve, you must ask the Willow. Salix. He remembers the old network. He remembers Abies.',
          character: StoryCharacter.woolberrySheep,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep2_sheep_salix_point',
    ),

    Scene(
      id: 'ep2_sheep_broken_talk',
      lines: const [
        StoryMessage(
          'Broken! Shattered! Wept apart!',
          character: StoryCharacter.thicketSheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Thicket is right, though he lacks tact. The earth didn\'t break from an earthquake. It broke from sorrow.',
          character: StoryCharacter.woolberrySheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The Willow wept. Salix wept so hard that his tears turned to heavy crystal. They struck the ground and cracked the world open.',
          character: StoryCharacter.bluebellSheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You should ask Salix himself. But tread carefully. His grief is older than our entire flock.',
          character: StoryCharacter.woolberrySheep,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep2_sheep_salix_point',
    ),

    Scene(
      id: 'ep2_sheep_salix_point',
      lines: const [
        StoryMessage(
          'You look toward the massive weeping willow on the shore.',
        ),
        StoryMessage(
          'He knew Abies. The eldest fir tree. Abies was part of the great network...',
          character: StoryCharacter.bluebellSheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Abies reached too far! Reached into the deep before! And now — far away, on ice — still reaching. Still reaching and reaching!',
          character: StoryCharacter.thicketSheep,
          kind: MessageKind.dialogue,
          isItalic: true,
        ),
        StoryMessage(
          'The sheep gesture toward the dark silhouette frozen in the center of the lake.',
        ),
        StoryMessage(
          'That\'s not Abies. Just his echo. A memory of the moment he left. Abies himself is far, far from here.',
          character: StoryCharacter.woolberrySheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Go on. Talk to Salix. We\'ll stay here and eat the clover. It\'s safer not to know too much.',
          character: StoryCharacter.woolberrySheep,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Approach the Willow (Salix)',
          nextScene: 'ep2_salix_first_contact',
        ),
        SceneChoice(
          letter: 'B',
          label: 'Approach the silhouette in the lake first',
          nextScene: 'ep2_approach_silhouette',
        ),
      ],
    ),

    Scene(
      id: 'ep2_approach_silhouette',
      lines: const [
        StoryMessage(
          'You ignore the sheep and fly out over the dark water toward the frozen echo in the center.',
        ),
        StoryMessage(
          'The air temperature drops precipitously. Your wings grow heavy with frost. A crushing pressure of unseen memories bears down on your mind — a thousand years of recollection, layered and impacted like glacial ice.',
        ),
        StoryMessage(
          'You realize with terror that if you get any closer, you will freeze mid-air. Whatever is down there is not a living thing — it is pure, pressurized memory, and it has no interest in being approached.',
        ),
        StoryMessage(
          'Gasping, you bank hard and return to the shore, landing near the Willow.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep2_salix_first_contact',
      onEnter: (state) {
        state.transience += 3;
      },
    ),

    Scene(
      id: 'ep2_salix_first_contact',
      lines: const [
        StoryMessage(
          'The weeping willow doesn\'t speak immediately. It acknowledges you. The heavy branches part slowly, revealing an ancient, scarred trunk.',
        ),
        StoryMessage(
          'I felt you arrive. The seed you carry... it glows with Dawn\'s light. You bring hope to a place that has forgotten the word.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I am Salix. And this fractured earth is my doing. My tears, crystallized by an unbearable truth, split the ground you walk on.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You look at the massive chasms cutting through the rock.',
        ),
        StoryMessage(
          'I wept for Abies. He is out there still — beyond the rainforest, beyond the open shore, across the crossing waters, on an island locked in ice. Alive. But changed. He stretched too far into the deep past, and the cold took hold of him. He never came back to the grove.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But do not mistake stillness for silence. Abies still works. He still tends the memories of this world. Just... more slowly. More quietly. From his frozen place at the edge of everything.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"What do you mean, he reached too far?"',
          nextScene: 'ep2_salix_offer_memories',
        ),
        SceneChoice(
          letter: 'B',
          label: '"I don\'t have time for tragedy. Point me to the gr0ve."',
          nextScene: 'ep2_salix_offer_memories',
          statEffects: {'vitality': 1},
        ),
      ],
    ),

    Scene(
      id: 'ep2_salix_offer_memories',
      lines: const [
        StoryMessage(
          'To understand the gr0ve, you must understand the network. And to understand the network, you must understand what broke it.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But raw memory is a dangerous thing. It will consume you if you carry it unprotected.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Salix\'s branches work the water of the lake. A single, new tear drops from his leaves, crystallizing into a beautiful pouch woven from water and light.',
          kind: MessageKind.narrative,
        ),
        StoryMessage(
          'Take this Memory Sack. It will hold the pieces of the past so they do not weigh upon your soul.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '[Memory Sack obtained | Items inside lose their crushing emotional weight.]',
          kind: MessageKind.system,
          isBold: true,
        ),
        StoryMessage(
          'Now, step into the shallows. Touch the water. It will show you four moments. Four pieces of a breaking heart.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep2_memory_1',
      onEnter: (state) {
        if (!state.inventory.contains('Memory Sack')) {
          state.inventory.add('Memory Sack');
        }
      },
    ),

    Scene(
      id: 'ep2_memory_1',
      lines: const [
        StoryMessage(
          'MEMORY 1: THE GIFT AWAKENS',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage(
          'You dip your talon into the freezing water. The lake shimmers, and the mist forms a vivid scene from centuries ago.',
        ),
        StoryMessage(
          'A young, vibrant fir tree stands beside a small, lively willow sapling. It is spring.',
        ),
        StoryMessage(
          'Salix, look! I felt something. A moment from before the winter. There was a bird\'s nest right here!',
          character: StoryCharacter.abiesBaby,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Show me! Can you really bring it back?',
          character: StoryCharacter.salixBaby,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Young Abies closes his eyes. His needles glow faintly. In the air between them, an image manifests: a small songbird, sitting on a branch, mouth open in mid-song.',
        ),
        StoryMessage(
          'It\'s beautiful, Abies. You\'re extraordinary. Do you know what this means?',
          character: StoryCharacter.salixBaby,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It means I can help. It means I matter. I can make sure nothing is ever truly lost.',
          character: StoryCharacter.abiesBaby,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You carefully place the Faint Resin Shard into your Memory Sack. It pulses with a soft, comforting light from within the fabric.',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep2_memory_2',
      waitDuration: const Duration(minutes: 45),
      onEnter: (state) {
        if (!state.inventory.contains('Faint Resin Shard')) {
          state.inventory.add('Faint Resin Shard');
        }
      },
    ),

    Scene(
      id: 'ep2_memory_2',
      lines: const [
        StoryMessage(
          'MEMORY 2: THE WEIGHT OF USEFULNESS',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage(
          'The water ripples. Years have passed. The forest is crowded with animals constantly demanding Abies\'s attention.',
        ),
        StoryMessage(
          'A raccoon begs him to find a lost cache. A fox demands to know who stole its prey. Abies is glowing constantly, his branches drooping under the effort.',
        ),
        StoryMessage(
          'Another young tree—Cedite, Abies\'s practical sibling—steps forward, looking alarmed.',
        ),
        StoryMessage(
          'Abies, stop! You\'re exhausting yourself. Every day you look backward for them. You\'re forgetting to live today!',
          character: StoryCharacter.cediteBaby,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But Cedite, they need me! I am necessary. If I stop, the truth is lost. I\'ll rest when everyone is at peace.',
          character: StoryCharacter.abiesBaby, // still youngish Abies
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Purpose becomes compulsion, brother. You are drowning in other people\'s pasts.',
          character: StoryCharacter.cediteBaby,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Abies ignores him, turning back to a waiting deer.'),
        StoryMessage(
          'The Etched Bark Strip slides into the Memory Sack. The weight on your mind lifts as the sack absorbs the burden of the memory.',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep2_memory_3',
      waitDuration: const Duration(minutes: 60),
      onEnter: (state) {
        if (!state.inventory.contains('Etched Bark Strip')) {
          state.inventory.add('Etched Bark Strip');
        }
      },
    ),

    Scene(
      id: 'ep2_memory_3',
      lines: const [
        StoryMessage(
          'MEMORY 3: THE BREAKING POINT',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage(
          'The water churns violently. Abies is much older, his bark cracked, his needles brown. He stands entirely alone.',
        ),
        StoryMessage(
          'There are no animals. Just Abies, surrounded by dozens of overlapping, chaotic memory projections.',
        ),
        StoryMessage(
          'I haven\'t reached far enough. There\'s a moment — the first loss. The original break. If I find it, I can fix everything!',
          character: StoryCharacter.abies,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He never found it. Because the original loss is before memory. He was reaching for something that cannot be grasped.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The memory in the water begins to fracture. Images repeat and glitch. Abies looks terrified as his own mind begins to splinter under the weight of deep time.',
        ),
        StoryMessage(
          'The Distorted Memory Fragment flickers as you tuck it into the Memory Sack. The dizziness fades as the sack stabilizes the splintered time.',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep2_memory_4',
      waitDuration: const Duration(minutes: 90),
      onEnter: (state) {
        if (!state.inventory.contains('Distorted Memory Fragment')) {
          state.inventory.add('Distorted Memory Fragment');
        }
      },
    ),

    Scene(
      id: 'ep2_memory_4',
      lines: const [
        StoryMessage(
          'MEMORY 4: THE FREEZE',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage(
          'The water becomes ice-cold. You are witnessing the exact moment of rupture.',
        ),
        StoryMessage(
          'Abies plunges his roots deep into the earth, reaching backward into a void so vast it has no name or shape.',
        ),
        StoryMessage('Suddenly, everything CRYSTALLIZES.'),
        StoryMessage(
          'Abies does not die. He simply STOPS. Caught perfectly between past and present, frozen in the eternal act of reaching. And then — slowly, inevitably — the cold pulls him away. Not down. Away. Northward. Toward ice.',
        ),
        StoryMessage(
          'The shockwave of his freezing blasts outward. The rivers overflow. The lake forms instantly. And Abies drifts, still standing, still reaching, until the ice claims the shore around him and holds him there.',
        ),
        StoryMessage(
          'Abies... you are still in there. I know you are. Keep working. Keep remembering. I will find someone to come to you.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The memory shows Salix, rooted to the shore, helplessly watching his friend drown in time. Salix begins to weep, and as the tears hit the ground, the earth shatters into the chasms you see today.',
        ),
        StoryMessage(
          'The Crystallized Memory Core settles at the bottom of the Memory Sack. Its immense weight is now manageable, safely contained within Salix\'s gift.',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep2_post_memory',
      waitDuration: const Duration(minutes: 120),
      onEnter: (state) {
        state.stability += 2;
        if (!state.inventory.contains('Crystallized Memory Core')) {
          state.inventory.add('Crystallized Memory Core');
        }
      },
    ),

    Scene(
      id: 'ep2_post_memory',
      lines: const [
        StoryMessage(
          'You pull your talon from the water, trembling. You are soaked. Dawn\'s seed is noticeably colder, its light flickering weakly.',
        ),
        StoryMessage(
          'The sheep have gathered silently at the edge of the grass, watching you.',
        ),
        StoryMessage(
          'He saw it all. The poor bird saw the freezing.',
          character: StoryCharacter.bluebellSheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Now you know why we stay in the meadow. The past is a trap.',
          character: StoryCharacter.woolberrySheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Salix\'s branches slowly sweep the ground.'),
        StoryMessage(
          'I do not expect you to understand fully. Most cannot. But you must carry this truth forward. Knowing everything is not the same as understanding anything.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"Can Abies be saved?"',
          nextScene: 'ep2_post_memory_talk',
        ),
        SceneChoice(
          letter: 'B',
          label: '"How do I reach Cedite in the gr0ve?"',
          nextScene: 'ep2_post_memory_talk',
        ),
      ],
      waitDuration: const Duration(minutes: 30),
    ),

    Scene(
      id: 'ep2_post_memory_talk',
      lines: const [
        StoryMessage(
          'To reach him, you cannot go the way he went — reaching backward into the void. You must go to him as he is now. Still frozen, yes. Still slow. But Abies never stopped. He is on that island, working with whatever movement remains in him.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'From here, you must follow the river through the tangled rainforest. It will lead you to the open shore. Then, you must cross the waters.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'At the end of the crossing, you will find the island consumed in ice — and Abies. You must reach him first.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'After Abies, you will find Cedite, who holds the present together. And finally, you will find Ash.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Raw memory cannot be carried safely. It will overwhelm you, pull you under, as the deep past tried to pull Abies. But I will give you something to help.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep2_salix_gift',
    ),

    Scene(
      id: 'ep2_salix_gift',
      lines: const [
        StoryMessage(
          'Salix\'s branches sweep the ground as you pull the last shard from the water.',
        ),
        StoryMessage(
          'You have the pieces now. The weight of the memories you just experienced is safely contained within the sack.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The sack glows with the combined light of the four shards, pulsing with a quiet, stabilized energy.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep2_departure',
      onEnter: (state) {
        state.stability += 1;
        state.connectivity += 1;
        state.vitality += 1;
        state.transience += 1;
      },
    ),

    Scene(
      id: 'ep2_departure',
      lines: const [
        StoryMessage(
          'The water of Lake Lament begins to move. The current finds an outlet—a narrow channel disappearing into a dense, towering rainforest.',
        ),
        StoryMessage('The sheep bleat softly from the grass.'),
        StoryMessage(
          'Good luck, little glowing bird! Don\'t get stuck in the past!',
          character: StoryCharacter.bluebellSheep,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Follow the river from here. Let it carry you through the rainforest to the open shore. From there, you must cross the waters to find Abies.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'And remember: Abies first, then Cedite, then Ash. That is the path you must take.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Thank Salix and follow the stream into the rainforest',
          nextScene: 'ep2_transition',
        ),
      ],
      waitDuration: const Duration(minutes: 60),
    ),

    Scene(
      id: 'ep2_transition',
      lines: const [
        StoryMessage(
          'You take flight, following the outlet stream. The water grows warmer, moving with purpose.',
        ),
        StoryMessage(
          'The misty, broken shores of the lake recede. The canopy of the rainforest closes over you, plunging you into a humid, vibrant green world.',
        ),
        StoryMessage(
          'Trust the water. Keep your eyes forward to the present.',
          character: StoryCharacter.salix,
          kind: MessageKind.dialogue,
          isItalic: true,
        ),
        StoryMessage(
          'EPISODE COMPLETE: THE WEEPING WILLOW',
          kind: MessageKind.episodeHeader,
        ),
        StoryMessage(
          'Thank you for playing the early access of The Gr0ve. Episode 3 is growing...',
          kind: MessageKind.system,
        ),
      ],
      inputType: InputType.none,
      onEnter: (state) {
        state.episodeComplete = true;
      },
    ),
  ];
}
