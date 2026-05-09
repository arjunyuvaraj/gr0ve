import 'package:gr0ve/features/grove/episodes/episode_02_weeping_willow.dart';
import 'package:gr0ve/features/grove/episodes/episode_03_tangled_forest.dart';
import 'package:gr0ve/features/grove/models/grove_models.dart';
import 'package:gr0ve/features/grove/episodes/episode_00_dawn.dart';
import 'package:gr0ve/features/grove/episodes/episode_01_orchard.dart';

final List<Episode> groveEpisodes = [
  Episode(
    id: 'ep0',
    number: 0,
    title: 'The Dawn',
    description:
        'A fading dawn, a seed held tight, a branch that bends toward fading light.',
    buildScenes: buildEpisode00Dawn,
  ),
  Episode(
    id: 'ep1',
    number: 1,
    title: 'The Prosperous Orchard',
    description:
        'Two orchards stood where choice was drawn, one locked, one wild beneath the dawn.',
    buildScenes: buildEpisode01Orchard,
  ),
  Episode(
    id: 'ep2',
    number: 2,
    title: 'The Weeping Willow',
    description:
        'A silent grove where dark waters lie, the willow weeps beneath a broken sky.',
    buildScenes: buildEpisode02WeepingWillow,
  ),
  Episode(
    id: 'ep3',
    number: 3,
    title: 'The Tangled Rainforest',
    description:
        'Through woven roots and dripping stone, the deepest paths are walked alone.',
    buildScenes: buildEpisode03TangledForest,
  ),
];
