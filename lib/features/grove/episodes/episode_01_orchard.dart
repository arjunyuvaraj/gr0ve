import 'dart:math';
import 'package:gr0ve/features/grove/models/grove_models.dart';
import 'package:gr0ve/features/grove/grove_progress_service.dart';

List<Scene> buildEpisode01Orchard() {
  return [
    Scene(
      id: 'ep1_intro',
      lines: const [
        StoryMessage(
          'EPISODE 1: THE ORCHARD',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage('You fly for hours. The branch tugs downward.'),
        StoryMessage(
          'Below: two vast orchards, separated by a weathered fence.',
        ),
        StoryMessage(
          'To the LEFT — Apple trees in perfect rows. White signs. Clean paths.\n"NEWTON\'S ORCHARD — Premium Experience Guaranteed"',
          isItalic: true,
        ),
        StoryMessage(
          'To the RIGHT — Orange trees sprawling wild. Hand-painted signs. Buzzing life.\n"DARWIN\'S GROVE — Open to All"',
          isItalic: true,
        ),
        StoryMessage(
          'Between them, a cluster of confused sparrows huddle on the fence, chirping nervously.',
        ),
        StoryMessage(
          'Dawn\'s Branch glows faintly. One of these holds what you need.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.choices,
      choices: [
        const SceneChoice(
          letter: 'A',
          label: 'Enter Newton\'s Apple Orchard',
          nextScene: 'ep1_newton_travel',
          setPath: 'apple',
          waitDuration: Duration(hours: 4),
        ),
        const SceneChoice(
          letter: 'B',
          label: 'Enter Darwin\'s Orange Grove',
          nextScene: 'ep1_darwin_travel',
          setPath: 'orange',
          waitDuration: Duration(hours: 4),
        ),
        const SceneChoice(
          letter: 'C',
          label: 'Talk to the sparrows',
          nextScene: 'ep1_sparrows',
        ),
        const SceneChoice(
          letter: 'D',
          label: 'Examine the fence',
          nextScene: 'ep1_fence',
        ),
        const SceneChoice(
          letter: 'E',
          label: 'Check inventory',
          nextScene: 'ep1_inventory_check',
        ),
      ],
    ),

    Scene(
      id: 'ep1_sparrows',
      lines: const [
        StoryMessage('You land near the cluster of sparrows on the fence.'),
        StoryMessage(
          'A sleek sparrow with deep red feathers chirps authoritatively:',
          character: StoryCharacter.redSparrow,
          isItalic: true,
        ),
        StoryMessage(
          'Order! That\'s what you need. Follow the apple paths to the left. Newton manages time here—it\'s expensive, but it\'s progress.',
          character: StoryCharacter.redSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A scruffy sparrow with orange-tipped wings hops over, chirping loudly:',
          character: StoryCharacter.orangeSparrow,
          isItalic: true,
        ),
        StoryMessage(
          'Don\'t listen to Red! Safety is just a fancy word for "boring." Come to the orange grove. It\'s wild, it\'s free, and Darwin always has a story worth hearing.',
          character: StoryCharacter.orangeSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A third sparrow with mottled gray feathers sighs from the corner of the fence.',
          character: StoryCharacter.graySparrow,
          isItalic: true,
        ),
        StoryMessage(
          'They\'ve been arguing for days. Bob would have known what to do... but he\'s gone now.',
          character: StoryCharacter.graySparrow,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: [
        const SceneChoice(
          letter: 'A',
          label: '"Why Newton\'s?" (To Red Sparrow)',
          nextScene: 'ep1_sparrows_newton_story',
        ),
        const SceneChoice(
          letter: 'B',
          label: '"Why Darwin\'s?" (To Orange Sparrow)',
          nextScene: 'ep1_sparrows_darwin_story',
        ),
        const SceneChoice(
          letter: 'C',
          label: '"Who\'s Bob?"',
          nextScene: 'ep1_sparrows_bob_story',
        ),
        const SceneChoice(
          letter: 'D',
          label: '"How long have you been here?"',
          nextScene: 'ep1_sparrows_stuck',
        ),
        const SceneChoice(
          letter: 'E',
          label: 'Thank them and move on',
          nextScene: 'ep1_intro',
          statEffects: {'connectivity': 1},
        ),
      ],
    ),

    Scene(
      id: 'ep1_sparrows_bob_story',
      lines: const [
        StoryMessage(
          'The gray sparrow looks down sadly.',
          character: StoryCharacter.graySparrow,
          isItalic: true,
        ),
        StoryMessage(
          'Bob was our leader. The wise one. He always knew which way to fly.',
          character: StoryCharacter.graySparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Red Sparrow adds:',
          character: StoryCharacter.redSparrow,
          isItalic: true,
        ),
        StoryMessage(
          'He was exploring the forest to the east. Rumor has it the wind blew too hard and he got stuck in a tree, never to be found again.',
          character: StoryCharacter.redSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Orange Sparrow shakes their head:',
          character: StoryCharacter.orangeSparrow,
          isItalic: true,
        ),
        StoryMessage(
          'Ever since Bob disappeared, we\'ve been... lost. Can\'t decide. Can\'t move forward. Just... stuck on this fence.',
          character: StoryCharacter.orangeSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Don\'t be like Bob. Don\'t get lost in the trees. And don\'t be like us—stuck between choices.',
          character: StoryCharacter.graySparrow,
          kind: MessageKind.dialogue,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep1_sparrows',
      onEnter: (state) {
        state.connectivity += 1;
      },
    ),

    Scene(
      id: 'ep1_sparrows_bob_story_notification',
      lines: const [
        StoryMessage(
          '[CONNECTIVITY +1]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep1_sparrows',
    ),

    Scene(
      id: 'ep1_sparrows_newton_story',
      lines: const [
        StoryMessage(
          'Orange Sparrow groans:',
          character: StoryCharacter.orangeSparrow,
          isItalic: true,
        ),
        StoryMessage(
          'The left? Newton\'s place? Ugh.',
          character: StoryCharacter.orangeSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I got stuck at the entrance riddle for THREE HOURS. When I finally got in, everything cost Golden Apples. I don\'t have Golden Apples! Who has Golden Apples?!',
          character: StoryCharacter.orangeSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Red Sparrow chimes in:',
          character: StoryCharacter.redSparrow,
          isItalic: true,
        ),
        StoryMessage(
          'I took the Scenic Route. All 47 trees. My wings still ache.',
          character: StoryCharacter.redSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The gray sparrow, looking slightly smug:',
          character: StoryCharacter.graySparrow,
          isItalic: true,
        ),
        StoryMessage(
          'I found a back way. Service entrance. Newton wasn\'t happy but he couldn\'t stop me. Just... read the signs carefully. Not everything premium is necessary.',
          character: StoryCharacter.graySparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '[CONNECTIVITY +1]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep1_sparrows',
      onEnter: (state) {
        state.connectivity += 1;
      },
    ),

    Scene(
      id: 'ep1_sparrows_darwin_story',
      lines: const [
        StoryMessage(
          'Red Sparrow laughs:',
          character: StoryCharacter.redSparrow,
          isItalic: true,
        ),
        StoryMessage(
          'Darwin\'s grove? Oh, that was... chaotic.',
          character: StoryCharacter.redSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I spent TWO HOURS customizing my juice. Forty-seven options! In the end it tasted exactly like regular orange juice.',
          character: StoryCharacter.redSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Orange Sparrow nods sympathetically:',
          character: StoryCharacter.orangeSparrow,
          isItalic: true,
        ),
        StoryMessage(
          'Darwin kept offering me side quests. "Wanna see this cool experiment?" "Check out this hybrid tree!" I never made it to the center. My seed went completely cold.',
          character: StoryCharacter.orangeSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The gray sparrow seems content:',
          character: StoryCharacter.graySparrow,
          isItalic: true,
        ),
        StoryMessage(
          'I just asked Darwin what he recommended. He said "default." I took default everything. In and out in ten minutes. Sometimes simple is best.',
          character: StoryCharacter.graySparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '[CONNECTIVITY +1]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep1_sparrows',
      onEnter: (state) {
        state.connectivity += 1;
      },
    ),

    Scene(
      id: 'ep1_sparrows_stuck',
      lines: const [
        StoryMessage('We can\'t decide!', kind: MessageKind.dialogue),
        StoryMessage(
          'Red Sparrow gestures left:',
          character: StoryCharacter.redSparrow,
          isItalic: true,
        ),
        StoryMessage(
          'That one looks professional. Organized. Safe.',
          character: StoryCharacter.redSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Orange Sparrow gestures right:',
          character: StoryCharacter.orangeSparrow,
          isItalic: true,
        ),
        StoryMessage(
          'But that one looks fun! Creative! Welcoming!',
          character: StoryCharacter.orangeSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The gray sparrow sighs:',
          character: StoryCharacter.graySparrow,
          isItalic: true,
        ),
        StoryMessage(
          'We\'ve been here so long our seeds went cold. Now we\'re just... waiting. For what, I don\'t know.',
          character: StoryCharacter.graySparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Don\'t be like us. Choose. Move forward. Even a wrong choice is better than no choice.',
          character: StoryCharacter.graySparrow,
          kind: MessageKind.dialogue,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep1_intro',
      onEnter: (state) {
        state.transience += 1;
      },
    ),

    Scene(
      id: 'ep1_fence',
      lines: const [
        StoryMessage(
          'You land on the weathered fence between the two orchards.',
        ),
        StoryMessage(
          'To your left, the air smells of parchment and crisp fruit. To your right, it smells of warm earth and citrus zest.',
        ),
        StoryMessage(
          'The sparrows around you are locked in a quiet debate, hopping between the fence posts but never crossing them.',
        ),
      ],
      inputType: InputType.choices,
      choices: [
        const SceneChoice(
          letter: 'A',
          label: 'Fly toward Newton\'s (Left)',
          nextScene: 'ep1_newton_travel',
          setPath: 'apple',
          waitDuration: Duration(hours: 5),
        ),
        const SceneChoice(
          letter: 'B',
          label: 'Fly toward Darwin\'s (Right)',
          nextScene: 'ep1_darwin_travel',
          setPath: 'orange',
          waitDuration: Duration(hours: 5),
        ),
        const SceneChoice(
          letter: 'C',
          label: 'Listen to their argument',
          nextScene: 'ep1_sparrows',
        ),
      ],
    ),

    Scene(
      id: 'ep1_inventory_check',
      lines: const [
        StoryMessage(
          'You check what you\'re carrying.',
          kind: MessageKind.system,
        ),
        StoryMessage(
          'Just the Branch. Just the Seed. Just yourself.',
          kind: MessageKind.system,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep1_intro',
    ),

    Scene(
      id: 'ep1_newton_travel',
      lines: const [
        StoryMessage(
          'You take flight, heading left toward the white-gated orchard.',
        ),
        StoryMessage(
          'Stick to the paths. Newton likes things tidy. If you show him you value order, he might just help you.',
          character: StoryCharacter.redSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The journey will be long. You settle into a steady, rhythmic flight pattern.',
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'newton_entrance',
      waitDuration: Duration(hours: 5),
      onEnter: (state) {
        state.seedWarmth -= 5;
      },
    ),

    Scene(
      id: 'ep1_darwin_travel',
      lines: const [
        StoryMessage(
          'You take flight, heading right toward the vibrant orange canopy.',
        ),
        StoryMessage(
          'Welcome to the wild side! Don\'t worry about the mess. Everything here is an experiment. Even you!',
          character: StoryCharacter.orangeSparrow,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The humidity rises as you dive into the thick, sweet air of the grove.',
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_entrance',
      waitDuration: Duration(hours: 5),
      onEnter: (state) {
        state.seedWarmth -= 5;
      },
    ),

    Scene(
      id: 'newton_entrance',
      lines: const [
        StoryMessage(
          'NEWTON\'S APPLE ORCHARD',
          kind: MessageKind.episodeHeader,
        ),
        StoryMessage('You land at the entrance.'),
        StoryMessage(
          'Immediately: order. Precision. Every apple tree in identical rows.',
        ),
        StoryMessage(
          'A towering tree stands at the center. Its bark is white. Its apples gleam.',
        ),
        StoryMessage('This is Newton.', isItalic: true),
        StoryMessage(
          'Welcome. I don\'t know you. But I can tell you carry something valuable. Before you may enter, answer my riddle:',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'newton_riddle',
    ),

    Scene(
      id: 'newton_riddle',
      lines: const [
        StoryMessage(
          'I am not alive, but I grow. I have no lungs, but I need air. I have no mouth, but water kills me. What am I?',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.freeText,
      onFreeText: (input, state) {
        final lower = input.toLowerCase().trim();
        if (lower.contains('fire') || lower.contains('flame')) {
          state.newtonRiddleSolved = true;
          return 'newton_riddle_correct';
        }
        if (lower.contains('apple')) return 'newton_riddle_apple';
        if (lower.contains('tree')) return 'newton_riddle_tree';
        return 'newton_riddle_wrong';
      },
    ),

    Scene(
      id: 'newton_riddle_correct',
      lines: const [
        StoryMessage(
          'Correct.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The gates open. You are permitted entry.',
          kind: MessageKind.system,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'newton_interior',
      waitDuration: Duration(hours: 3),
      onEnter: (state) {
        state.stability += 1;
      },
    ),

    Scene(
      id: 'newton_riddle_apple',
      lines: const [
        StoryMessage(
          'An apple? You just walked past 10,000 of them and you think THAT\'S the riddle? How disappointing.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.freeText,
      onFreeText: (input, state) {
        final lower = input.toLowerCase().trim();
        if (lower.contains('fire') || lower.contains('flame')) {
          state.newtonRiddleSolved = true;
          return 'newton_riddle_correct';
        }
        return 'newton_riddle_wrong';
      },
    ),

    Scene(
      id: 'newton_riddle_tree',
      lines: const [
        StoryMessage(
          'A tree? I AM a tree. That\'s not an answer. That\'s observation. Try again.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.freeText,
      onFreeText: (input, state) {
        final lower = input.toLowerCase().trim();
        if (lower.contains('fire') || lower.contains('flame')) {
          state.newtonRiddleSolved = true;
          return 'newton_riddle_correct';
        }
        return 'newton_riddle_wrong';
      },
    ),

    Scene(
      id: 'newton_riddle_wrong',
      lines: const [
        StoryMessage(
          'No. And I don\'t explain wrong answers. Try again.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.freeText,
      onFreeText: (input, state) {
        final lower = input.toLowerCase().trim();
        if (lower.contains('fire') || lower.contains('flame')) {
          state.newtonRiddleSolved = true;
          return 'newton_riddle_correct';
        }
        return 'newton_riddle_wrong';
      },
    ),

    Scene(
      id: 'newton_interior',
      lines: const [
        StoryMessage('You enter the orchard proper.'),
        StoryMessage(
          'Each tree is labeled. Each tree is identical. Each tree\'s apples are priced.',
        ),
        StoryMessage(
          '"Standard Apples — 5 Tokens"\n"Premium Apples — 20 Tokens"\n"Exclusive Golden Apples™ — CONTACT FOR PRICING"',
          isItalic: true,
        ),
        StoryMessage('Newton appears again.', isItalic: true),
        StoryMessage(
          'Welcome, riddle-solver. I see you have something valuable. But everything here is also valuable. The question is — what can you afford?',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Ask about the Standard Apples',
          nextScene: 'newton_standard_apples',
        ),
        SceneChoice(
          letter: 'B',
          label: 'Ask about the Premium Apples',
          nextScene: 'newton_premium_apples',
        ),
        SceneChoice(
          letter: 'C',
          label: 'Ask about the Golden Apples™',
          nextScene: 'newton_golden_apples',
        ),
        SceneChoice(
          letter: 'D',
          label: 'Try to find an alternate route',
          nextScene: 'newton_service_entrance',
        ),
      ],
    ),

    Scene(
      id: 'newton_standard_apples',
      lines: const [
        StoryMessage(
          'The standard ones? They\'re... adequate. Free from disease. Nutritious. But indistinguishable from any other apple tree farmer\'s product.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'If you want adequate, you can have those. But adequate means interchangeable. Forgettable. Is that what you want?',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Take the Standard Apples',
          nextScene: 'newton_standard_apples_take',
          waitDuration: Duration(hours: 1),
        ),
        SceneChoice(
          letter: 'B',
          label: 'Ask about Premium',
          nextScene: 'newton_premium_apples',
        ),
        SceneChoice(
          letter: 'C',
          label: 'Look for another way',
          nextScene: 'newton_service_entrance',
        ),
      ],
    ),

    Scene(
      id: 'newton_service_entrance',
      lines: const [
        StoryMessage(
          'You find a small, unlabeled gate near the back of the orchard.',
        ),
        StoryMessage(
          'It leads through a narrow path, bypassing the rows of premium trees.',
        ),
        StoryMessage('The air here is quieter. No white signs. No prices.'),
        StoryMessage(
          'You see Newton in the distance, tending to a small, unremarkable sapling. He doesn\'t see you.',
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'newton_juice_station',
      waitDuration: Duration(hours: 2),
      onEnter: (state) {
        state.vitality += 1;
      },
    ),

    Scene(
      id: 'newton_premium_apples',
      lines: const [
        StoryMessage(
          'Premium. Now those are worth discussing.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Specially bred. Enhanced flavor. Consistent quality. The kind of apple a serious person eats.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'They cost more, naturally. But you get what you pay for. Isn\'t that right?',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Ask how much they cost',
          nextScene: 'newton_premium_cost',
        ),
        SceneChoice(
          letter: 'B',
          label: 'Ask about the Golden Apples',
          nextScene: 'newton_golden_apples',
        ),
        SceneChoice(
          letter: 'C',
          label: 'Go with Standard',
          nextScene: 'newton_standard_apples_take',
          waitDuration: Duration(hours: 3),
        ),
      ],
    ),

    Scene(
      id: 'newton_premium_cost',
      lines: const [
        StoryMessage(
          'That... depends on your resources. Do you have anything valuable?',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The Branch is quite striking. Perhaps...',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Offer the Branch',
          nextScene: 'newton_branch_trade',
          waitDuration: Duration(hours: 4),
        ),
        SceneChoice(
          letter: 'B',
          label: 'Decline and take Standard',
          nextScene: 'newton_standard_apples_take',
          waitDuration: Duration(hours: 3),
        ),
        SceneChoice(
          letter: 'C',
          label: 'Ask about the Golden Apples',
          nextScene: 'newton_golden_apples',
        ),
      ],
    ),

    Scene(
      id: 'newton_branch_trade',
      lines: const [
        StoryMessage(
          'You offer the Branch. Its light pulses against the orchard\'s sterile rows.',
        ),
        StoryMessage(
          'Newton\'s presence seems to widen, examining the Branch carefully.',
        ),
        StoryMessage(
          'Fascinating. A primitive link, but full of... potential energy.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'I accept. Here are your apples. Better than anything else you\'ll find.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'newton_juice_station',
      onEnter: (state) {
        state.stability += 2;
      },
    ),

    Scene(
      id: 'newton_standard_apples_take',
      lines: const [
        StoryMessage(
          'You choose the standard apples. Newton seems disappointed, but not surprised.',
        ),
        StoryMessage(
          'Sufficient. Functional. Forgettable. Like everything else in the public domain.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Take them. Proceed to the center.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'newton_juice_station',
      waitDuration: Duration(hours: 2),
      onEnter: (state) {
        state.seedWarmth = max(0, state.seedWarmth - 3);
      },
    ),

    Scene(
      id: 'newton_golden_apples',
      lines: const [
        StoryMessage(
          'The Golden Apples™?',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Those are... an investment. Fewer than 100 exist. Each is numbered. Verified. Exclusive.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'They don\'t just taste good. They grant prestige. They prove you\'re the kind of person who can afford prestige.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'But I suspect you don\'t have what it takes to acquire one.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
          isItalic: true,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Take the challenge',
          nextScene: 'newton_golden_challenge',
        ),
        SceneChoice(
          letter: 'B',
          label: 'Go with Premium',
          nextScene: 'newton_premium_cost',
        ),
        SceneChoice(
          letter: 'C',
          label: 'Go with Standard',
          nextScene: 'newton_standard_apples_take',
          waitDuration: Duration(hours: 3),
        ),
      ],
    ),

    Scene(
      id: 'newton_golden_challenge',
      lines: const [
        StoryMessage(
          'I thought so. A true competitor.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Then you must prove your worth. Navigate my entire orchard. Visit all 47 trees on the Scenic Route. Only then will you earn a Golden Apple™.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Fail to complete the route, and you get the Standard. And you\'ll never leave the same.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Accept the quest',
          nextScene: 'newton_scenic_route',
          waitDuration: Duration(hours: 4),
        ),
        SceneChoice(
          letter: 'B',
          label: 'Decline, take Standard',
          nextScene: 'newton_standard_apples_take',
          waitDuration: Duration(hours: 3),
        ),
      ],
    ),

    Scene(
      id: 'newton_scenic_route',
      lines: const [
        StoryMessage(
          'You set off down the Scenic Route. It\'s gorgeous, but it never ends.',
          kind: MessageKind.system,
        ),
        StoryMessage(
          'Hours pass. You see 47 different apple varieties. Each more impressive than the last.',
        ),
        StoryMessage(
          'Tree #1: Honeycrisp Premium. Tree #2: Fuji Select. Tree #3: Granny Smith Elite...',
          isItalic: true,
        ),
        StoryMessage('Your wings ache. Your seed grows colder.'),
        StoryMessage(
          '[Seed warmth: 70%  |  Getting tired...]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'newton_juice_station',
      onEnter: (state) {
        state.seedWarmth = max(0, state.seedWarmth - 10);
        state.transience += 1;
      },
    ),

    Scene(
      id: 'newton_juice_station',
      lines: const [
        StoryMessage(
          'You arrive at the center. A juice station. Three options.',
          kind: MessageKind.system,
        ),
        StoryMessage('Newton\'s presence looms.', isItalic: true),
        StoryMessage(
          'So. Which will you choose?',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'iJuice Premium™',
          nextScene: 'newton_juice_premium',
          waitDuration: Duration(hours: 3),
        ),
        SceneChoice(
          letter: 'B',
          label: 'iJuice Plus™',
          nextScene: 'newton_juice_plus',
          waitDuration: Duration(hours: 4),
        ),
        SceneChoice(
          letter: 'C',
          label: 'Apple Juice — Standard',
          nextScene: 'newton_juice_standard',
          waitDuration: Duration(hours: 2),
        ),
      ],
    ),

    Scene(
      id: 'newton_juice_premium',
      lines: const [
        StoryMessage(
          'Premium. An excellent choice.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A sleek glass fills with golden liquid. It sparkles.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'You paid for quality. And quality is what you received. Remember this feeling.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '[iJuice Premium™ obtained]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'newton_exit_puzzle',
      onEnter: (state) {
        if (!state.inventory.contains('iJuice Premium™'))
          state.inventory.add('iJuice Premium™');
        state.vitality += 2;
        state.stability += 1;
      },
    ),

    Scene(
      id: 'newton_juice_plus',
      lines: const [
        StoryMessage(
          'Plus. The middle option. How... strategic.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A polished cup fills with enhanced apple juice.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'Better than standard. Not quite premium. The safe choice for those who want more but fear commitment.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '[iJuice Plus™ obtained]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'newton_exit_puzzle',
      onEnter: (state) {
        if (!state.inventory.contains('iJuice Plus™'))
          state.inventory.add('iJuice Plus™');
        state.vitality += 1;
      },
    ),

    Scene(
      id: 'newton_juice_standard',
      lines: const [
        StoryMessage(
          'The... standard option. How... practical.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'A wooden cup fills with simple apple juice.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'Free, functional, utterly unremarkable. But it works. I suppose that\'s what matters.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '[Apple Juice obtained]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'newton_exit_puzzle',
      onEnter: (state) {
        if (!state.inventory.contains('Apple Juice'))
          state.inventory.add('Apple Juice');
        state.vitality += 1;
      },
    ),

    Scene(
      id: 'newton_exit_puzzle',
      lines: const [
        StoryMessage(
          'You turn to leave. The exit is... missing.',
          isBold: true,
        ),
        StoryMessage('Instead: a white wall with text:'),
        StoryMessage(
          'TO EXIT NEWTON\'S ORCHARD:\nProve you understand simplicity.\n\nWhat is the most valuable thing in this orchard?',
          kind: MessageKind.system,
          isBold: true,
        ),
        StoryMessage(
          'Most say "the premium apples." They stay here forever.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
          isItalic: true,
        ),
      ],
      inputType: InputType.freeText,
      onFreeText: (input, state) {
        final lower = input.toLowerCase().trim();
        final exitWords = [
          'exit',
          'leaving',
          'freedom',
          'getting out',
          'leave',
          'the exit',
          'way out',
          'escape',
          'door',
          'free',
        ];
        if (exitWords.any((w) => lower.contains(w))) {
          state.newtonExitSolved = true;
          state.stability += 1;
          return 'newton_exit_correct';
        }
        state.newtonExitAttempts++;
        if (lower.contains('premium') || lower.contains('apple'))
          return 'newton_exit_wrong_premium';
        if (lower.contains('tree')) return 'newton_exit_wrong_tree';
        if (lower.contains('juice')) return 'newton_exit_wrong_juice';
        if (state.newtonExitAttempts >= 3) return 'newton_exit_hint';
        return 'newton_exit_wrong_generic';
      },
    ),

    ..._buildExitRetryScenes(
      'premium',
      'Incorrect. Locked in perceived value.',
    ),
    ..._buildExitRetryScenes('tree', 'Incorrect. You worship the surface.'),
    ..._buildExitRetryScenes(
      'juice',
      'Incorrect. You mistake product for purpose.',
    ),

    Scene(
      id: 'newton_exit_wrong_generic',
      lines: const [
        StoryMessage(
          'Incorrect. Think about what matters most to someone who is trapped.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.freeText,
      onFreeText: _exitFreeTextHandler,
    ),

    Scene(
      id: 'newton_exit_hint',
      lines: const [
        StoryMessage(
          'You\'ve been here too long. Here\'s a hint:',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
          isItalic: true,
        ),
        StoryMessage(
          'A premium cage is still a cage. What would you want most if you were caged?',
          isItalic: true,
        ),
      ],
      inputType: InputType.freeText,
      onFreeText: (input, state) {
        final lower = input.toLowerCase().trim();
        final exitWords = [
          'exit',
          'leaving',
          'freedom',
          'getting out',
          'leave',
          'the exit',
          'way out',
          'escape',
          'door',
          'free',
        ];
        if (exitWords.any((w) => lower.contains(w))) {
          state.newtonExitSolved = true;
          return 'newton_exit_correct';
        }
        state.newtonExitSolved = true;
        return 'newton_exit_correct';
      },
    ),

    Scene(
      id: 'newton_exit_correct',
      lines: const [
        StoryMessage(
          '...correct.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The most valuable thing is the ability to leave. A premium cage is still a cage.\n\nYou understand. Go.',
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The wall dissolves.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep1_complete',
      waitDuration: Duration(hours: 36),
    ),

    Scene(
      id: 'darwin_entrance',
      lines: const [
        StoryMessage('DARWIN\'S ORANGE GROVE', kind: MessageKind.episodeHeader),
        StoryMessage('You land at the entrance.'),
        StoryMessage(
          'Immediately, it\'s different. The air smells alive — citrus, earth, wild growth.',
        ),
        StoryMessage(
          'A cheerful scarecrow waves. Patched overalls. Mismatched buttons. One arm sewn with different fabric.',
        ),
        StoryMessage('This is Darwin.'),
        StoryMessage(
          'Hey! Welcome! Come on in!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He notices you hesitating.', isItalic: true),
        StoryMessage(
          'Oh — wait, gotta make sure you\'re not a bot. Just answer this real quick:\n\nI\'m thinking of a number between 1 and 100. What is it?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.freeText,
      onFreeText: (input, state) => 'darwin_number_response',
    ),

    Scene(
      id: 'darwin_number_response',
      lines: const [
        StoryMessage(
          'Oh! That\'s... not it. It was 47. But hey, you TRIED! That\'s what counts. Come in!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The gate swings open — not with a chime, but with a cheerful creak.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage('You enter a wild, sprawling grove.'),
        StoryMessage(
          'Orange trees everywhere — different sizes, shapes, varieties. No two alike.',
        ),
        StoryMessage(
          'Some labeled: "Navel Orange v2.1" "Blood Orange Beta" "Experimental Hybrid — DO NOT EAT (or do, I\'m not a cop)"',
          isItalic: true,
        ),
        StoryMessage(
          'Paths branch in every direction. Some lead to trees. Some to experiments. Some to nowhere.',
        ),
        StoryMessage('Darwin walks alongside you.', isItalic: true),
        StoryMessage(
          'So! You carrying something important? That seed looks cool. Where you headed?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Tell Darwin about the grove',
          nextScene: 'darwin_conversation',
        ),
        SceneChoice(
          letter: 'B',
          label: 'Stay silent, keep walking',
          nextScene: 'darwin_path_choice',
        ),
        SceneChoice(
          letter: 'C',
          label: 'Ask Darwin about the oranges',
          nextScene: 'darwin_orange_question',
        ),
        SceneChoice(
          letter: 'D',
          label: 'Follow Dawn\'s Branch direction',
          nextScene: 'darwin_follow_branch',
        ),
      ],
    ),

    Scene(
      id: 'darwin_orange_question',
      lines: const [
        StoryMessage(
          'These oranges? Oh, they\'re all open-source genetics. Anyone can grow \'em. Fork \'em. Remix \'em.',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'He points to a bizarre-looking tree with purple-tinted oranges.',
          isItalic: true,
        ),
        StoryMessage(
          'That one over there? A user submission. Someone crossed a blood orange with... honestly I forget. But it WORKS! Wild, right?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_conversation',
      onEnter: (state) {
        state.connectivity += 1;
      },
    ),

    Scene(
      id: 'darwin_conversation',
      lines: const [
        StoryMessage(
          'The grove! Oh man, I\'ve heard of that place. Super exclusive, right? You gotta meet some Keeper dude?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Want me to show you around? Or you good to explore on your own?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"Show me around!"',
          nextScene: 'darwin_tour',
          waitDuration: Duration(hours: 3),
        ),
        SceneChoice(
          letter: 'B',
          label: '"I\'ll explore on my own"',
          nextScene: 'darwin_path_choice',
        ),
        SceneChoice(
          letter: 'C',
          label: '"Just point me to the center"',
          nextScene: 'darwin_direct_ask',
        ),
      ],
      onEnter: (state) {
        state.darwinConversationHad = true;
        state.connectivity += 1;
      },
    ),

    Scene(
      id: 'darwin_tour',
      lines: const [
        StoryMessage(
          'Awesome! Okay so, this way —',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Darwin leads you down a winding path.', isItalic: true),
        StoryMessage(
          'This is the Experimental Section. See that tree? Auto-peeling oranges. Still buggy though. Sometimes the whole tree peels.',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'And THAT one produces oranges that taste like whatever you\'re thinking about. Mostly works. One time someone thought about dirt and... yeah.',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The tour continues. And continues. Darwin has SO much to show you.',
          isItalic: true,
        ),
        StoryMessage(
          'Dawn\'s Seed pulses. Getting colder.',
          kind: MessageKind.system,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"This is amazing, but I need to get to the center"',
          nextScene: 'darwin_tour_exit',
        ),
        SceneChoice(
          letter: 'B',
          label: 'Keep following the tour',
          nextScene: 'darwin_tour_continue',
        ),
        SceneChoice(
          letter: 'C',
          label: '"Can we speed this up?"',
          nextScene: 'darwin_tour_fast',
        ),
      ],
    ),

    Scene(
      id: 'darwin_tour_continue',
      lines: const [
        StoryMessage('Darwin beams and continues enthusiastically.'),
        StoryMessage(
          'Oh! And over here — this is the Failure Garden. All the experiments that DIDN\'T work. But we keep them because failure is data!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'See that one? Tried to make seedless oranges. Made oranges that are ONLY seeds. Whoops!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Thirty minutes later...', isItalic: true),
        StoryMessage(
          '[Seed warmth: 65%  |  Time spent wandering]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_path_choice',
      onEnter: (state) {
        state.seedWarmth = max(0, state.seedWarmth - 10);
        state.transience += 1;
        state.vitality -= 2;
      },
    ),

    Scene(
      id: 'darwin_tour_fast',
      lines: const [
        StoryMessage(
          'Oh! Yeah, sure! Fast tour mode activated!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Darwin speaks rapidly, gesturing at trees in a blur.',
          isItalic: true,
        ),
        StoryMessage(
          'Experimental section — FAIL garden — Hybrid zone — User submissions — Compost pile we\'re hiding — The big tree — Community board — Old weather station —',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('And... done! You feel dizzy.', kind: MessageKind.system),
        StoryMessage(
          '[CONNECTIVITY +1  |  VITALITY −1]',
          kind: MessageKind.system,
          isBold: true,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_path_choice',
      onEnter: (state) {
        state.connectivity += 1;
        state.vitality -= 1;
      },
    ),

    Scene(
      id: 'darwin_tour_exit',
      lines: const [
        StoryMessage(
          'Oh! Yeah, okay, I get it. The branch thing. Gotta go!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Darwin points you toward the center.', isItalic: true),
        StoryMessage(
          'Straight ahead. Hard to miss. And hey — the tree there is really cool! You\'ll like it.',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_path_choice',
      onEnter: (state) {
        state.vitality += 1;
      },
    ),

    Scene(
      id: 'darwin_path_choice',
      lines: const [
        StoryMessage('You stand at a junction. Multiple paths forward.'),
        StoryMessage(
          'The center is somewhere ahead. Dawn\'s Branch glows faintly.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Follow the shortest path',
          nextScene: 'darwin_direct_center',
          waitDuration: Duration(hours: 3),
        ),
        SceneChoice(
          letter: 'B',
          label: 'Explore side paths',
          nextScene: 'darwin_exploration',
          waitDuration: Duration(hours: 4),
        ),
        SceneChoice(
          letter: 'C',
          label: 'Call out to Darwin for help',
          nextScene: 'darwin_help',
        ),
      ],
    ),

    Scene(
      id: 'darwin_direct_center',
      lines: const [
        StoryMessage('You navigate efficiently toward the center.'),
        StoryMessage('No detours. No distractions. Just focus.'),
        StoryMessage('The seed stays warm. You feel good about this.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_tree_center',
      onEnter: (state) {
        state.vitality += 1;
      },
    ),

    Scene(
      id: 'darwin_exploration',
      lines: const [
        StoryMessage('You take a winding path. Curious. Exploring.'),
        StoryMessage(
          'You see beautiful experiments. Fascinating side quests. All optional. All tempting.',
        ),
        StoryMessage('Time passes. Your seed gets colder.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_tree_center',
      onEnter: (state) {
        state.seedWarmth = max(0, state.seedWarmth - 10);
        state.transience += 1;
      },
    ),

    Scene(
      id: 'darwin_help',
      lines: const [
        StoryMessage('Darwin appears.', isItalic: true),
        StoryMessage(
          'Oh hey! Want me to guide you? Or figure it out yourself?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"Guide me to the center"',
          nextScene: 'darwin_direct_center',
          waitDuration: Duration(hours: 3),
        ),
        SceneChoice(
          letter: 'B',
          label: '"I got this"',
          nextScene: 'darwin_path_choice',
        ),
      ],
      onEnter: (state) {
        state.connectivity += 1;
      },
    ),

    Scene(
      id: 'darwin_follow_branch',
      lines: const [
        StoryMessage(
          'You let the Branch guide you. It glows, pulling you toward a specific path.',
        ),
        StoryMessage('The path is shorter. Clearer. Direct.'),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_tree_center',
      onEnter: (state) {
        state.stability += 1;
      },
    ),

    Scene(
      id: 'darwin_direct_ask',
      lines: const [
        StoryMessage(
          'Oh! You want the quick route? Yeah, sure, follow me!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_tree_center',
      onEnter: (state) {
        state.stability += 1;
      },
    ),

    Scene(
      id: 'darwin_tree_center',
      lines: const [
        StoryMessage('You arrive at the center of Darwin\'s Grove.'),
        StoryMessage(
          'A massive orange tree stands in the middle. Its fruit glows faintly.',
        ),
        StoryMessage('Darwin stands proudly beside it.', isItalic: true),
        StoryMessage(
          'So! You made it! What do you think?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'And more importantly — want some juice?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Ask about juice options',
          nextScene: 'darwin_juice_ask',
        ),
        SceneChoice(
          letter: 'B',
          label: 'Just take the default',
          nextScene: 'darwin_juice_recommend',
          waitDuration: Duration(hours: 2),
        ),
        SceneChoice(
          letter: 'C',
          label: 'Decline juice',
          nextScene: 'darwin_juice_skip',
        ),
      ],
    ),

    Scene(
      id: 'darwin_juice_ask',
      lines: const [
        StoryMessage(
          'Juice options? Oh man, SO many!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You can customize sweetness, pulp level, thickness, temperature, color enhancement, organic certification, artisanal sourcing...',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Darwin trails off, watching your confusion.',
          isItalic: true,
        ),
        StoryMessage(
          'Or... I can just make you something? I know what tastes good?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: 'Customize extensively',
          nextScene: 'darwin_juice_customize',
        ),
        SceneChoice(
          letter: 'B',
          label: 'Let Darwin choose',
          nextScene: 'darwin_juice_recommend',
          waitDuration: Duration(hours: 2),
        ),
        SceneChoice(
          letter: 'C',
          label: 'Skip juice',
          nextScene: 'darwin_juice_skip',
        ),
      ],
    ),

    Scene(
      id: 'darwin_juice_customize',
      lines: const [
        StoryMessage('You dive into the options. All 47 of them.'),
        StoryMessage(
          'Orange juice with a hint of blood orange, medium pulp, slightly thick, room temperature, with natural color enhancement but no artisanal certification because that seems excessive...',
        ),
        StoryMessage('Thirty minutes later...', isItalic: true),
        StoryMessage(
          'You have the most personalized juice ever created. It\'s delicious. It tastes exactly like... orange juice.',
        ),
        StoryMessage('Darwin watches, amused.', isItalic: true),
        StoryMessage(
          'See? Custom is good but... you just made orange juice.',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_side_quest',
      onEnter: (state) {
        state.seedWarmth = max(0, state.seedWarmth - 15);
        state.transience += 2;
        if (!state.inventory.contains('Custom Orange Juice'))
          state.inventory.add('Custom Orange Juice');
      },
    ),

    Scene(
      id: 'darwin_juice_recommend',
      lines: const [
        StoryMessage('Darwin nods and hands you a glass.', isItalic: true),
        StoryMessage(
          'Here. Just right.',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '[Orange Juice obtained]',
          kind: MessageKind.system,
          isBold: true,
        ),
        StoryMessage(
          'You just... took what works. Respect.',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('[VITALITY +1]', kind: MessageKind.system, isBold: true),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_side_quest',
      onEnter: (state) {
        if (!state.inventory.contains('Orange Juice'))
          state.inventory.add('Orange Juice');
        state.vitality += 1;
      },
    ),

    Scene(
      id: 'darwin_juice_skip',
      lines: const [
        StoryMessage(
          'Oh... you don\'t want juice? But... why not?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'It\'s free! And customizable! And... okay, fine. Your call.',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"I\'m in a hurry"',
          nextScene: 'darwin_side_quest',
        ),
        SceneChoice(
          letter: 'B',
          label: '"I don\'t need it"',
          nextScene: 'darwin_side_quest',
        ),
        SceneChoice(
          letter: 'C',
          label: '"What does it actually do?"',
          nextScene: 'darwin_juice_explain',
        ),
      ],
      onEnter: (state) {
        state.vitality += 1;
      },
    ),

    Scene(
      id: 'darwin_juice_explain',
      lines: const [
        StoryMessage(
          'What does it do? Oh! Good question.',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Uh... refreshment? Vitamin C? Proof you were here?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Honestly, mostly symbolic. Every orchard gives travelers something. It\'s tradition.',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Want some or nah?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'darwin_juice_recommend',
    ),

    Scene(
      id: 'darwin_side_quest',
      lines: const [
        StoryMessage(
          'You turn to leave. The exit is clearly marked. Open. Easy.',
        ),
        StoryMessage(
          'But Darwin appears, bouncing with excitement.',
          isItalic: true,
        ),
        StoryMessage(
          'Oh! Before you go — wanna see something cool?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The path forward is right there. Clear. Open. You could just... walk out.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'I\'ve been working on this new puzzle. It\'s like... a logic thing? Super fun! Wanna try?',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Totally optional! But I think you\'d like it!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Dawn\'s Seed pulses. Still warm, but... you should probably go.',
          kind: MessageKind.system,
          isItalic: true,
        ),
      ],
      inputType: InputType.choices,
      choices: const [
        SceneChoice(
          letter: 'A',
          label: '"Sure, show me"',
          nextScene: 'darwin_puzzle',
        ),
        SceneChoice(
          letter: 'B',
          label: '"No thanks, I need to go"',
          nextScene: 'darwin_exit_efficient',
          waitDuration: Duration(hours: 10),
        ),
        SceneChoice(
          letter: 'C',
          label: '"Maybe later?"',
          nextScene: 'darwin_exit_polite',
          waitDuration: Duration(hours: 10),
        ),
        SceneChoice(
          letter: 'D',
          label: 'Walk away without responding',
          nextScene: 'darwin_exit_efficient',
          waitDuration: Duration(hours: 10),
        ),
      ],
    ),

    Scene(
      id: 'darwin_puzzle',
      lines: const [
        StoryMessage(
          'Awesome! Okay so —',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'Darwin pulls out a complicated diagram scratched in the dirt.',
          isItalic: true,
        ),
        StoryMessage(
          'Three birds want to cross a river. They have a boat. But the boat only holds two birds. And one of the birds is afraid of water, so someone has to stay with them...',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'The puzzle is long. Convoluted. Interesting, sure, but...',
        ),
        StoryMessage('Fifteen minutes later...', isItalic: true),
        StoryMessage(
          'Nice! You solved it! Here\'s your reward —',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('He checks his pockets.', isItalic: true),
        StoryMessage(
          '— a cool rock I found!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          '[Cool Rock obtained... momentarily]\n(This does nothing. It\'s literally just a rock.)',
          kind: MessageKind.system,
        ),
        StoryMessage(
          '[Seed warmth: 65%]\n[TRANSIENCE +1]',
          kind: MessageKind.system,
          isBold: true,
        ),
        StoryMessage(
          'You spent time on a distraction. You throw the rock into the distance for fun. It skips twice before vanishing.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep1_complete',
      waitDuration: Duration(hours: 10),
      onEnter: (state) {
        state.seedWarmth = max(0, state.seedWarmth - 10);
        state.transience += 1;
      },
    ),

    Scene(
      id: 'darwin_exit_efficient',
      lines: const [
        StoryMessage(
          'Oh! Yeah, totally get it. Safe travels!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage(
          'You exit the grove efficiently. Direct. No distractions.',
          kind: MessageKind.system,
          isItalic: true,
        ),
        StoryMessage(
          'Darwin waves enthusiastically as you leave.',
          isItalic: true,
        ),
        StoryMessage('[VITALITY +1]', kind: MessageKind.system, isBold: true),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep1_complete',
      onEnter: (state) {
        state.vitality += 1;
      },
    ),

    Scene(
      id: 'darwin_exit_polite',
      lines: const [
        StoryMessage(
          'Cool! Come back anytime! The grove is always here!',
          character: StoryCharacter.darwin,
          kind: MessageKind.dialogue,
        ),
        StoryMessage('Darwin waves as you fly away.', isItalic: true),
        StoryMessage(
          'You leave politely. Not rushed, not distracted. Just... done.',
        ),
      ],
      inputType: InputType.continueOnly,
      nextScene: 'ep1_complete',
    ),

    Scene(
      id: 'ep1_complete',
      lines: const [
        StoryMessage(
          'EPISODE COMPLETE',
          kind: MessageKind.episodeHeader,
          isBold: true,
        ),
        StoryMessage(
          'You exit the orchard, juice in your talon. Dawn\'s Branch pulses — pointing north now.',
        ),
        StoryMessage('Your choices have shaped you.', isBold: true),
      ],
      inputType: InputType.none,
      onEnter: (state) {
        state.seedWarmth = state.seedWarmth.clamp(60, 90);
        state.episodeComplete = true;
        if (state.chosenPath == 'apple') {
          state.inventory.removeWhere(
            (item) => item == 'Orange Juice' || item == 'Custom Orange Juice',
          );
          if (!state.inventory.contains('Apple Juice')) {
            state.inventory.add('Apple Juice');
          }
          state.newtonUnlocked = true;
          state.darwinUnlocked = false;
        } else {
          state.inventory.removeWhere(
            (item) =>
                item == 'Apple Juice' ||
                item == 'iJuice Premium™' ||
                item == 'iJuice Plus™',
          );
          if (!state.inventory.contains('Orange Juice')) {
            state.inventory.add('Orange Juice');
          }
          state.darwinUnlocked = true;
          state.newtonUnlocked = false;
        }
      },
    ),
  ];
}

List<Scene> _buildExitRetryScenes(String variant, String response) {
  return [
    Scene(
      id: 'newton_exit_wrong_$variant',
      lines: [
        StoryMessage(
          response,
          character: StoryCharacter.newtonsTree,
          kind: MessageKind.dialogue,
        ),
      ],
      inputType: InputType.freeText,
      onFreeText: _exitFreeTextHandler,
    ),
  ];
}

String? _exitFreeTextHandler(String input, GroveGameState state) {
  final lower = input.toLowerCase().trim();
  final exitWords = [
    'exit',
    'leaving',
    'freedom',
    'getting out',
    'leave',
    'the exit',
    'way out',
    'escape',
    'door',
    'free',
  ];
  if (exitWords.any((w) => lower.contains(w))) {
    state.newtonExitSolved = true;
    return 'newton_exit_correct';
  }
  state.newtonExitAttempts++;
  if (state.newtonExitAttempts >= 3) return 'newton_exit_hint';
  return 'newton_exit_wrong_generic';
}
