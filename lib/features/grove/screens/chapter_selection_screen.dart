import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/features/easter_eggs/hidden_fish/hidden_fish.dart';
import 'package:gr0ve/features/easter_eggs/hidden_fish/hidden_fish_service.dart';
import 'package:gr0ve/features/grove/episodes/episode_registry.dart';

import 'package:gr0ve/features/account/services/profile_picture_service.dart';
import 'package:gr0ve/features/grove/grove_progress_service.dart';
import 'package:gr0ve/features/grove/models/grove_models.dart';
import 'package:gr0ve/features/grove/screens/grove_chat_screen.dart';
import 'package:gr0ve/core/services/network_time_service.dart';
import 'package:gr0ve/features/grove/screens/inventory_sheet.dart';
import 'package:gr0ve/features/grove/widgets/stat_scale_widget.dart';

class ChapterSelectionScreen extends StatefulWidget {
  final bool isBetaTester;
  const ChapterSelectionScreen({super.key, this.isBetaTester = false});

  @override
  State<ChapterSelectionScreen> createState() => _ChapterSelectionScreenState();
}

class _ChapterSelectionScreenState extends State<ChapterSelectionScreen>
    with SingleTickerProviderStateMixin {
  GroveGameState? _gameState;
  bool _isLoading = true;
  Timer? _refreshTimer;
  DateTime _currentTime = NetworkTimeService.now;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadProgress();
  }

  @override
  void didUpdateWidget(covariant ChapterSelectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBetaTester != oldWidget.isBetaTester) {
      if (_gameState != null) {
        setState(() {
          _gameState!.isBetaTester = widget.isBetaTester;
        });
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final state = await GroveProgressService.load();
    if (mounted) {
      setState(() {
        _gameState = state ?? GroveGameState();

        if (widget.isBetaTester) {
          _gameState!.isBetaTester = true;
        }
        _isLoading = false;
      });

      _animCtrl.forward();
      _startTimer();
    }
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = NetworkTimeService.now;
        });
      }
    });
  }

  void _openEpisode(Episode episode, bool isUnlocked) {
    if (episode.isComingSoon && !widget.isBetaTester) {
      HapticFeedback.lightImpact();
      return;
    }

    if (!isUnlocked && !widget.isBetaTester) {
      HapticFeedback.lightImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroveChatScreen(
          episode: episode,
          initialState: _gameState!,
          isBetaTester: widget.isBetaTester,
          onProgressUpdated: (newState) {
            setState(() {
              _gameState = newState;
            });
          },
        ),
      ),
    );
  }

  void _resetProgress() async {
    setState(() => _isLoading = true);
    try {
      await GroveProgressService.clear();

      lockStoryPfp('newton');
      lockStoryPfp('darwin');
      lockStoryPfp('salix');
      lockStoryPfp('london');

      final current = ProfilePictureService.activeVariant.value;
      if (['newton', 'darwin', 'salix', 'london'].contains(current.key)) {
        await ProfilePictureService.setVariant(
          ProfilePictureService.defaultVariant,
        );
      }

      if (mounted) {
        setState(() {
          _gameState = GroveGameState();
        });
      }
    } catch (e) {
      debugPrint('[ChapterSelection] Reset error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'Reset Progress',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to reset all your progress in The Gr0ve? This cannot be undone.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetProgress();
              },
              child: Text(
                'Reset Everything',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmEpisodeReset(Episode episode) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Reset ${episode.title}?',
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This will roll back your stats, inventory, and choices to the beginning of this episode. All progress in later episodes will also be cleared. Continue?',
            style: TextStyle(color: colors.onSurface.withOpacity(0.8)),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final newState = await GroveProgressService.resetToEpisode(
                    _gameState!,
                    episode.number,
                  );

                  if (episode.number <= 3) lockStoryPfp('london');
                  if (episode.number <= 2) lockStoryPfp('salix');
                  if (episode.number <= 1) {
                    lockStoryPfp('newton');
                    lockStoryPfp('darwin');
                  }

                  final currentPfp = ProfilePictureService.activeVariant.value;
                  if ((episode.number <= 1 &&
                          ['newton', 'darwin'].contains(currentPfp.key)) ||
                      (episode.number <= 2 && currentPfp.key == 'salix') ||
                      (episode.number <= 3 && currentPfp.key == 'london')) {
                    await ProfilePictureService.setVariant(
                      ProfilePictureService.defaultVariant,
                    );
                  }

                  if (mounted) {
                    setState(() {
                      _gameState = newState;
                    });
                  }
                } catch (e) {
                  debugPrint('[ChapterSelection] Episode reset error: $e');
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: Text(
                'Reset Episode',
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'The Gr0ve',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Dawn\'s seed is fading. The great gr0ve is the only place it can be planted. But the path is not straight, and the choices you make will determine what kind of tree you ultimately grow.\n\nInstructions: Progress through episodes. Trust Dawn\'s branch. And remember, every answer reshapes your seed.',
            style: TextStyle(height: 1.5, fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Got it',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInventory() {
    TInventorySheet.show(context, _gameState!.inventory);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pc = colors.primary;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(child: CircularProgressIndicator(color: pc)),
      );
    }

    final maxEpisode = _gameState?.currentEpisode ?? 0;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          CustomHeader(title: 'THE GR0VE', action: null),
          const SizedBox(height: 16),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.surfaceContainerHighest.withOpacity(0.3)
                          : colors.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.outline.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A912).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFD4A912).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 14,
                                color: Color(0xFFD4A912),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_gameState?.seedWarmth ?? 100}%',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD4A912),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 1,
                          height: 16,
                          color: colors.outline.withOpacity(0.2),
                        ),
                        const SizedBox(width: 8),

                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _showStatsDialog(colors);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                'STATS',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: colors.primary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 16,
                          color: colors.outline.withOpacity(0.2),
                        ),

                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.backpack_outlined,
                            size: 18,
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                          onPressed: _showInventory,
                        ),
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                          onPressed: _showInfo,
                        ),
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                          onPressed: _confirmReset,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          _buildChapterOneHeader(colors, isDark),

          ...List.generate(4, (index) {
            final ep = groveEpisodes[index];
            final isUnlocked = ep.number <= maxEpisode;
            final isCompleted = ep.number < maxEpisode;
            final inProgress = ep.number == maxEpisode;

            final delay = index * 0.1;
            final slideAnim =
                Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animCtrl,
                    curve: Interval(
                      delay,
                      (delay + 0.5).clamp(0.0, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                );
            final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animCtrl,
                curve: Interval(
                  delay,
                  (delay + 0.5).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
            );

            return FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildChapterCard(
                    ep,
                    isUnlocked,
                    isCompleted,
                    inProgress,
                    colors,
                    pc,
                    isDark,
                  ),
                ),
              ),
            );
          }),
          ValueListenableBuilder<Set<String>>(
            valueListenable: HiddenFishService.foundIds,
            builder: (context, foundIds, _) {
              final isUnlocked =
                  HiddenFishService.isChapterTwoUnlocked.value ||
                  foundIds.length >= HiddenFishService.fish.length;
              return _buildChapterTwoPreview(
                colors,
                pc,
                isDark,
                isUnlocked,
                maxEpisode,
              );
            },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildChapterTwoPreview(
    ColorScheme colors,
    Color pc,
    bool isDark,
    bool isUnlocked,
    int maxEpisode,
  ) {
    final accent = isUnlocked
        ? (isDark ? const Color(0xFF7BDFF2) : const Color(0xFF146C94))
        : colors.onSurface.withOpacity(0.32);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildChapterHeaderStack(
            colors: colors,
            accent: accent,
            badgeRow: SizedBox(
              width: 132,
              height: 32,
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: HiddenFishService.foundIds,
                builder: (context, foundIds, _) {
                  const itemSize = 26.0;
                  const spacing = 16.0;
                  final totalWidth =
                      itemSize + (HiddenFishService.fish.length - 1) * spacing;
                  final start = (132 - totalWidth) / 2;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < HiddenFishService.fish.length; i++)
                        Positioned(
                          left: start + (i * spacing),
                          child: _buildHiddenFishOrb(
                            context,
                            HiddenFishService.fish[i],
                            foundIds.contains(HiddenFishService.fish[i].id),
                            isUnlocked,
                            colors,
                            compact: true,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            chapterLabel: 'CHAPTER 2',
            subtitle: 'INTO THE WATER',
          ),
          const SizedBox(height: 16),
          _buildChapterCard(
            groveEpisodes.firstWhere((episode) => episode.number == 4),
            maxEpisode >= 4,
            maxEpisode > 4,
            maxEpisode == 4,
            colors,
            pc,
            isDark,
          ),
          const SizedBox(height: 12),
          ..._buildChapterTwoEpisodeCards(colors, pc, isDark),
        ],
      ),
    );
  }

  Widget _buildChapterOneHeader(ColorScheme colors, bool isDark) {
    final chosenPath = _gameState?.chosenPath;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: _buildChapterHeaderStack(
          colors: colors,
          accent: colors.primary,
          badgeRow: HiddenFishTrigger(
            id: 'stinger_scorpion',
            gesture: HiddenFishTriggerGesture.longPress,
            child: SizedBox(
              width: 132,
              height: 32,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const itemSize = 26.0;
                  const spacing = 16.0;
                  final totalWidth = itemSize + (5 - 1) * spacing;
                  final start = (constraints.maxWidth - totalWidth) / 2;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: start,
                        child: _buildOrchardTreeBadge(
                          StoryCharacter.dawn,
                          colors,
                          isDark,
                          active: true,
                          compact: true,
                        ),
                      ),
                      Positioned(
                        left: start + spacing,
                        child: _buildOrchardTreeBadge(
                          StoryCharacter.newton,
                          colors,
                          isDark,
                          active: chosenPath == 'apple',
                          compact: true,
                        ),
                      ),
                      Positioned(
                        left: start + spacing * 2,
                        child: _buildOrchardTreeBadge(
                          StoryCharacter.darwin,
                          colors,
                          isDark,
                          active: chosenPath == 'orange',
                          compact: true,
                        ),
                      ),
                      Positioned(
                        left: start + spacing * 3,
                        child: _buildOrchardTreeBadge(
                          StoryCharacter.salix,
                          colors,
                          isDark,
                          active: _gameState?.salixUnlocked ?? false,
                          compact: true,
                        ),
                      ),
                      Positioned(
                        left: start + spacing * 4,
                        child: _buildOrchardTreeBadge(
                          StoryCharacter.london,
                          colors,
                          isDark,
                          active: _gameState?.londonUnlocked ?? false,
                          compact: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          chapterLabel: 'CHAPTER 1',
          subtitle: 'INTO THE FIELD',
        ),
      ),
    );
  }

  Widget _buildChapterHeaderStack({
    required ColorScheme colors,
    required Color accent,
    required Widget badgeRow,
    required String chapterLabel,
    required String subtitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        badgeRow,
        const SizedBox(height: 8),
        Text(
          chapterLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: accent,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildHiddenFishOrb(
    BuildContext context,
    HiddenFishDefinition fish,
    bool isFound,
    bool isUnlocked,
    ColorScheme colors, {
    bool compact = false,
  }) {
    final active = isUnlocked || isFound;
    final circleColor = colors.brightness == Brightness.dark
        ? Color(0xFF1d1d1d)
        : Color(0xFFFFFFFF);
    final fishTint = active ? null : Colors.black;
    final size = compact ? 26.0 : 48.0;
    final padding = compact ? 4.0 : 8.0;

    final orb = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? colors.onSurface.withOpacity(0.18)
              : colors.onSurface.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(active ? 0.12 : 0.06),
            blurRadius: compact ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: SvgPicture.asset(
          fish.asset,
          fit: BoxFit.contain,
          colorFilter: fishTint == null
              ? null
              : const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        ),
      ),
    );

    if (!active) {
      return Semantics(label: 'Hidden fish', child: orb);
    }

    return Semantics(
      label: '${fish.name} found',
      button: true,
      child: GestureDetector(
        onTap: () => HiddenFishService.showInfoDialog(context, fish),
        behavior: HitTestBehavior.opaque,
        child: orb,
      ),
    );
  }

  Widget _buildOrchardTreeBadge(
    StoryCharacter character,
    ColorScheme colors,
    bool isDark, {
    required bool active,
    bool compact = false,
  }) {
    final size = compact ? 26.0 : 42.0;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final asset = character.avatarAsset(brightness);
    final grayscale = active
        ? null
        : const ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.brightness == Brightness.dark
            ? Color(0xFF1a1a1a)
            : Color(0xFFFFFFFF),
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? colors.primary.withOpacity(0.28)
              : colors.onSurface.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(active ? 0.12 : 0.06),
            blurRadius: compact ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 4 : 7),
        child: grayscale == null
            ? Image.asset(asset, fit: BoxFit.contain)
            : ColorFiltered(
                colorFilter: grayscale,
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
      ),
    );
  }

  List<Widget> _buildChapterTwoEpisodeCards(
    ColorScheme colors,
    Color pc,
    bool isDark,
  ) {
    final comingSoonEpisodes = [
      Episode(
        id: 'chapter2_episode5',
        number: 5,
        title: 'The Unnamed Waters',
        description:
            'Waters with no name still remember every step taken into them.',
        buildScenes: _emptyComingSoonScenes,
        isComingSoon: true,
      ),
      Episode(
        id: 'chapter2_episode6',
        number: 6,
        title: 'The Frigid Landfall',
        description:
            'At long last, the final stretch, but a broken wing and final breath',
        buildScenes: _emptyComingSoonScenes,
        isComingSoon: true,
      ),
    ];

    return comingSoonEpisodes
        .map(
          (episode) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildChapterCard(
              episode,
              false,
              false,
              false,
              colors,
              pc,
              isDark,
            ),
          ),
        )
        .toList();
  }

  FutureOr<List<Scene>> _emptyComingSoonScenes() => const <Scene>[];

  Widget _buildChapterCard(
    Episode episode,
    bool isUnlocked,
    bool isCompleted,
    bool inProgress,
    ColorScheme colors,
    Color pc,
    bool isDark,
  ) {
    final bool isLocked =
        !isUnlocked || (episode.isComingSoon && !widget.isBetaTester);

    Color accentColor;
    if (isCompleted && !isLocked) {
      accentColor = isDark ? const Color(0xFF5AE6A0) : const Color(0xFF1F8A5F);
    } else if (inProgress && !isLocked) {
      accentColor = isDark ? const Color(0xFFF1C40F) : const Color(0xFFD4A912);
    } else if (!isLocked) {
      accentColor = pc;
    } else {
      accentColor = colors.onSurface.withOpacity(0.3);
    }

    final cardBgColor = isLocked
        ? colors.surfaceContainerHighest.withOpacity(0.3)
        : accentColor.withOpacity(0.04);

    final cardBorderColor = isLocked
        ? colors.outline.withOpacity(0.1)
        : accentColor.withOpacity(0.3);

    return IgnorePointer(
      ignoring: isLocked,
      child: GestureDetector(
        onTap: () => _openEpisode(episode, isUnlocked),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorderColor),
          ),
          child: Opacity(
            opacity: isLocked ? 0.4 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(isLocked ? 0.2 : 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'EP ${episode.number}',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (episode.isComingSoon) ...[
                      Icon(Icons.lock_rounded, size: 14, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        'COMING SOON',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ] else if (isCompleted) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'COMPLETED',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ] else if (inProgress) ...[
                      Icon(
                        Icons.play_circle_filled_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'IN PROGRESS',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ] else if (isLocked) ...[
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (inProgress &&
                    _gameState?.busyUntil != null &&
                    _currentTime.millisecondsSinceEpoch <
                        _gameState!.busyUntil!) ...[
                  _buildWaitTimer(accentColor, colors),
                ] else ...[
                  Text(
                    episode.title,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isLocked
                          ? colors.onSurface.withOpacity(0.4)
                          : colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    episode.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isLocked
                          ? colors.onSurface.withOpacity(0.3)
                          : colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                if (!isLocked) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isCompleted || inProgress)
                        InkWell(
                          onTap: () => _confirmEpisodeReset(episode),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.restart_alt_rounded,
                                  size: 14,
                                  color: accentColor.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'RESET',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor.withOpacity(0.5),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        isCompleted ? 'REVIEW' : 'ENTER',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isCompleted
                            ? Icons.history_rounded
                            : Icons.arrow_forward_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitTimer(Color accentColor, ColorScheme colors) {
    final remainingMillis =
        _gameState!.busyUntil! - _currentTime.millisecondsSinceEpoch;
    final duration = Duration(
      milliseconds: remainingMillis > 0 ? remainingMillis : 0,
    );

    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: 1.0 - (remainingMillis / (5 * 3600 * 1000)).clamp(0.0, 1.0),
            backgroundColor: accentColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            minHeight: 2,
            borderRadius: BorderRadius.circular(1),
          ),
          const SizedBox(height: 2),
          Text(
            '$h:$m:$s',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: 1.0,
            ),
          ),
          if ((_gameState?.skips1h ?? 0) > 0 ||
              (_gameState?.skips3h ?? 0) > 0 ||
              (_gameState?.skips5h ?? 0) > 0) ...[
            const SizedBox(height: 12),
            if ((_gameState?.skips5h ?? 0) > 0)
              _buildSkipButton(5, _gameState!.skips5h, accentColor),
            if ((_gameState?.skips3h ?? 0) > 0)
              _buildSkipButton(3, _gameState!.skips3h, accentColor),
            if ((_gameState?.skips1h ?? 0) > 0)
              _buildSkipButton(1, _gameState!.skips1h, accentColor),
            if (widget.isBetaTester) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    final isBusy =
                        _gameState!.busyUntil != null &&
                        _gameState!.busyUntil! >
                            NetworkTimeService.now.millisecondsSinceEpoch;
                    if (isBusy) {
                      setState(() {
                        _gameState!.busyUntil =
                            NetworkTimeService.now.millisecondsSinceEpoch;
                      });
                      GroveProgressService.save(_gameState!);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'BETA: SKIP TRAVEL',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSkipButton(int hours, int amount, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: TextButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            setState(() {
              if (hours == 5)
                _gameState!.skips5h--;
              else if (hours == 3)
                _gameState!.skips3h--;
              else if (hours == 1)
                _gameState!.skips1h--;

              final currentBusy = _gameState!.busyUntil ?? 0;
              final skipMs = Duration(hours: hours).inMilliseconds;
              _gameState!.busyUntil = currentBusy - skipMs;
            });
            GroveProgressService.save(_gameState!);
          },
          style: TextButton.styleFrom(
            backgroundColor: accent.withOpacity(0.1),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: accent.withOpacity(0.2)),
            ),
          ),
          child: Text(
            'use ${hours} hr skip time ($amount left)',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ),
      ),
    );
  }

  void _showStatsDialog(ColorScheme colors) {
    if (_gameState == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: const Text(
          'NARRATIVE STATS',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatScaleWidget(
                  label: 'STABILITY',
                  value: _gameState!.stability,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                StatScaleWidget(
                  label: 'CONNECTIVITY',
                  value: _gameState!.connectivity,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                StatScaleWidget(
                  label: 'VITALITY',
                  value: _gameState!.vitality,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                StatScaleWidget(
                  label: 'TRANSIENCE',
                  value: _gameState!.transience,
                  colors: colors,
                ),
              ],
            ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );
  }
}
