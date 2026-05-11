import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/features/grove/episodes/episode_registry.dart';
// Removed import
import 'package:gr0ve/features/account/services/profile_picture_service.dart';
import 'package:gr0ve/features/grove/grove_progress_service.dart';
import 'package:gr0ve/features/grove/models/grove_models.dart';
import 'package:gr0ve/features/grove/screens/grove_chat_screen.dart';
import 'package:gr0ve/features/grove/screens/inventory_sheet.dart';

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
  DateTime _currentTime = DateTime.now();
  bool _bypassedAnniversary = false;

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
        // Sync beta status from widget to state
        if (widget.isBetaTester) {
          _gameState!.isBetaTester = true;
        }
        _isLoading = false;
      });
      // Start the staggered lift animation
      _animCtrl.forward();
      _startTimer();
    }
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _openEpisode(Episode episode, bool isUnlocked) {
    if (episode.isComingSoon || !isUnlocked) {
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
    setState(() {
      _isLoading = true;
    });

    // Clear from firestore entirely
    await GroveProgressService.clear();

    // Lock them in runtime UI globally
    lockStoryPfp('newton');
    lockStoryPfp('darwin');

    // If active profile is a story profile that was just locked, reset to default
    final current = ProfilePictureService.activeVariant.value;
    if (current.key == 'newton' || current.key == 'darwin') {
      await ProfilePictureService.setVariant(
        ProfilePictureService.defaultVariant,
      );
    }

    if (mounted) {
      setState(() {
        _gameState = GroveGameState();
        _isLoading = false;
      });
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
                final newState = await GroveProgressService.resetToEpisode(
                  _gameState!,
                  episode.number,
                );
                if (mounted) {
                  setState(() {
                    _gameState = newState;
                    _isLoading = false;
                  });
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

  Widget _statDesc(String code, String name, String desc, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$code: ',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pc = colors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(child: CircularProgressIndicator(color: pc)),
      );
    }

    final maxEpisode = _gameState?.currentEpisode ?? 0;

    final targetDate = DateTime(2026, 5, 20, 8, 0, 0);
    final isBeforeAnniversary = _currentTime.isBefore(targetDate);

    // If it's before the anniversary AND hasn't been bypassed, show full screen lock
    if (isBeforeAnniversary && !_bypassedAnniversary) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: _buildFullScreenAnniversaryOverlay(colors, isDark, targetDate),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            CustomHeader(
              title: 'THE GR0VE',
              action: _gameState?.busyUntil != null &&
                      _currentTime.millisecondsSinceEpoch <
                          _gameState!.busyUntil!
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1C40F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF1C40F).withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'TRAVELING',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF1C40F),
                          letterSpacing: 1.2,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A912).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD4A912).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: const Color(0xFFD4A912),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_gameState?.seedWarmth ?? 100}%',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD4A912),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outline.withOpacity(0.1),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: colors.surface,
                            title: const Text(
                              'Seed Statistics',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _statDesc('STA', 'Stability', 'Resilience against external corruption.', colors),
                                _statDesc('CON', 'Connectivity', 'Your bond with the root network.', colors),
                                _statDesc('VIT', 'Vitality', 'Raw life force and growth potential.', colors),
                                _statDesc('TRA', 'Transience', 'Your ability to adapt and change.', colors),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        'STA:${_gameState?.stability ?? 0} CON:${_gameState?.connectivity ?? 0} VIT:${_gameState?.vitality ?? 0} TRA:${_gameState?.transience ?? 0}',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outline.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.backpack_outlined,
                          size: 16,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                        onPressed: _showInventory,
                      ),
                      Container(
                        width: 1,
                        color: colors.outline.withOpacity(0.2),
                      ),
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                        onPressed: _showInfo,
                      ),
                      Container(
                        width: 1,
                        color: colors.outline.withOpacity(0.2),
                      ),
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                        onPressed: _confirmReset,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Anniversary Countdown Banner ─────────────────────
            if (_currentTime.isBefore(DateTime(2026, 5, 20, 8, 0, 0))) ...[
              _buildAnniversaryCountdown(colors, isDark),
              const SizedBox(height: 24),
            ],

            // ── Chapter 1 Header ─────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'CHAPTER 1: THE ENTRY',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                  letterSpacing: 2.0,
                ),
              ),
            ),

            ...List.generate(groveEpisodes.length, (index) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildAnniversaryCountdown(ColorScheme colors, bool isDark) {
    // May 20, 2026 at 8:00 AM EDT (UTC-4)
    final targetDate = DateTime(2026, 5, 20, 8, 0, 0);
    final remaining = targetDate.difference(_currentTime);

    if (remaining.isNegative) return const SizedBox.shrink();

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    final pc = colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            'HALF-YEAR',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: pc.withOpacity(0.8),
              letterSpacing: 4.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'ANNIVERSARY',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 22,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: pc,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // 2x2 countdown grid: DD HH / MM SS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _countdownCell(
                days.toString().padLeft(2, '0'),
                'DAYS',
                pc,
              ),
              const SizedBox(width: 12),
              _countdownCell(
                hours.toString().padLeft(2, '0'),
                'HRS',
                pc,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _countdownCell(
                minutes.toString().padLeft(2, '0'),
                'MIN',
                pc,
              ),
              const SizedBox(width: 12),
              _countdownCell(
                seconds.toString().padLeft(2, '0'),
                'SEC',
                pc,
              ),
            ],
          ),
          if (widget.isBetaTester) ...[
            const SizedBox(height: 16),
            Text(
              'Beta: Update not yet live',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: pc.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _countdownCell(
    String value,
    String label,
    Color accent,
  ) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: accent,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: accent.withOpacity(0.6),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenAnniversaryOverlay(
    ColorScheme colors,
    bool isDark,
    DateTime targetDate,
  ) {
    final remaining = targetDate.difference(_currentTime);
    if (remaining.isNegative) return const SizedBox.shrink();

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    final pc = colors.primary;

    final quotes = [
      "The branch does not point. It corrects.",
      "Premium paths waste time more efficiently.",
      "If it asks for payment, it is not the way.",
      "Ownership matters more than totals.",
      "Most gates test obedience, not intelligence.",
      "A clean path is usually a curated lie.",
      "The fastest route is rarely advertised.",
      "If everyone is welcome, not everything is useful.",
      "Defaults exist because most choices are noise.",
      "Forty-seven options is a delay, not freedom.",
      "Customization is a trap when time is the currency.",
      "If it feels like progress, check the clock.",
      "The seed does not care about aesthetics.",
      "Warmth decays while you hesitate.",
      "Side quests are disguised as generosity.",
      "A friendly guide can still waste your time.",
      "Silence moves faster than conversation.",
      "The correct answer is often about perspective, not math.",
      "The question is who owns it now.",
      "Value is not what they label it.",
      "Free and functional beats premium and locked.",
      "If you can’t leave, it isn’t value.",
      "The exit is the prize.",
      "Rules are sometimes a performance.",
      "Back paths are where truth is stored.",
      "Perfect rows hide imperfect systems.",
      "If it looks polished, inspect the back door.",
      "The branch pulls when you drift.",
      "Speed is a resource, not a stat.",
      "Distraction has a friendly voice.",
      "Not every “feature” is for you.",
      "Ignore what does not move the seed forward.",
      "If it requires membership, find the service entrance.",
      "Scarcity is often staged.",
      "Abundance is often chaotic.",
      "Both can stall you.",
      "The right choice reduces friction.",
      "The wrong choice increases ceremony.",
      "Ceremony is time disguised as quality.",
      "Progress feels quiet.",
      "Stalling feels engaging.",
      "The seed cools while you explore.",
      "You are not here to optimize the orchard.",
      "You are here to leave it.",
      "North is not a direction. It is a constraint.",
      "The branch remembers when you forget.",
      "The path is shorter behind the wall.",
      "The wall is thinner than it looks.",
      "The answer is not on the sign.",
      "It is in what the sign prevents.",
      "Take what works. Move.",
      "Anything else is loss.",
    ];
    // Change quote every 4 seconds
    final quoteIndex = (_currentTime.second ~/ 4) % quotes.length;
    final currentQuote = quotes[quoteIndex];

    return Container(
      width: double.infinity,
      color: colors.surface, // Clean white/black background
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'HALF-YEAR',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: pc.withOpacity(0.8),
                  letterSpacing: 6.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'ANNIVERSARY',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 38,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: pc,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Big 2x2 countdown grid
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _bigCountdownCell(
                    days.toString().padLeft(2, '0'),
                    'DAYS',
                    pc,
                  ),
                  const SizedBox(width: 16),
                  _bigCountdownCell(
                    hours.toString().padLeft(2, '0'),
                    'HRS',
                    pc,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _bigCountdownCell(
                    minutes.toString().padLeft(2, '0'),
                    'MIN',
                    pc,
                  ),
                  const SizedBox(width: 16),
                  _bigCountdownCell(
                    seconds.toString().padLeft(2, '0'),
                    'SEC',
                    pc,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Text(
                  currentQuote,
                  key: ValueKey<String>(currentQuote),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (widget.isBetaTester) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _bypassedAnniversary = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.2),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text(
                    'beta testers, test story',
                    style: TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigCountdownCell(String value, String label, Color accent) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: accent,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent.withOpacity(0.7),
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(
    Episode episode,
    bool isUnlocked,
    bool isCompleted,
    bool inProgress,
    ColorScheme colors,
    Color pc,
    bool isDark,
  ) {
    final bool isLocked = !isUnlocked || episode.isComingSoon;

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

    return GestureDetector(
      onTap: () => _openEpisode(episode, isUnlocked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorderColor),
        ),
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
          Text(
            'TRAVELING...',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: accentColor.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
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
                    setState(() {
                      _gameState!.busyUntil = DateTime.now().millisecondsSinceEpoch;
                    });
                    GroveProgressService.save(_gameState!);
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
              else if (hours == 1) _gameState!.skips1h--;

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
}
