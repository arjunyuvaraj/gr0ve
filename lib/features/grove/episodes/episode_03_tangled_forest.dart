import 'package:gr0ve/features/grove/models/grove_models.dart';

List<Scene> buildEpisode03TangledForest() {
  return [
    Scene(
      id: 'ep3_intro',
      lines: const [
        StoryMessage(
          'EPISODE 3: THE TANGLED FOREST',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage(
          'You follow the outlet stream from Lake Lament, just as Salix directed. The water moves with purpose, cutting through dense undergrowth and mossy banks.',
        ),
        StoryMessage(
          'For thirty minutes, the stream flows downhill. The forest grows thicker. The mist from Lake Lament fades behind you.',
        ),
        StoryMessage(
          'The temperature RISES. The humidity wraps around you like a warm, wet blanket. Your feathers grow heavy with moisture.',
        ),
        StoryMessage(
          'The water, which was clear and reflective at the lake, becomes warmer. The memory images that rippled across Lake Lament\'s surface fade completely. The water is just water again.',
        ),
        StoryMessage(
          'The Flask of Tears against your side responds to the heat. The crushing weight of the shards inside feels... lighter somehow. More bearable.',
        ),
        StoryMessage(
          'Dawn\'s Seed, which had cooled to a dim flicker at Lake Lament, maintains its weak glow but the light shifts—becoming less blue-tinged, more amber-colored. The rainforest light is affecting it.',
        ),
        StoryMessage(
          'Dawn\'s Branch, clutched in your other talon, begins to absorb moisture. The wood feels heavier, but less brittle. It\'s coming alive with humidity.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_stream_split',
      waitDuration: const Duration(minutes: 30),
    ),

    Scene(
      id: 'ep3_stream_split',
      lines: const [
        StoryMessage('The stream you\'ve been following suddenly SPLITS.'),
        StoryMessage(
          'Three tributaries branch in different directions. The water is identical in all three—same speed, same clarity, same temperature.',
        ),
        StoryMessage('There is NO obvious correct choice.'),
        StoryMessage(
          'This is... confusing. Which way did Salix say to go? Just "follow the water," but the water doesn\'t seem sure of where it\'s going.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You land on a moss-covered stone and consider your options.',
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Try the leftmost tributary immediately',
          nextScene: 'ep3_wrong_path_loop',
        ),
        SceneChoice(
          letter: 'B',
          label: 'Examine the loop more carefully—why would water do this?',
          nextScene: 'ep3_examine_loop',
        ),
        SceneChoice(
          letter: 'C',
          label: 'Climb higher to get a better vantage point',
          nextScene: 'ep3_climb_high',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: 'Call out—maybe something here can help',
          nextScene: 'ep3_call_out',
        ),
      ],
      waitDuration: const Duration(minutes: 20),
    ),

    Scene(
      id: 'ep3_wrong_path_loop',
      lines: const [
        StoryMessage(
          'You choose the leftmost tributary—the one that seems to flow westward, toward where you assume the sun is hiding behind the thick canopy.',
        ),
        StoryMessage(
          'You follow it for ten minutes. The ravine curves. The water moves steadily.',
        ),
        StoryMessage('Then you see something FAMILIAR.'),
        StoryMessage(
          'A particular moss-covered log. Ferns arranged in the same pattern. You\'ve seen this exact spot before.',
        ),
        StoryMessage(
          'Wait. That\'s the stone I was just sitting on. The stream has LOOPED. It brought me back to the beginning.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You try the middle tributary. Ten minutes later: the same log. The same stone.',
        ),
        StoryMessage('You try the rightmost tributary. Same result.'),
        StoryMessage(
          'Okay, this forest is messing with me. Or teaching me something. Or both.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You return to the splitting point, exhausted and disoriented.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_find_correct_path',
      waitDuration: const Duration(minutes: 45),
      onEnter: (state) {
        state.vitality -= 1;
      },
    ),

    Scene(
      id: 'ep3_examine_loop',
      lines: const [
        StoryMessage(
          'You don\'t rush. Instead, you settle onto the moss and watch the water.',
        ),
        StoryMessage(
          'The tributaries split. The water flows. But there\'s a rhythm to it—a pattern you didn\'t notice at first.',
        ),
        StoryMessage(
          'The rightmost tributary flows slightly faster. The surface ripples differently.',
        ),
        StoryMessage(
          'The rainforest teaches by repetition. It shows you the same thing until you understand it. Maybe the loop isn\'t a mistake. Maybe it\'s a lesson.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You choose the rightmost tributary, trusting the subtle difference you noticed.',
        ),
        StoryMessage(
          'The ravine curves less sharply. The water flows with more confidence. You don\'t loop back.',
        ),
        StoryMessage(
          'The forest does not thin, but it OPENS. Space expands slightly. Room to fly without crashing into hanging vegetation.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_reveal',
      waitDuration: const Duration(minutes: 25),
      onEnter: (state) {
        state.stability += 1;
      },
    ),

    Scene(
      id: 'ep3_climb_high',
      lines: const [
        StoryMessage(
          'You launch upward, trying to rise above the canopy for a better view.',
        ),
        StoryMessage(
          'But the canopy is THICK. Layer upon layer of leaves. The higher you climb, the more tangled it becomes.',
        ),
        StoryMessage(
          'You catch brief glimpses of sky—filtered green light, never direct sun. But no clear view of the landscape. No sense of direction.',
        ),
        StoryMessage(
          'Dizzy and more confused than before, you return to the moss-covered stone.',
        ),
        StoryMessage(
          'The forest doesn\'t want to be seen from above. It wants to be understood from within.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_find_correct_path',
      waitDuration: const Duration(minutes: 15),
    ),

    Scene(
      id: 'ep3_call_out',
      lines: const [
        StoryMessage(
          'Hello? Is anyone here? I\'m trying to reach the open shore!',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Your voice echoes through the ravine. Water drips. Leaves rustle.',
        ),
        StoryMessage('No response.'),
        StoryMessage(
          'The rainforest is alive, but it doesn\'t speak in words. It speaks in patterns. In loops. In the subtle differences between identical-seeming paths.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_find_correct_path',
      waitDuration: const Duration(minutes: 10),
    ),

    Scene(
      id: 'ep3_find_correct_path',
      lines: const [
        StoryMessage(
          'Eventually, through trial or patience or luck, you find the correct tributary.',
        ),
        StoryMessage(
          'The ravine curves less sharply. The water flows with more confidence. The sound changes—less chaotic, more purposeful.',
        ),
        StoryMessage(
          'The forest does not thin, but it OPENS. Space expands. You can fly without constantly dodging vines.',
        ),
        StoryMessage('And then you see something strange.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_reveal',
    ),

    Scene(
      id: 'ep3_london_reveal',
      lines: const [
        StoryMessage('At first, it looks like part of the ravine wall itself.'),
        StoryMessage(
          'A darker patch of green. A shadow. A thickening of vegetation. Your eyes don\'t register it as separate from the landscape.',
        ),
        StoryMessage(
          'You continue flying, passing what you think is just another moss-covered cliff.',
        ),
        StoryMessage('Then—something shifts.'),
        StoryMessage(
          'The "wall" MOVES. Not violently. Not suddenly. Just a subtle reorganization of what is visible.',
        ),
        StoryMessage(
          'Layers of bark peel back, revealing something newer underneath.',
        ),
        StoryMessage('You realize with a start: you are looking at a TREE.'),
        StoryMessage(
          'But not just any tree. This is something massive. Its trunk is wider than you are long. Its bark is... wrong. It is PEELING. Sheets of papery skin are sloughing off constantly—a perpetual shedding revealing fresh growth beneath.',
        ),
        StoryMessage(
          'The ground around it is littered with shed bark—a carpet of pale, translucent flakes that cover the moss like forgotten letters.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_first_contact',
    ),

    Scene(
      id: 'ep3_london_first_contact',
      lines: const [
        StoryMessage(
          'The voice arrives before you fully understand what you\'re seeing. It is calm. Female. Not unkind. Patient, like something that has been waiting for a long time and does not mind waiting longer.',
        ),
        StoryMessage(
          'You carry much weight for something that flies so easily. The seed. Yes. I recognize that light. But more than that—the branch. The memories. The grief you collected in that lake.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You move like you\'re carrying stone. Like the sky itself is pressing down. Why is that?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You land fully on the moss. The Flask of Tears settles against your side. You feel its warmth intensify slightly—responding to proximity, to being noticed.',
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label:
              '"I\'m on a mission. The seed needs to be planted in the gr0ve. Everything I carry serves that purpose."',
          nextScene: 'ep3_london_purpose_response',
        ),
        SceneChoice(
          letter: 'B',
          label:
              '"These things were given to me. I don\'t know if I wanted them, but I\'m responsible for them now."',
          nextScene: 'ep3_london_duty_response',
        ),
        SceneChoice(
          letter: 'C',
          label:
              '"I\'m trying to understand what happened to something ancient. That\'s why the weight."',
          nextScene: 'ep3_london_knowledge_response',
        ),
        SceneChoice(
          letter: 'D',
          label: '"Who are you, and why does it matter to you?"',
          nextScene: 'ep3_london_identity_response',
        ),
        SceneChoice(
          letter: 'E',
          label:
              '"I don\'t know anymore. The weight gets heavier each moment."',
          nextScene: 'ep3_london_honesty_response',
          statEffects: {'stability': 1},
        ),
      ],
      waitDuration: const Duration(minutes: 20),
    ),

    Scene(
      id: 'ep3_london_purpose_response',
      lines: const [
        StoryMessage(
          'A mission. Purpose. Serving something larger than yourself. I understand these words.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But I wonder—if the seed could not be planted, if the journey ended here, what would you want then? When purpose is removed, what remains?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You don\'t have an answer. The question feels dangerous.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_introduction',
    ),

    Scene(
      id: 'ep3_london_duty_response',
      lines: const [
        StoryMessage(
          'Given. Responsible. These are the words of burden accepted without question.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I know that language well. I was grown in a place not built for me, expected to be something I was not. I understand the weight of duty.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The question is: when does responsibility become prison?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_introduction',
    ),

    Scene(
      id: 'ep3_london_knowledge_response',
      lines: const [
        StoryMessage(
          'Understanding. Yes. Memory\'s weight. I recognize it.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Salix carries that same burden—the grief of knowing what was lost. Of remembering what cannot be recovered.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But understanding everything is not the same as understanding anything. Sometimes knowledge is just weight.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_introduction',
    ),

    Scene(
      id: 'ep3_london_identity_response',
      lines: const [
        StoryMessage(
          'Direct. I appreciate that.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It matters to me because you are interesting. Because you carry things carefully. Because you are here, in my territory, and I have been alone with my shedding for a very long time.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'And because I see in you something I once saw in myself—the confusion between what you were given to carry and what you choose to carry.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_introduction',
    ),

    Scene(
      id: 'ep3_london_honesty_response',
      lines: const [
        StoryMessage(
          'London\'s branches shift. Something in her presence relaxes slightly.',
        ),
        StoryMessage(
          'Honesty. Finally. That is what I was listening for.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Most who pass through this forest know exactly what they want, or think they do. But you... you are still asking the question. That is rare. That is valuable.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_introduction',
    ),

    Scene(
      id: 'ep3_london_introduction',
      lines: const [
        StoryMessage(
          'I am London. That name fits well enough. I am a tree of that name, grown in a place that was not built for me.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The old growth here—the ancient ones—they don\'t really understand me. I don\'t fit their patterns. So I learned something early: change faster than the world expects.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Shed my past constantly, because the present does not have room for history.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'In shedding, I become difficult to see. Until I want to be seen. Until something arrives in my territory that is interesting enough to peel back the camouflage for.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"Are you part of the gr0ve?"',
          nextScene: 'ep3_london_grove_talk',
        ),
        SceneChoice(
          letter: 'B',
          label: '"Do you work with Salix and the others?"',
          nextScene: 'ep3_london_grove_talk',
        ),
      ],
    ),

    Scene(
      id: 'ep3_london_grove_talk',
      lines: const [
        StoryMessage(
          'No. Not part of their network. Not connected to their purpose.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I\'m aware of them—I know of Salix through travelers and wind-carried news. I know of the gr0ve through distant rumor. But I chose a different path.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Independence. Presence. The freedom to shed what doesn\'t serve the moment.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'They chose connection. Connection is beautiful. But it\'s also heavy. I prefer light.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'London\'s branches—visible above, thick and spreading—lower slightly. They don\'t touch you, but they approach closer.',
        ),
        StoryMessage(
          'That branch concerns me more than the seed. Reach down—let me see it.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_branch_examination',
      waitDuration: const Duration(minutes: 15),
    ),

    Scene(
      id: 'ep3_branch_examination',
      lines: const [
        StoryMessage(
          'You hold Dawn\'s Branch more tightly, but London\'s attention is patient and inevitable.',
        ),
        StoryMessage(
          'Her presence is calm enough that you find yourself lowering the branch slightly, so her leaves can brush it, examine it.',
        ),
        StoryMessage(
          'Yes. I can read it. This wood was a bridge. A threshold. Look at the growth rings—they alternate with precision. One side light, one side dark. Day and night held in perfect, rhythmic balance.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But then—do you see?—the rhythm begins to fail. The rings grow thin. Translucent. The wood itself seems to be... fading.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'As if the tree it came from was losing its grip on the world. As if it were standing on a line that was being drawn away. A tree that was once a gate, now becoming a ghost.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You look down at the branch. In the rainforest\'s green light, the grain is suddenly VISIBLE. Stark. The story London is reading is written in wood—in the architecture of growth itself.',
        ),
        StoryMessage(
          'The rings don\'t lie. There is a moment where the tree\'s growth changed from a steady bridge into something... vanishing.',
        ),
        StoryMessage(
          'This wood was a boundary once. A limit. But the boundary began to thin. To blur. I can feel the memory of a great weight in these fibers—the weight of holding two worlds apart, until they finally touched.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I wonder what happened after. After the balance failed. After the gate began to dissolve. Did the tree find a new place to stand? Or did it simply... end?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"Is it the same as the tree that froze? The one reaching?"',
          nextScene: 'ep3_london_freeze_response',
        ),
        SceneChoice(
          letter: 'B',
          label:
              '"It reached too far into the light and vanished. I have the fragments here."',
          nextScene: 'ep3_london_sack_response',
        ),
        SceneChoice(
          letter: 'C',
          label:
              '"I was told it was a gate. I didn\'t know wood could become a ghost."',
          nextScene: 'ep3_london_mission_response',
        ),
        SceneChoice(
          letter: 'D',
          label:
              '"Abies reached backward. Did this tree do the same?"',
          nextScene: 'ep3_london_backward_response',
        ),
      ],
    ),

    Scene(
      id: 'ep3_london_freeze_response',
      lines: const [
        StoryMessage(
          'No. Freezing is an ending of a different kind. Abies—the one you speak of—he was caught in a moment of desperate holding. He froze because he refused to let go.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But this branch in your hand? It didn\'t freeze. It thinned. It chose to become nothing rather than be trapped. It didn\'t reach for the past; it reached so far into the future that the present couldn\'t hold it.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_invitation',
    ),

    Scene(
      id: 'ep3_london_sack_response',
      lines: const [
        StoryMessage(
          'The memories are in the sack. Of course they are.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Salix gave you that container, didn\'t he? A Flask of Tears to hold what would otherwise crush you. I understand his gift. But I wonder—does carrying those memories help you, or does it simply make the weight more bearable?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'There is a difference between understanding weight and being freed from it.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_invitation',
    ),

    Scene(
      id: 'ep3_london_mission_response',
      lines: const [
        StoryMessage(
          'Everything is a story. Even missions. Especially missions.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The branch is telling you something whether you listen or not. The grain holds truth. The wood remembers what the tree became.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Perhaps you should ask the branch what it wants, instead of assuming it wants what you were told it wants.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_invitation',
    ),

    Scene(
      id: 'ep3_london_backward_response',
      lines: const [
        StoryMessage(
          'Abies reached backward, yes. The past was his gravity. But look at these rings again.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Dawn didn\'t reach back. She reached through. She was a threshold that decided to stop being a wall. She didn\'t fail because of a mistake; she succeeded so well that she ceased to be a solid thing.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But there is another kind of reaching. Forward. Into what might be. That reaching doesn\'t freeze you. It animates you.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_invitation',
    ),

    Scene(
      id: 'ep3_london_invitation',
      lines: const [
        StoryMessage(
          'Come. Sit with me. The rainforest is difficult to navigate when you don\'t know its rules. I have been here longer than I remember. I know the paths, such as they are.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'And I am curious about a bird that carries such burdens so carefully.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Sit. Tell me about the reaching. Tell me about what froze.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_sitting_conversation',
      waitDuration: const Duration(minutes: 30),
    ),

    Scene(
      id: 'ep3_sitting_conversation',
      lines: const [
        StoryMessage(
          'You settle into the moss beside London\'s roots. The roots are enormous—spreading across the forest floor like the fingers of a sleeping giant.',
        ),
        StoryMessage(
          'They are old. They are patient. They have made peace with holding this patch of earth while the rest of the rainforest is constantly becoming, constantly transforming.',
        ),
        StoryMessage(
          'The Flask of Tears, warm against your side, continues to respond to London\'s presence. Its warmth increases. The sack is reacting to being witnessed—to another living thing attending to the memories it holds.',
        ),
        StoryMessage(
          'How long have you been carrying these things? The seed. The branch. The sack.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label:
              '"Since before I understood what they meant. Since the very beginning of this journey."',
          nextScene: 'ep3_conv_beginning',
        ),
        SceneChoice(
          letter: 'B',
          label:
              '"The seed and branch since the beginning. The sack only since Lake Lament."',
          nextScene: 'ep3_conv_lake',
        ),
        SceneChoice(
          letter: 'C',
          label:
              '"I don\'t know. It feels like forever. It feels like a day. Time isn\'t clear anymore."',
          nextScene: 'ep3_conv_time',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label:
              '"Long enough to feel like they own me instead of me owning them."',
          nextScene: 'ep3_conv_ownership',
        ),
      ],
    ),

    Scene(
      id: 'ep3_conv_beginning',
      lines: const [
        StoryMessage(
          'The beginning. And what did the beginning mean? When you first accepted these burdens?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You think back. Dawn. The orchard. The moment when you agreed to carry his vision forward.',
        ),
        StoryMessage(
          'It meant purpose, I think. It meant I mattered. That I could do something important.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Purpose. Mattering. Important. These are powerful words. But are they true? Or are they the story you told yourself to make the weight bearable?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_understanding_question',
    ),

    Scene(
      id: 'ep3_conv_lake',
      lines: const [
        StoryMessage(
          'Lake Lament. Salix\'s grief. The memories of Abies\'s breaking.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That lake holds weight older than most forests. Salix gave you a container so you could carry what would otherwise drown you. But the question remains: should you be carrying it at all?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_understanding_question',
    ),

    Scene(
      id: 'ep3_conv_time',
      lines: const [
        StoryMessage(
          'That\'s the rainforest teaching you about present time. Here, there is no past. No future. Only the constant NOW of growth and transformation.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The confusion you feel—that\'s not weakness. That\'s the forest showing you something true. That time is less fixed than you think. That the weight you carry exists partly because you believe it must.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_understanding_question',
    ),

    Scene(
      id: 'ep3_conv_ownership',
      lines: const [
        StoryMessage(
          'Yes. That\'s the question, isn\'t it.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'When does what we carry begin to carry us? When do our purposes become our prisons?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I shed constantly to avoid that fate. To avoid being owned by what I was. But you—you cannot shed the seed. You cannot shed the branch. So what do you do?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_understanding_question',
    ),

    Scene(
      id: 'ep3_understanding_question',
      lines: const [
        StoryMessage(
          'And do you understand what they mean now? What they\'re for?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label:
              '"I understand that Dawn had a vision. That his seed carries that vision. That memory can become bearable if you have the right container."',
          nextScene: 'ep3_understand_vision',
        ),
        SceneChoice(
          letter: 'B',
          label:
              '"I understand they\'re heavy. That\'s all I really understand."',
          nextScene: 'ep3_understand_weight',
        ),
        SceneChoice(
          letter: 'C',
          label:
              '"I\'m starting to. But understanding feels separate from wanting to carry them."',
          nextScene: 'ep3_understand_separate',
          statEffects: {'connectivity': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '"Not really. I just know I\'m supposed to."',
          nextScene: 'ep3_understand_supposed',
        ),
      ],
      waitDuration: const Duration(minutes: 45),
    ),

    Scene(
      id: 'ep3_understand_vision',
      lines: const [
        StoryMessage(
          'Understanding and agreement are not the same. You understand Dawn\'s vision. But do you agree with it? Do you want what he wanted?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Or are you simply carrying forward someone else\'s dream because you were asked to?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_grove_choice',
    ),

    Scene(
      id: 'ep3_understand_weight',
      lines: const [
        StoryMessage(
          'Simplicity is often truest. Weight is weight. Burden is burden.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The question is: do you want to keep carrying it? Not because you should. Not because you promised. But because YOU want to.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_grove_choice',
    ),

    Scene(
      id: 'ep3_understand_separate',
      lines: const [
        StoryMessage(
          'London\'s branches shift. She seems to lean into this response.',
        ),
        StoryMessage(
          'Yes. Exactly that. Understanding is not the same as wanting. Knowledge is not the same as desire.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You can understand what the seed needs, what Dawn wanted, what the gr0ve requires—and still ask yourself what YOU want. That question is allowed. That question is necessary.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_grove_choice',
    ),

    Scene(
      id: 'ep3_understand_supposed',
      lines: const [
        StoryMessage(
          'Supposed to. Those are the words of someone who has never been asked what they want.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Let me ask you something different, then. Something simpler.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_grove_choice',
    ),

    Scene(
      id: 'ep3_grove_choice',
      lines: const [
        StoryMessage(
          'I chose not to join that network. Grover, Aspen, Rowan, Sakura—they call themselves the gr0ve. They speak of connection. Of holding things together. Of purpose larger than any single tree.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You\'ve heard of them.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Yes. From Salix. From the sheep. Everyone speaks of them like they matter tremendously.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'They do matter. They are ancient. They are real. And they are wounded now, because their eldest—Abies—chose solitude over connection. Chose to reach backward instead of forward. And in reaching, he froze.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But I looked at what the gr0ve was offering—rootedness to purpose, connection to a larger meaning—and I decided that I preferred to shed my obligations along with my bark.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'To be present here, in this rainforest, without the weight of what the network requires. I could have joined. Once. But I chose differently.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"Was that wise? Choosing independence over connection?"',
          nextScene: 'ep3_choice_wisdom',
        ),
        SceneChoice(
          letter: 'B',
          label: '"Do you regret it?"',
          nextScene: 'ep3_choice_regret',
        ),
        SceneChoice(
          letter: 'C',
          label: '"Doesn\'t isolation get lonely?"',
          nextScene: 'ep3_choice_lonely',
        ),
        SceneChoice(
          letter: 'D',
          label: '"I\'m beginning to understand why you did that."',
          nextScene: 'ep3_choice_understand',
          statEffects: {'transience': 1},
        ),
      ],
    ),

    Scene(
      id: 'ep3_choice_wisdom',
      lines: const [
        StoryMessage(
          'It was honest, not wise. Wisdom and honest choice are not always the same thing.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Wisdom looks at consequences and chooses accordingly. Honesty looks at what is true and chooses regardless.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I chose honesty. I cannot say if that was wise. But it was mine.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_central_question',
    ),

    Scene(
      id: 'ep3_choice_regret',
      lines: const [
        StoryMessage(
          'I don\'t experience regret. I shed those feelings along with everything else that doesn\'t serve the present.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But I do wonder, sometimes. Wonder what it would have been like to be part of something larger. To carry the weight of connection instead of the lightness of solitude.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Wonder is different from regret. Wonder looks forward. Regret looks back.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_central_question',
    ),

    Scene(
      id: 'ep3_choice_lonely',
      lines: const [
        StoryMessage(
          'Loneliness and solitude are not the same thing.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Loneliness is wanting connection and not having it. Solitude is choosing presence without connection. I chose solitude.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But yes. Sometimes. The rainforest is full of life, but most of it does not speak as I speak. Most of it does not attend as I attend. So when something interesting arrives—a bird carrying burdens it doesn\'t understand—I pay attention.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_central_question',
    ),

    Scene(
      id: 'ep3_choice_understand',
      lines: const [
        StoryMessage(
          'What are you beginning to understand?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('You pause. The words come slowly.'),
        StoryMessage(
          'That sometimes the heaviest thing we carry is other people\'s expectations. Other people\'s purposes. That there might be a difference between what I was given to do and what I want to do.',
          character: StoryCharacter.player,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'London\'s bark sheds. Layer after layer revealing something new.',
        ),
        StoryMessage(
          'Yes. That is what I hoped you would see.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_central_question',
    ),

    Scene(
      id: 'ep3_central_question',
      lines: const [
        StoryMessage(
          'London lowers her attention toward you. It is not a physical gaze—trees do not have eyes—but you feel it nonetheless.',
        ),
        StoryMessage(
          'An attention. A focusing on the specific bird in front of her.',
        ),
        StoryMessage(
          'Tell me something. And answer honestly, as honestly as you can.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Of all the things you hold, of all the purposes that have been handed to you—Dawn\'s mission, Salix\'s knowledge, the seed\'s hunger for ground—what do you actually want?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Not what you should want. Not what you promised to want. Not what makes sense given everything that has been given to you.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But you. The bird. Right now. In this moment. What do you want?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label:
              '"I want to plant the seed. That\'s what I want. Everything else is secondary."',
          nextScene: 'ep3_want_seed',
        ),
        SceneChoice(
          letter: 'B',
          label:
              '"I want to rest. To stop carrying weight. To understand my own desires instead of serving someone else\'s vision."',
          nextScene: 'ep3_want_rest',
          statEffects: {'transience': 2, 'connectivity': 1},
        ),
        SceneChoice(
          letter: 'C',
          label:
              '"I don\'t know. I\'ve never had the luxury of wanting something just for myself."',
          nextScene: 'ep3_want_unknown',
          statEffects: {'transience': 1},
        ),
        SceneChoice(
          letter: 'D',
          label:
              '"I want to understand what happened to the tree that this branch came from. That\'s my want. That\'s my mission."',
          nextScene: 'ep3_want_understand',
        ),
      ],
      waitDuration: const Duration(hours: 1),
    ),

    Scene(
      id: 'ep3_want_seed',
      lines: const [
        StoryMessage('London is quiet for a long moment.'),
        StoryMessage(
          'And if the seed couldn\'t be planted? If the journey ended here? If the gr0ve was unreachable? What would you want then?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You don\'t have an answer. The question unravels something inside you.',
        ),
        StoryMessage(
          'You\'re confusing purpose with desire. They\'re not the same. Purpose is what you were given. Desire is what you choose.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_rainforest_gift',
    ),

    Scene(
      id: 'ep3_want_rest',
      lines: const [
        StoryMessage(
          'That is honest. That is dangerous. And that is where real choice begins.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'To rest is not to abandon. To stop carrying is not to fail. To want something for yourself is not selfishness.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But the question remains: can you choose rest while still holding the seed? Or must you put it down to be free?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('You don\'t answer. You don\'t know the answer.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_rainforest_gift',
    ),

    Scene(
      id: 'ep3_want_unknown',
      lines: const [
        StoryMessage(
          'Then perhaps the rainforest can teach you. We teach that. Present desire. Present need. Not the weight of history or the promise of future.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But you cannot fully learn while carrying so much. The weight itself prevents you from knowing what you want beneath it.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'This is the paradox you live in. To know what you want, you must put down what you carry. But you cannot put down what you carry until you know what you want.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_rainforest_gift',
    ),

    Scene(
      id: 'ep3_want_understand',
      lines: const [
        StoryMessage(
          'You\'re confusing understanding with wanting. They are not the same. But the confusion is instructive.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Understanding is safe. It\'s intellectual. It requires nothing of you except attention. But wanting? Wanting is dangerous. Wanting requires you to choose. To risk. To say "this matters to me" even when the world expects you to want something else.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'So I ask again: what do YOU want? Not what you want to understand. What you want to DO. To BE. To HAVE.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('You still don\'t have an answer.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_rainforest_gift',
    ),

    Scene(
      id: 'ep3_rainforest_gift',
      lines: const [
        StoryMessage(
          'That is the rainforest\'s gift. Not fertility—any forest has that. But present-ness.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The fact that nothing here is concerned with yesterday or tomorrow. The vines grow today. The water flows today. The light filters through today\'s leaves. The rain falls on today\'s moss.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The rainforest teaches you to stop reaching backward into what was. And it does not allow you to reach forward into what might be. It forces you to be here. In the growing. In the becoming. In the present.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But you cannot live in the present, can you? You carry something that exists only in promise. A seed that might become a tree a thousand years from now.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A branch that is already dead wood, already memory. You cannot be only present. You have to be also future. Also past.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label:
              '"Then I\'m trapped. Past and future, with no present of my own."',
          nextScene: 'ep3_trapped_response',
        ),
        SceneChoice(
          letter: 'B',
          label:
              '"So the rainforest can teach me to be present, but it can\'t solve my problem."',
          nextScene: 'ep3_solve_response',
        ),
        SceneChoice(
          letter: 'C',
          label:
              '"Maybe that\'s okay. Maybe carrying both is the actual task."',
          nextScene: 'ep3_both_response',
          statEffects: {'stability': 1},
        ),
        SceneChoice(
          letter: 'D',
          label: '"You\'re saying I have to choose. Choose what matters more."',
          nextScene: 'ep3_choose_response',
        ),
      ],
    ),

    Scene(
      id: 'ep3_trapped_response',
      lines: const [
        StoryMessage(
          'Yes. Many are.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But being trapped is not the same as being doomed. Traps can be studied. Understood. Sometimes even escaped. But first you must acknowledge the trap exists.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_conclusion',
    ),

    Scene(
      id: 'ep3_solve_response',
      lines: const [
        StoryMessage(
          'The rainforest teaches what it knows. It knows NOW. It cannot teach past or future. That is not its domain.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But perhaps the lesson is simpler than you think. Perhaps the rainforest is saying: you can carry past and future, but you must live in the present. That is the only place where life actually happens.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_conclusion',
    ),

    Scene(
      id: 'ep3_both_response',
      lines: const [
        StoryMessage('London pauses. Her branches shift. More bark falls.'),
        StoryMessage(
          'Perhaps. I have not considered that approach.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'To carry both without being crushed by either. To hold past and future while living in the present. That would be... extraordinary. If it\'s possible.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I chose to shed the past entirely. Abies chose to drown in it. But you—you might find a third way. A balance.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_conclusion',
    ),

    Scene(
      id: 'ep3_choose_response',
      lines: const [
        StoryMessage(
          'No. I\'m saying there is no good choice. Only the one you make.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Every path has cost. Connection has weight. Independence has loneliness. Past has grief. Future has uncertainty. Present has impermanence.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The question is not which choice is right. The question is which cost you\'re willing to pay.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_london_conclusion',
    ),

    Scene(
      id: 'ep3_london_conclusion',
      lines: const [
        StoryMessage(
          'Yes. And that is why you are here, and I am here. That is why you will leave, and I will remain.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That is why the seed glows with something beyond present light, and why my bark sheds to reveal only now.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You are carrying past and future. I am carrying only the present. We are two different kinds of trees, living two different kinds of lives.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Before you leave, there is something you should take.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_vial_gift',
      waitDuration: const Duration(minutes: 15),
    ),

    Scene(
      id: 'ep3_vial_gift',
      lines: const [
        StoryMessage(
          'Not a blessing. Not advice. Simply a thing. A thing that will matter later, though not now.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Her lower branches move. Something rolls across the moss toward you.',
        ),
        StoryMessage(
          'At first you think it is another piece of bark. But it has weight. Substance.',
        ),
        StoryMessage(
          'It is a VIAL. Small. Circular. Perfectly smooth. And inside, liquid.',
        ),
        StoryMessage(
          'The liquid is not water. It is LUMINOUS. Warm-colored, even in the green rainforest light. It seems ALIVE in a way that water is not. It pulses faintly, as if responding to the humid air around it.',
        ),
        StoryMessage(
          'The vial is WARM to the touch—warmer than the air around it, which is already warm and humid.',
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"What is this?"',
          nextScene: 'ep3_vial_explanation',
        ),
        SceneChoice(
          letter: 'B',
          label: '"What do I do with it?"',
          nextScene: 'ep3_vial_explanation',
        ),
        SceneChoice(
          letter: 'C',
          label: '"Why are you giving this to me?"',
          nextScene: 'ep3_vial_explanation',
        ),
        SceneChoice(
          letter: 'D',
          label: '"Is it safe to carry?"',
          nextScene: 'ep3_vial_explanation',
        ),
      ],
    ),

    Scene(
      id: 'ep3_vial_explanation',
      lines: const [
        StoryMessage(
          'It is the rainforest\'s gift to travelers. It holds the warmth of this place. The present-ness. The aliveness.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You can carry it. It is safe. In fact, it is necessary—more necessary than you understand right now.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But it is not for now. Not for this moment. It is waiting. Like you are waiting. Like the seed is waiting.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You will know, eventually. It is not for now. But it will matter. Particularly when you reach the shore. Particularly when warmth becomes scarce.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The shore is not far. You can follow the ravine east—the stream will split again, and split again, but eventually one tributary will win. It will widen. It will stop looping. And it will flow into open water.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'From there, you will see the ocean. And beyond the ocean—if you fly far enough—is water you cannot cross without rest.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'And on the other side of that water, if you fly still farther, is ice. There is a tree there. Old. Frozen. Still working, but in a way that does not look like work.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Abies.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"Abies is alive? I thought he froze."',
          nextScene: 'ep3_abies_alive',
        ),
        SceneChoice(
          letter: 'B',
          label: '"How do you know all of this?"',
          nextScene: 'ep3_london_knows',
        ),
        SceneChoice(
          letter: 'C',
          label: '"Should I try to unfreeze him?"',
          nextScene: 'ep3_unfreeze_question',
        ),
        SceneChoice(
          letter: 'D',
          label: '"I don\'t understand. Help me understand the path."',
          nextScene: 'ep3_path_explanation',
        ),
      ],
    ),

    Scene(
      id: 'ep3_abies_alive',
      lines: const [
        StoryMessage(
          'He froze. But freezing is not the same as death. He is still there. Still working. Just... differently.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Slower than slow. Quieter than quiet. But Abies never stopped. He is working with whatever movement remains in him.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_vial_purpose',
    ),

    Scene(
      id: 'ep3_london_knows',
      lines: const [
        StoryMessage(
          'I listen. The wind carries news. The water carries memory echoes. I know more than I seem to.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'And I have been here a long time. Long enough to hear the stories that travelers carry. Long enough to piece together what happened to the gr0ve.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_vial_purpose',
    ),

    Scene(
      id: 'ep3_unfreeze_question',
      lines: const [
        StoryMessage(
          'That is not my question to answer. That is your question. That is your choice, when you reach him.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But I will tell you this: unfreezing assumes that frozen is wrong. That stillness is failure. But Abies chose his path. He reached backward until he could reach no further. And in that reaching, he found... something. Or perhaps he is still searching.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Do not assume he wants to be unfrozen. Ask him first.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_vial_purpose',
    ),

    Scene(
      id: 'ep3_path_explanation',
      lines: const [
        StoryMessage(
          'The branch you carry—it is reaching for him, even though it is dead. Even though it can no longer reach for anything. There is a connection there. You will feel it when you are close.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Follow the shore east. The ocean will be vast and empty. But there are places to rest. There are small creatures that understand warmth and time. They may help in ways you cannot predict.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Cross the water. It is long. You will grow tired. But you will reach the other side.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Beyond that is ice. Cold beyond cold. Where the tree lives now.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_vial_purpose',
    ),

    Scene(
      id: 'ep3_vial_purpose',
      lines: const [
        StoryMessage(
          'Your vial will matter there. The warmth it holds. The present aliveness. When everything is frozen, a vial of rainforest warmth becomes something else.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Something alive in a dead place.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '[Circular Vial obtained | Contains luminous rainforest liquid. Warm. Alive. Waiting.]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_final_wisdom',
      onEnter: (state) {
        if (!state.inventory.contains('Circular Vial')) {
          state.inventory.add('Circular Vial');
        }
        state.vitality += 2;
      },
      waitDuration: const Duration(minutes: 10),
    ),

    Scene(
      id: 'ep3_final_wisdom',
      lines: const [
        StoryMessage(
          'London\'s bark continues to shed—a constant, gentle sloughing. Each layer revealing something new beneath.',
        ),
        StoryMessage(
          'The process is not violent or desperate. It is methodical. Inevitable. A shedding of what was so that what is can be seen clearly.',
        ),
        StoryMessage(
          'One more thing. About the thinning in that branch. The moment when the balance finally broke.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That thinning is the opposite of the reaching in the ice. Abies tried to hold everything by reaching backward into what was. But the tree of this branch... it tried to hold everything by standing in the middle. By being the bridge between day and night.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Both are dangerous, little bird. Reaching backward freezes you. But being a bridge for shores that are drawing apart... that can pull you thin until you vanish entirely.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Do not be a bridge for worlds that do not want to be connected. And do not reach for yesterday. Just be here. In the flight. In the now.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"I\'ll try. I don\'t know if I can, but I\'ll try."',
          nextScene: 'ep3_departure_prep',
        ),
        SceneChoice(
          letter: 'B',
          label: '"How do I know which kind of reaching I\'m doing?"',
          nextScene: 'ep3_reaching_distinction',
        ),
        SceneChoice(
          letter: 'C',
          label: '"Can I come back here? After I\'ve done what I need to do?"',
          nextScene: 'ep3_return_question',
        ),
        SceneChoice(
          letter: 'D',
          label:
              '"Thank you, London. For seeing me. For asking what I wanted."',
          nextScene: 'ep3_departure_prep',
          statEffects: {'connectivity': 1},
        ),
      ],
    ),

    Scene(
      id: 'ep3_reaching_distinction',
      lines: const [
        StoryMessage(
          'Ask yourself: Does this reach come from love for what I\'m seeking? Or from fear of what I\'m leaving behind?',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Love pulls you forward. Fear pulls you backward. Both feel like reaching, but they lead to very different places.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_departure_prep',
    ),

    Scene(
      id: 'ep3_return_question',
      lines: const [
        StoryMessage(
          'The rainforest doesn\'t work that way. It\'s always here. But you can only arrive for the first time once.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'After that, you\'re always returning to a changed place. The forest will have grown. I will have shed. You will have become someone different.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But yes. You can return. Just don\'t expect to find what you left behind.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_departure_prep',
    ),

    Scene(
      id: 'ep3_departure_prep',
      lines: const [
        StoryMessage(
          'Go. The shore waits.',
          character: StoryCharacter.london,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You take flight. London watches you go, her bark shedding constantly, each layer revealing something new beneath.',
        ),
        StoryMessage(
          'She does not speak further. She has said what needs saying.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_ravine_escape',
      waitDuration: const Duration(minutes: 30),
    ),

    Scene(
      id: 'ep3_ravine_escape',
      lines: const [
        StoryMessage(
          'The ravine DOES widen, as London promised. The stream DOES choose one direction and abandon the others.',
        ),
        StoryMessage(
          'The sound of flowing water grows louder, more confident.',
        ),
        StoryMessage('The humidity increases. The warmth intensifies.'),
        StoryMessage(
          'And then, after perhaps thirty minutes, the forest wall OPENS entirely.',
        ),
        StoryMessage(
          'The trees pull back as if in deference to something larger. The stream widens dramatically, becomes a river, becomes a flood of water flowing toward a clear horizon.',
        ),
        StoryMessage('Light. OPEN light. Sky. Massive sky.'),
        StoryMessage(
          'You break through the rainforest\'s edge and see it: the OPEN SHORE. The beach. Water without bounds, without loops, without confusion.',
        ),
        StoryMessage(
          'The air is suddenly clear. The light is suddenly direct. The horizon stretches endlessly.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_squashy_encounter',
    ),

    Scene(
      id: 'ep3_squashy_encounter',
      lines: const [
        StoryMessage(
          'You land on the warm sand to catch your breath. The beach is beautiful—pale sand, gentle waves, the sound of water meeting shore.',
        ),
        StoryMessage('As you settle, movement catches your eye.'),
        StoryMessage(
          'A SNAKE slides smoothly across the warm sand, moving toward you with purposeful grace.',
        ),
        StoryMessage(
          'The snake is neither threatening nor timid. It moves with quiet confidence.',
        ),
        StoryMessage(
          'The snake is small—perhaps the length of your wing—with scales that shimmer in soft greens and earth tones. Her eyes are bright and knowing.',
        ),
        StoryMessage(
          'You carry something that grows cold. I can feel it from here. The seed. Yes. It\'s warming, then cooling. Warming, then cooling.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The rainforest heated it, but not enough. The open shore is hot, yes, but temporary heat is not the same as sustained warmth.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You will need something better before you cross the water.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"Who are you? How do you know about the seed?"',
          nextScene: 'ep3_squashy_introduction',
        ),
        SceneChoice(
          letter: 'B',
          label: '"I have a vial of rainforest warmth. Will that be enough?"',
          nextScene: 'ep3_squashy_vial',
        ),
        SceneChoice(
          letter: 'C',
          label: '"What do you want? Are you here to help or to test me?"',
          nextScene: 'ep3_squashy_purpose',
        ),
        SceneChoice(
          letter: 'D',
          label: '[Stay silent and observe the snake]',
          nextScene: 'ep3_squashy_silence',
        ),
      ],
      waitDuration: const Duration(minutes: 15),
    ),

    Scene(
      id: 'ep3_squashy_introduction',
      lines: const [
        StoryMessage(
          'I am Squashy. That\'s what the creatures of the shore call me.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'As for knowing—I listen to the sand, the warmth, the life that passes through this place. Everything leaves a trace of heat. Your seed\'s glow is obvious to those who know how to look.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_squashy_warmth_talk',
    ),

    Scene(
      id: 'ep3_squashy_vial',
      lines: const [
        StoryMessage(
          'For now, yes. But for the journey ahead—the crossing, the ice—no.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You will need something more reliable. Something woven into a vessel that holds warmth the way a mother holds an egg.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_squashy_warmth_talk',
    ),

    Scene(
      id: 'ep3_squashy_purpose',
      lines: const [
        StoryMessage(
          'Both. Neither. I\'m here because you arrived. And in arriving, you asked for help without knowing you were asking.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The seed\'s cooling is a question. I have an answer.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_squashy_warmth_talk',
    ),

    Scene(
      id: 'ep3_squashy_silence',
      lines: const [
        StoryMessage(
          'Squashy approaches closer, unbothered by your silence. She understands. She continues anyway.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_squashy_warmth_talk',
    ),

    Scene(
      id: 'ep3_squashy_warmth_talk',
      lines: const [
        StoryMessage(
          'Squashy moves closer, circling the area near your talons but not touching you or your cargo. She is warm to the touch, and you can feel the heat radiating from her scaled body.',
        ),
        StoryMessage(
          'The rainforest teaches shedding. Transformation. But the shore teaches something different. The shore teaches that some things need to be held. Protected. Warmed without changing them.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That vial you carry—the rainforest\'s gift—it\'s good. But it\'s warm for today. The seed needs warmth for tomorrow. And the day after. And through a long crossing where the sun is far away and the water is cold and indifferent.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label:
              '"What are you offering? How can a snake help a bird keep something warm?"',
          nextScene: 'ep3_pouch_offer',
        ),
        SceneChoice(
          letter: 'B',
          label: '"Why would you help me? You don\'t know my purpose."',
          nextScene: 'ep3_squashy_why',
        ),
        SceneChoice(
          letter: 'C',
          label: '"I don\'t need help. I can keep the seed warm myself."',
          nextScene: 'ep3_squashy_pride',
        ),
        SceneChoice(
          letter: 'D',
          label: '"London sent you, didn\'t she?"',
          nextScene: 'ep3_london_connection',
        ),
      ],
    ),

    Scene(
      id: 'ep3_pouch_offer',
      lines: const [
        StoryMessage(
          'I weave. That\'s what snakes do—we understand wrapping, holding, making spaces that are safe.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I have woven a pouch from the grasses and silks of this shore. It holds heat the way nothing else can.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_pouch_description',
    ),

    Scene(
      id: 'ep3_squashy_why',
      lines: const [
        StoryMessage(
          'Purpose doesn\'t matter to me. Need matters. Your seed needs warmth. You need the seed. That\'s enough reason for any creature of the shore to help.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_pouch_description',
    ),

    Scene(
      id: 'ep3_squashy_pride',
      lines: const [
        StoryMessage(
          'Can you? For how long? Through how much cold? Through a crossing that takes days?',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'No. Pride is a poor insulator.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_pouch_description',
    ),

    Scene(
      id: 'ep3_london_connection',
      lines: const [
        StoryMessage('Squashy pauses.'),
        StoryMessage(
          'London doesn\'t send anyone. But she and I understand the same thing—that some gifts matter less for what they do and more for what they signal.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That someone cares. That you\'re not alone in your carrying.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_pouch_description',
    ),

    Scene(
      id: 'ep3_pouch_description',
      lines: const [
        StoryMessage(
          'I have woven a warming pouch from the dried grasses of the shore, heated in the sun for days, and layered with silks—spider silks, actually—that hold heat the way almost nothing else can.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The pouch is small. Meant to hold something precious and keep it alive. It\'s meant for your seed.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Squashy produces the pouch—it appears from the sand beside her, as if she\'d been carrying it hidden all along.',
        ),
        StoryMessage(
          'The pouch is small, soft, made of woven natural fibers in shades of cream and pale green. It radiates warmth. Inside, you can see the faint glow of retained solar heat.',
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label:
              '"I\'ll take it. The seed needs protection, and I accept that."',
          nextScene: 'ep3_accept_pouch',
          statEffects: {'connectivity': 2},
        ),
        SceneChoice(
          letter: 'B',
          label: '"What\'s the cost? Nothing is given freely."',
          nextScene: 'ep3_pouch_cost',
        ),
        SceneChoice(
          letter: 'C',
          label:
              '"Will the seed understand? Will it know it\'s being protected?"',
          nextScene: 'ep3_seed_understanding',
        ),
        SceneChoice(
          letter: 'D',
          label: '"How do I use it? How does it work?"',
          nextScene: 'ep3_pouch_usage',
        ),
      ],
    ),

    Scene(
      id: 'ep3_accept_pouch',
      lines: const [
        StoryMessage(
          'That\'s wise. No shame in accepting help.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_place_seed',
    ),

    Scene(
      id: 'ep3_pouch_cost',
      lines: const [
        StoryMessage(
          'No cost. But there is a debt of knowledge.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'If you survive the crossing—if you reach the place beyond the water—remember that a small snake on a beach helped keep you warm.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Remember that kindness exists in small forms.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_place_seed',
    ),

    Scene(
      id: 'ep3_seed_understanding',
      lines: const [
        StoryMessage(
          'Seeds know warmth. They know it in their deepest parts.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'This pouch will speak to it in a language older than words. It will say: You are cared for. You are held. You will not be abandoned.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_place_seed',
    ),

    Scene(
      id: 'ep3_pouch_usage',
      lines: const [
        StoryMessage(
          'Simply place the seed inside when the warmth matters most. The pouch will keep it stable—not growing warmer, but retaining what heat it already has.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It will keep the warmth in. The pouch itself will warm from the seed\'s glow, and that warmth will cycle back. A closed system. A held space.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_place_seed',
    ),

    Scene(
      id: 'ep3_place_seed',
      lines: const [
        StoryMessage(
          'You accept the pouch. It is warm in your talons—almost alive with heat. The sensation is comforting.',
        ),
        StoryMessage(
          'You carefully place Dawn\'s Seed into the warming pouch.',
        ),
        StoryMessage(
          'The moment the seed touches the interior, the glow BRIGHTENS. The amber light becomes vivid, almost red-gold.',
        ),
        StoryMessage(
          'The seed seems to recognize the warmth, to settle into it. The pouch responds to the seed\'s heat, creating a cycle—seed warming pouch, pouch warming seed.',
        ),
        StoryMessage('A closed system of care.'),
        StoryMessage(
          '[Warming Pouch obtained | Contains Dawn\'s Seed. Creates a cycle of warmth. Seed-light brightens to red-gold.]',
          kind: MessageKind.system,
          isBold: true,
        ),
        StoryMessage(
          'There. Now your seed is held. Now you can carry it across the water without wondering if it will survive.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The pouch will preserve what warmth it has. That is all anyone can do—preserve what is precious, hold it safe, and trust the journey.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_unnamed_tree_hint',
      onEnter: (state) {
        if (!state.inventory.contains('Warming Pouch')) {
          state.inventory.add('Warming Pouch');
        }
        state.vitality += 1;
      },
      waitDuration: const Duration(minutes: 20),
    ),

    Scene(
      id: 'ep3_unnamed_tree_hint',
      lines: const [
        StoryMessage(
          'Before you depart, Squashy settles onto the warm sand beside you. Her voice becomes quieter—more serious.',
        ),
        StoryMessage(
          'You will cross the water. That much is necessary. And on the other side, you will find ice, and the tree that froze. Abies. That is your path.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But there is something else. Something that neither London nor Salix told you, because they do not know. Because it is hidden. Because it is guarded.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'In the depths of the water—far deeper than you will fly, deeper than most creatures dare to venture—there is a tree. An UNNAMED TREE.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'She has no name because she exists in a place beyond naming. A place without light. Without sun. Without the seasons you know.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That tree holds knowledge that you will need. Knowledge about the path forward. Knowledge about what the seed truly is.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Knowledge about how to move through the world without freezing, without shedding away everything you are.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"How do I reach this tree? How do I get past the guardians?"',
          nextScene: 'ep3_tree_fish_explanation',
        ),
        SceneChoice(
          letter: 'B',
          label: '"Should I go there? Should I risk it before finding Abies?"',
          nextScene: 'ep3_unnamed_priority',
        ),
        SceneChoice(
          letter: 'C',
          label: '"What kind of knowledge? What does the Unnamed Tree know?"',
          nextScene: 'ep3_unnamed_knowledge',
        ),
        SceneChoice(
          letter: 'D',
          label:
              '"I don\'t have time for hidden trees and mysterious fish. I need to reach Abies."',
          nextScene: 'ep3_unnamed_skip',
        ),
      ],
    ),

    Scene(
      id: 'ep3_tree_fish_explanation',
      lines: const [
        StoryMessage(
          'I don\'t know. That\'s the point. The Unnamed Tree will be found only by those who need to find it.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'If you need that knowledge badly enough, you\'ll find your way. If you don\'t, the ocean will keep its secrets.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The tree is guarded by seven rare orange fish—the TREE FISH. They circle her endlessly. They have never been named. They speak no language you would recognize.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But they understand protection. They understand purpose. They will not let you pass unless you belong there.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_squashy_conclusion',
    ),

    Scene(
      id: 'ep3_unnamed_priority',
      lines: const [
        StoryMessage(
          'Only you know the answer. But I will tell you this—Abies is the past reaching. The ice island is where reaching backward led.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The Unnamed Tree is something else. Something that might show you how to reach forward instead.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_squashy_conclusion',
    ),

    Scene(
      id: 'ep3_unnamed_knowledge',
      lines: const [
        StoryMessage(
          'About the origin of the seed. About Dawn. About what it truly means to plant something in a broken world.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'About the difference between reaching and releasing. Things that cannot be learned anywhere else.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_squashy_conclusion',
    ),

    Scene(
      id: 'ep3_unnamed_skip',
      lines: const [
        StoryMessage(
          'Then don\'t search for it. The ocean is vast. You can sail past the Unnamed Tree forever and never know you missed it.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But if the moment comes when you need what that tree knows, look for the orange light in the deepest places. Seven lights, moving together. That\'s how you\'ll find the way down.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_squashy_conclusion',
    ),

    Scene(
      id: 'ep3_squashy_conclusion',
      lines: const [
        StoryMessage(
          'The knowledge is there if you need it. The Tree Fish guard it. The Unnamed Tree holds it.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But the journey itself—the crossing, the ice, the reaching—that must come first. Find your own answers first.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Then, if you find yourself lost, remember: there is a tree in the deep, and she waits for those who are ready to learn.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'That\'s all I can say. That\'s all I\'m allowed to say.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_squashy_farewell',
      waitDuration: const Duration(minutes: 5),
    ),

    Scene(
      id: 'ep3_squashy_farewell',
      lines: const [
        StoryMessage(
          'Squashy slides back toward the warm sand, preparing to depart.',
        ),
        StoryMessage(
          'The warming pouch will serve you. The seed is held. Your journey continues.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But remember: what you carry is not just yours to carry alone. The rainforest warmed it. The shore wove a pouch for it. A snake helped you protect it.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A tree in the ocean waits to teach you about it. You are not as alone as you feel. None of us are.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"Thank you, Squashy. I won\'t forget."',
          nextScene: 'ep3_final_departure',
        ),
        SceneChoice(
          letter: 'B',
          label: '"I\'ll find the Unnamed Tree. I\'ll learn what she knows."',
          nextScene: 'ep3_final_departure',
        ),
        SceneChoice(
          letter: 'C',
          label: '"Will I see you again?"',
          nextScene: 'ep3_see_again',
        ),
        SceneChoice(
          letter: 'D',
          label: '[Simply wave goodbye, turn toward the ocean]',
          nextScene: 'ep3_final_departure',
        ),
      ],
    ),

    Scene(
      id: 'ep3_see_again',
      lines: const [
        StoryMessage(
          'The shore is long. It\'s possible. But shores change. You change. The likelihood of the same moment happening twice is very small.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Be grateful for this one.',
          character: StoryCharacter.squashy,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep3_final_departure',
    ),

    Scene(
      id: 'ep3_final_departure',
      lines: const [
        StoryMessage(
          'Squashy slides away, her scaled body catching the last light of afternoon. In moments, she\'s indistinguishable from the sand itself.',
        ),
        StoryMessage(
          'But her gift remains warm in your talons. The seed, safely held in the warming pouch, glows steadily with golden light. The warmth is consistent. Real. Reliable.',
        ),
        StoryMessage(
          'The vial of rainforest liquid remains in your other talon—still inert, still waiting, still warm with the day\'s heat.',
        ),
        StoryMessage(
          'Dawn\'s Branch, heavy with moisture and story, remains held close.',
        ),
        StoryMessage(
          'The Flask of Tears, warm against your side, pulses gently with the memory shards it carries.',
        ),
        StoryMessage(
          'You have been given gifts by the forest, by the shore, by a small snake with bright eyes.',
        ),
        StoryMessage(
          'You have learned that you cannot carry everything alone. You have learned that accepting help is not weakness.',
        ),
        StoryMessage('Now you turn toward the ocean.'),
        StoryMessage(
          'The water stretches beyond sight. Vast. Unknown. Waiting.',
        ),
        StoryMessage('Beyond that water is ice, and the tree that froze.'),
        StoryMessage(
          'But in the depths, in the places where light does not reach, seven orange fish circle an Unnamed Tree. They wait. They guard. They know something.',
        ),
        StoryMessage(
          'Not yet. Not yet. But eventually, perhaps, when you are ready.',
        ),
        StoryMessage(
          'For now: the crossing. For now: Abies. For now: the journey forward.',
        ),
        StoryMessage('You spread your wings and turn toward the open water.'),
        StoryMessage('The shore falls behind you. The new ocean begins.'),
        StoryMessage(
          'EPISODE COMPLETE: THE TANGLED FOREST',
          kind: MessageKind.episodeHeader,
        ),
        StoryMessage(
          'Before the crossing, a message from the depths drifts into your mind...',
          kind: MessageKind.narrative,
          isItalic: true,
        ),
        StoryMessage(
          '0x47 0x52 0x30 0x56 0x45 0x20 0x57 0x41 0x49 0x54 0x53',
          kind: MessageKind.system,
          isBold: true,
        ),
        StoryMessage(
          '"Only those who have shed the burden of \'Totals\' may pass the Unnamed Gate."',
          kind: MessageKind.narrative,
          isItalic: true,
        ),
        StoryMessage(
          'The path forward through the Frozen Crossing awaits...',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.none,
      onEnter: (state) {
        state.episodeComplete = true;
        state.londonUnlocked = true;
        state.stability += 1;
        state.connectivity += 1;
        state.seedWarmth = 15; // Steadily lost warmth throughout the episode
      },
      waitDuration: const Duration(hours: 5),
    ),
  ];
}
