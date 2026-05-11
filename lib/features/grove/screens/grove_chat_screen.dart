import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/account/services/profile_picture_service.dart';

import 'package:gr0ve/features/grove/grove_progress_service.dart';
import 'package:gr0ve/features/grove/models/grove_models.dart';
import 'package:gr0ve/features/grove/screens/episode_complete_sheet.dart';

class GroveChatScreen extends StatefulWidget {
  final Episode episode;
  final GroveGameState initialState;
  final bool isBetaTester;
  final ValueChanged<GroveGameState> onProgressUpdated;

  const GroveChatScreen({
    super.key,
    required this.episode,
    required this.initialState,
    this.isBetaTester = false,
    required this.onProgressUpdated,
  });

  @override
  State<GroveChatScreen> createState() => _GroveChatScreenState();
}

class _GroveChatScreenState extends State<GroveChatScreen>
    with TickerProviderStateMixin {
  Timer? _typeTimer;
  Timer? _waitTimer;
  int _currentMsgIdx = 0;
  DateTime _currentTime = DateTime.now();
  late GroveGameState _gameState;
  late List<Scene> _scenes;
  Scene? _currentScene;

  final List<_ChatBubbleData> _bubbles = [];
  bool _isTyping = false;
  bool _showInput = false;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _gameState = widget.initialState;
    _scenes = widget.episode.buildScenes();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // If starting a new episode, default to the first scene of that episode.
    // If resuming the current episode, find the saved scene.
    String startSceneId = _scenes.first.id;

    final pastCompleted = _gameState.currentEpisode > widget.episode.number;

    if (_gameState.currentEpisode == widget.episode.number &&
        _gameState.currentScene.isNotEmpty) {
      // Check if we have the saved scene in this episode
      if (_scenes.any((s) => s.id == _gameState.currentScene)) {
        startSceneId = _gameState.currentScene;
      }
    } else if (!pastCompleted) {
      _gameState.currentEpisode = widget.episode.number;
      _gameState.currentScene = startSceneId;
      _gameState.episodeComplete = false;
      _gameState.episodeHistories[widget.episode.id] = [];
      // Save snapshot of state at the start of this episode
      _gameState.episodeStartStates.putIfAbsent(
        widget.episode.id,
        () => _gameState.toJson(),
      );
      GroveProgressService.save(_gameState);
    }

    // Restore history
    final epKey = widget.episode.id;

    if (_gameState.episodeHistories[epKey]?.isNotEmpty ?? false) {
      _bubbles.addAll(
        _gameState.episodeHistories[epKey]!.map(
          (json) => _ChatBubbleData(message: StoryMessage.fromJson(json)),
        ),
      );

      if (pastCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
          _showInput = false;
          _isTyping = false;
        });
        return; // Halt logic, let them view history
      }
    } else if (pastCompleted) {
      // If completed but no history found, just show generic complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEpisodeComplete();
      });
      return;
    }

    // Delay slight bit before loading so UI can build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pulseCtrl.repeat(reverse: true);

      // Initial timer check
      if (_gameState.busyUntil != null) {
        _startWaitTimer();
      }

      // ONLY load the scene if we don't have bubbles in history for this episode yet,
      // OR if we are just starting fresh. This prevents duplicating messages on app resume.
      if (_bubbles.isEmpty && !pastCompleted) {
        _loadScene(startSceneId);
      } else {
        // If we have history, we just need to set the current scene so input knows what to show
        setState(() {
          _currentScene = _scenes
              .where((s) => s.id == startSceneId)
              .firstOrNull;
          _showInput = _bubbles.isNotEmpty && !_isTyping;
        });
        _scrollToBottom();
      }
    });
  }

  void _startWaitTimer() {
    _waitTimer?.cancel();
    if (mounted) {
      setState(() {
        _currentTime = DateTime.now();
      });
    }
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });

        if (_gameState.busyUntil != null &&
            DateTime.now().millisecondsSinceEpoch >= _gameState.busyUntil!) {
          final next = _gameState.pendingScene;
          _gameState.busyUntil = null;
          _gameState.pendingScene = null;

          if (next != null) {
            _gameState.currentScene = next;
          }

          GroveProgressService.save(_gameState);
          _waitTimer?.cancel();

          if (next != null) {
            _loadScene(next);
          }
        }
      } else {
        _waitTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _waitTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _loadScene(String sceneId) {
    final scene = _scenes.where((s) => s.id == sceneId).firstOrNull;
    if (scene == null) {
      debugPrint('[Grove] Scene not found: $sceneId');
      return;
    }

    // Only set onEnter logic if we're not exceeding current progress or if it's stats-based
    scene.onEnter?.call(_gameState);

    // SAVE PROGRESS: Only if we are playing the LATEST episode
    // Reviews should not overwrite the currentScene of the global state
    if (scene.inputType != InputType.none &&
        _gameState.currentEpisode == widget.episode.number) {
      _gameState.currentScene = sceneId;
      GroveProgressService.save(_gameState);
      widget.onProgressUpdated(_gameState);
    }

    setState(() {
      _currentScene = scene;
      _currentMsgIdx = 0;
      _showInput = false;
      _isTyping = true;
    });

    _pushNextMessage();
  }

  void _pushNextMessage() {
    if (_currentScene == null || !mounted) return;
    final lines = _currentScene!.lines;

    if (_currentMsgIdx >= lines.length) {
      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
      _handleEndOfScene();
      return;
    }

    final msg = lines[_currentMsgIdx];
    setState(() {
      _addBubble(msg);
      _currentMsgIdx++;
    });
    _scrollToBottom();

    final delay = msg.kind == MessageKind.episodeHeader
        ? 600
        : msg.kind == MessageKind.divider
        ? 200
        : 600 + (msg.text.length * 5); // Simulated read time

    _typeTimer?.cancel();
    _typeTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted) _pushNextMessage();
    });
  }

  void _skipTyping() {
    if (!_isTyping || _currentScene == null) return;
    _typeTimer?.cancel();
    final lines = _currentScene!.lines;
    for (int i = _currentMsgIdx; i < lines.length; i++) {
      _addBubble(lines[i]);
    }
    setState(() {
      _currentMsgIdx = lines.length;
      _isTyping = false;
    });
    _scrollToBottom();
    _handleEndOfScene();
  }

  void _handleEndOfScene() {
    final scene = _currentScene!;
    if (scene.inputType == InputType.none) {
      // It's the end of the episode or a terminal state
      _showEpisodeComplete();
    } else {
      setState(() {
        _showInput = true;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showEpisodeComplete() async {
    // Determine reward if any
    String? pfpAsset;
    String? pfpName;

    if (widget.episode.number == 1) {
      // Episode 1 gives rewards
      final pfpChar = (_gameState.chosenPath == 'apple')
          ? StoryCharacter.newton
          : StoryCharacter.darwin;
      pfpName = (_gameState.chosenPath == 'apple') ? 'Newton' : 'Darwin';

      final pfpKey = (_gameState.chosenPath == 'apple') ? 'newton' : 'darwin';
      final isDark = Theme.of(context).brightness == Brightness.dark;
      pfpAsset = pfpChar.avatarAsset(Theme.of(context).brightness);

      await GroveProgressService.unlockProfilePicture(pfpKey);
      markStoryPfpUnlocked(pfpKey);
      if (pfpKey == 'newton') {
        _gameState.newtonUnlocked = true;
      } else {
        _gameState.darwinUnlocked = true;
      }
    } else if (widget.episode.number == 3) {
      // Episode 3 gives London reward
      pfpName = 'London';
      final pfpKey = 'london';
      final pfpChar = StoryCharacter.london;
      pfpAsset = pfpChar.avatarAsset(Theme.of(context).brightness);

      await GroveProgressService.unlockProfilePicture(pfpKey);
      markStoryPfpUnlocked(pfpKey);
      _gameState.londonUnlocked = true;
    }

    if (_gameState.currentEpisode == widget.episode.number) {
      _gameState.currentEpisode = widget.episode.number + 1;
      _gameState.currentScene =
          ''; // Wipe scene progression tracking for the next run

      // Mandatory 5-hour travel wait between episodes
      _gameState.busyUntil = DateTime.now()
          .add(const Duration(hours: 5))
          .millisecondsSinceEpoch;
      _gameState.episodeComplete = true;

      await GroveProgressService.save(_gameState);
      widget.onProgressUpdated(_gameState);
    }

    if (mounted) {
      EpisodeCompleteSheet.show(
        context: context,
        title: widget.episode.title,
        state: _gameState,
        unlockedPfpAsset: pfpAsset,
        unlockedPfpName: pfpName,
        onReturnToChapters: () {
          Navigator.of(context).pop(); // pop modal
          Navigator.of(context).pop(); // pop chat screen
        },
      );
    }
  }

  // ── INPUT HANDLING ─────────────────────────────────────────────

  void _handleChoice(SceneChoice choice) {
    HapticFeedback.mediumImpact();
    choice.statEffects.forEach((stat, value) {
      switch (stat) {
        case 'stability':
          _gameState.stability += value;
        case 'connectivity':
          _gameState.connectivity += value;
        case 'vitality':
          _gameState.vitality += value;
        case 'transience':
          _gameState.transience += value;
      }
    });
    for (final item in choice.addItems) {
      if (!_gameState.inventory.contains(item)) _gameState.inventory.add(item);
    }
    _gameState.seedWarmth = (_gameState.seedWarmth + choice.warmthChange).clamp(
      0,
      100,
    );
    if (choice.setPath != null) _gameState.chosenPath = choice.setPath;

    // Handle wait duration
    if (choice.waitDuration != null) {
      _gameState.busyUntil = DateTime.now()
          .add(choice.waitDuration!)
          .millisecondsSinceEpoch;
      _gameState.pendingScene = choice.nextScene;
      GroveProgressService.save(_gameState); // SAVE IMMEDIATELY
      widget.onProgressUpdated(_gameState); // NOTIFY PARENT
      _startWaitTimer();
    }

    setState(() {
      _addBubble(
        StoryMessage(
          choice.label,
          character: StoryCharacter.player,
          kind: MessageKind.playerChoice,
        ),
      );
      _showInput = false;
    });

    if (choice.waitDuration == null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _loadScene(choice.nextScene);
      });
    }
  }

  void _handleFreeTextSubmit() {
    final input = _textController.text.trim();
    if (input.isEmpty) return;
    HapticFeedback.mediumImpact();
    final scene = _currentScene;
    if (scene?.onFreeText == null) return;

    setState(() {
      _addBubble(
        StoryMessage(
          input,
          character: StoryCharacter.player,
          kind: MessageKind.playerChoice,
        ),
      );
      _showInput = false;
    });
    _textController.clear();
    _textFocusNode.unfocus();

    final nextScene = scene!.onFreeText!(input, _gameState);
    if (nextScene != null) {
      if (scene.waitDuration != null) {
        _gameState.busyUntil = DateTime.now()
            .add(scene.waitDuration!)
            .millisecondsSinceEpoch;
        _gameState.pendingScene = nextScene;
        GroveProgressService.save(_gameState);
        widget.onProgressUpdated(_gameState);
        _startWaitTimer();
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _loadScene(nextScene);
        });
      }
    }
  }

  void _handleContinue() {
    HapticFeedback.lightImpact();
    setState(() => _showInput = false);
    final next = _currentScene?.nextScene;
    final wait = _currentScene?.waitDuration;

    if (next != null) {
      if (wait != null) {
        _gameState.busyUntil = DateTime.now().add(wait).millisecondsSinceEpoch;
        _gameState.pendingScene = next;
        GroveProgressService.save(_gameState);
        widget.onProgressUpdated(_gameState);
        _startWaitTimer();
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _loadScene(next);
        });
      }
    }
  }

  Widget _buildSkipButton(int hours, int amount) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF1C40F).withOpacity(0.15),
                const Color(0xFFF39C12).withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFF1C40F).withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF1C40F).withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  if (hours == 5)
                    _gameState.skips5h--;
                  else if (hours == 3)
                    _gameState.skips3h--;
                  else if (hours == 1)
                    _gameState.skips1h--;

                  final currentBusy = _gameState.busyUntil ?? 0;
                  final skipMs = Duration(hours: hours).inMilliseconds;
                  _gameState.busyUntil = currentBusy - skipMs;
                  _currentTime = DateTime.now();
                });

                if (_gameState.busyUntil != null &&
                    _currentTime.millisecondsSinceEpoch >=
                        _gameState.busyUntil!) {
                  final next = _gameState.pendingScene;
                  _gameState.busyUntil = null;
                  _gameState.pendingScene = null;
                  if (next != null) {
                    _gameState.currentScene = next;
                    _waitTimer?.cancel();
                    _loadScene(next);
                  }
                }

                GroveProgressService.save(_gameState);
                widget.onProgressUpdated(_gameState);
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1C40F).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fast_forward_rounded,
                        size: 16,
                        color: Color(0xFFF1C40F),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'USE ${hours}HR SKIP TOKEN',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF1C40F),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '$amount remaining in your sack',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF1C40F).withOpacity(0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── INTERNAL HELPERS ─────────────────────────────────────────

  void _addBubble(StoryMessage msg) {
    _bubbles.add(_ChatBubbleData(message: msg));
    final epKey = widget.episode.id;
    _gameState.episodeHistories.putIfAbsent(epKey, () => []);
    _gameState.episodeHistories[epKey]!.add(msg.toJson());
  }

  // ── BUILD ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pc = colors.primary;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final goldColor = isDark
                ? const Color(0xFFF1C40F)
                : const Color(0xFFD4A912);
            final glow = 0.6 + _pulseCtrl.value * 0.4;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: goldColor.withOpacity(0.06),
                border: Border.all(color: goldColor.withOpacity(glow * 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 14,
                    color: goldColor.withOpacity(glow),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_gameState.seedWarmth}%',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: goldColor,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _isTyping ? _skipTyping : null,
              behavior: HitTestBehavior.translucent,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                itemCount: _bubbles.length,
                itemBuilder: (ctx, i) {
                  final bubble = _bubbles[i];
                  final prev = i > 0 ? _bubbles[i - 1] : null;
                  final showAvatar =
                      bubble.message.character != prev?.message.character ||
                      bubble.message.kind != prev?.message.kind ||
                      bubble.message.kind == MessageKind.episodeHeader;

                  return _ChatBubbleWidget(
                    data: bubble,
                    showAvatar: showAvatar,
                    brightness: Theme.of(context).brightness,
                    colors: colors,
                    textTheme: Theme.of(context).textTheme,
                  );
                },
              ),
            ),
          ),
          if (_showInput || _gameState.busyUntil != null)
            _buildInputArea(colors, pc),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colors, Color pc) {
    final scene = _currentScene;

    // Check if we are currently "busy" (timer active)
    final isBusy =
        _gameState.busyUntil != null &&
        _currentTime.millisecondsSinceEpoch < _gameState.busyUntil!;

    if (isBusy) {
      final remaining = Duration(
        milliseconds:
            _gameState.busyUntil! - _currentTime.millisecondsSinceEpoch,
      );
      final totalSeconds = remaining.inSeconds;
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      final seconds = totalSeconds % 60;

      return Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(color: colors.outline.withOpacity(0.07)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: pc.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'TRAVELING...',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: pc.withOpacity(0.6),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: colors.onSurface,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.onSurface.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                TravelNarrative.getQuote(_gameState.chosenPath, remaining),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ),
            if (_gameState.skips5h > 0) _buildSkipButton(5, _gameState.skips5h),
            if (_gameState.skips3h > 0) _buildSkipButton(3, _gameState.skips3h),
            if (_gameState.skips1h > 0) _buildSkipButton(1, _gameState.skips1h),
            if (widget.isBetaTester) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: colors.error.withOpacity(0.05),
                  border: Border.all(
                    color: colors.error.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _gameState.busyUntil =
                            DateTime.now().millisecondsSinceEpoch;
                        _currentTime = DateTime.now();
                      });

                      // Immediately check if we finished the wait
                      if (_gameState.busyUntil != null &&
                          _currentTime.millisecondsSinceEpoch >=
                              _gameState.busyUntil!) {
                        final next = _gameState.pendingScene;
                        _gameState.busyUntil = null;
                        _gameState.pendingScene = null;
                        if (next != null) {
                          _gameState.currentScene = next;
                          _waitTimer?.cancel();
                          _loadScene(next);
                        }
                      }

                      GroveProgressService.save(_gameState);
                      widget.onProgressUpdated(_gameState);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bug_report_rounded,
                            size: 16,
                            color: colors.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'SKIP WAIT (BETA TESTER)',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: colors.error,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (scene == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outline.withOpacity(0.07)),
        ),
      ),
      child: switch (scene.inputType) {
        InputType.continueOnly => _buildContinueBtn(pc, colors),
        InputType.choices => _buildChoiceList(scene, pc, colors),
        InputType.freeText || InputType.number => _buildTextInput(pc, colors),
        InputType.none => const SizedBox.shrink(),
      },
    );
  }

  // Updated Continue Button Style
  Widget _buildContinueBtn(Color pc, ColorScheme colors) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _handleContinue,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: BorderSide(color: pc.withOpacity(0.3)),
          backgroundColor: pc.withOpacity(0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CONTINUE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: pc,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Opacity(
                opacity: 0.5 + _pulseCtrl.value * 0.5,
                child: Icon(Icons.arrow_forward_rounded, size: 16, color: pc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Polished Choice List Style
  Widget _buildChoiceList(Scene scene, Color pc, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: scene.choices.map((ch) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: colors.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () => _handleChoice(ch),
              highlightColor: pc.withOpacity(0.1),
              splashColor: pc.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: pc.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ch.letter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'JetBrains Mono',
                          color: pc,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        ch.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface.withOpacity(0.85),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Refined Text Input Style
  Widget _buildTextInput(Color pc, ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
              cursorColor: pc,
              decoration: InputDecoration(
                hintText: 'Type your answer...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.3),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (_) => _handleFreeTextSubmit(),
              textInputAction: TextInputAction.send,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8, top: 8),
            child: GestureDetector(
              onTap: _handleFreeTextSubmit,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: pc, shape: BoxShape.circle),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHAT BUBBLE WIDGET
// ─────────────────────────────────────────────────────────────

class _ChatBubbleData {
  final StoryMessage message;
  _ChatBubbleData({required this.message});
}

class _ChatBubbleWidget extends StatefulWidget {
  final _ChatBubbleData data;
  final bool showAvatar;
  final Brightness brightness;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _ChatBubbleWidget({
    required this.data,
    required this.showAvatar,
    required this.brightness,
    required this.colors,
    required this.textTheme,
  });

  @override
  State<_ChatBubbleWidget> createState() => _ChatBubbleWidgetState();
}

class _ChatBubbleWidgetState extends State<_ChatBubbleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.data.message;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: () {
            // If the character is the player, always use the player bubble style
            if (msg.character == StoryCharacter.player) {
              return _playerBubble(msg);
            }

            return switch (msg.kind) {
              MessageKind.episodeHeader => _episodeHeader(msg),
              MessageKind.playerChoice => _playerBubble(msg),
              MessageKind.dialogue => _characterBubble(msg),
              MessageKind.narrative => _narrativeBubble(msg),
              MessageKind.system => _systemBubble(msg),
              MessageKind.divider => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: widget.colors.onSurface.withOpacity(0.07),
                  thickness: 1,
                ),
              ),
            };
          }(),
        ),
      ),
    );
  }

  Widget _episodeHeader(StoryMessage msg) {
    final isItalicHeader = msg.text.startsWith('EPISODE COMPLETE');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: widget.colors.primary.withOpacity(
              isItalicHeader ? 0.04 : 0.08,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.colors.primary.withOpacity(
                isItalicHeader ? 0.08 : 0.15,
              ),
            ),
          ),
          child: Text(
            msg.text,
            style: widget.textTheme.labelSmall?.copyWith(
              color: widget.colors.primary.withOpacity(
                isItalicHeader ? 0.7 : 1.0,
              ),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _playerBubble(StoryMessage msg) {
    final pc = widget.colors.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: pc,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              msg.text,
              style: widget.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _characterBubble(StoryMessage msg) {
    final accent = msg.character.accent(widget.brightness);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: widget.showAvatar && msg.character.hasAvatar
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    msg.character.avatarAsset(widget.brightness),
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                )
              : null,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showAvatar) ...[
                Text(
                  msg.character.displayName,
                  style: widget.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.07),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(widget.showAvatar ? 4 : 16),
                    topRight: const Radius.circular(16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: const Radius.circular(16),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: widget.textTheme.bodySmall?.copyWith(
                    color: widget.colors.onSurface.withOpacity(0.88),
                    height: 1.5,
                    fontSize: 13,
                    fontStyle: msg.isItalic ? FontStyle.italic : null,
                    fontWeight: msg.isBold ? FontWeight.w700 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrativeBubble(StoryMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 2, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showAvatar) ...[
            Text(
              msg.character.displayName.toUpperCase(),
              style: widget.textTheme.labelSmall?.copyWith(
                color: msg.character.accent(widget.brightness).withOpacity(0.5),
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            msg.text,
            style: widget.textTheme.bodySmall?.copyWith(
              color: widget.colors.onSurface.withOpacity(0.65),
              height: 1.6,
              fontSize: 13,
              fontStyle: msg.isItalic ? FontStyle.italic : null,
              fontWeight: msg.isBold ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemBubble(StoryMessage msg) {
    final sysColor = msg.character == StoryCharacter.system
        ? StoryCharacter.system.accent(widget.brightness)
        : widget.colors.primary;

    // Detect if this is a stat change or inventory update
    final isStat = msg.text.contains(RegExp(r'STA|CON|VIT|TRA|STABILITY|CONNECTIVITY|VITALITY|TRANSIENCE'));
    final isInventory = msg.text.contains('[') && msg.text.contains('obtained]');

    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: sysColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sysColor.withOpacity(0.12)),
          boxShadow: isStat || isInventory ? [
            BoxShadow(
              color: sysColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isStat) ...[
              Icon(Icons.auto_graph_rounded, size: 14, color: sysColor.withOpacity(0.7)),
              const SizedBox(width: 8),
            ] else if (isInventory) ...[
              Icon(Icons.backpack_rounded, size: 14, color: sysColor.withOpacity(0.7)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                msg.text,
                style: widget.textTheme.bodySmall?.copyWith(
                  fontFamily: 'JetBrains Mono',
                  color: sysColor.withOpacity(0.8),
                  height: 1.55,
                  fontSize: 11,
                  fontStyle: msg.isItalic ? FontStyle.italic : null,
                  fontWeight: (isStat || isInventory || msg.isBold) ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
