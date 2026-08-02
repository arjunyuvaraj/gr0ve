import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/core/widgets/images/remote_asset_image.dart';
import 'package:gr0ve/features/account/services/profile_picture_service.dart';

import 'package:gr0ve/features/grove/grove_progress_service.dart';
import 'package:gr0ve/features/grove/models/grove_models.dart';
import 'package:gr0ve/features/grove/screens/episode_complete_sheet.dart';
import 'package:gr0ve/core/services/network_time_service.dart';

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
  List<Scene>? _scenes;
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
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initEpisode();
  }

  Future<void> _initEpisode() async {
    final scenes = await widget.episode.buildScenes();
    if (!mounted) return;

    setState(() {
      _scenes = scenes;
    });

    String startSceneId = _scenes!.first.id;

    final pastCompleted = _gameState.currentEpisode > widget.episode.number;

    if (_gameState.currentEpisode == widget.episode.number &&
        _gameState.currentScene.isNotEmpty) {
      if (_scenes!.any((s) => s.id == _gameState.currentScene)) {
        startSceneId = _gameState.currentScene;
      }
    } else if (!pastCompleted) {
      _gameState.currentEpisode = widget.episode.number;
      _gameState.currentScene = startSceneId;
      _gameState.episodeComplete = false;
      _gameState.episodeHistories[widget.episode.id] = [];

      _gameState.episodeStartStates.putIfAbsent(
        widget.episode.id,
        () => _gameState.toNestedJson(),
      );
      GroveProgressService.save(_gameState);
    }

    final epKey = widget.episode.id;

    if (_gameState.episodeHistories[epKey]?.isNotEmpty ?? false) {
      setState(() {
        _bubbles.addAll(
          _gameState.episodeHistories[epKey]!.map(
            (json) => _ChatBubbleData(message: StoryMessage.fromJson(json)),
          ),
        );
      });

      if (pastCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
          setState(() {
            _showInput = false;
            _isTyping = false;
          });
        });
        return;
      }

      final completedScene = _scenes!
          .where((s) => s.id == _gameState.currentScene)
          .firstOrNull;
      if (_gameState.currentEpisode == widget.episode.number &&
          _gameState.episodeComplete &&
          completedScene?.inputType == InputType.none) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
          _showEpisodeComplete();
        });
        return;
      }
    } else if (pastCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEpisodeComplete();
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pulseCtrl.repeat(reverse: true);

      if (_gameState.busyUntil != null) {
        _startWaitTimer();
      }

      if (_bubbles.isEmpty && !pastCompleted) {
        _loadScene(startSceneId);
      } else {
        setState(() {
          _currentScene = _scenes!
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
        _currentTime = NetworkTimeService.now;
      });
    }
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = NetworkTimeService.now;
        });

        if (_gameState.busyUntil != null &&
            NetworkTimeService.now.millisecondsSinceEpoch >=
                _gameState.busyUntil!) {
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
    final scene = _scenes?.where((s) => s.id == sceneId).firstOrNull;
    if (scene == null) {
      debugPrint('[Grove] Scene not found: $sceneId');
      return;
    }

    final oldStats = {
      'STABILITY': _gameState.stability,
      'CONNECTIVITY': _gameState.connectivity,
      'VITALITY': _gameState.vitality,
      'TRANSIENCE': _gameState.transience,
      'WARMTH': _gameState.seedWarmth,
    };
    final oldInventory = List<String>.from(_gameState.inventory);

    scene.onEnter?.call(_gameState);

    if (oldStats['STABILITY'] != _gameState.stability) {
      _addStatBubble(
        'STABILITY',
        _gameState.stability - oldStats['STABILITY']!,
      );
    }
    if (oldStats['CONNECTIVITY'] != _gameState.connectivity) {
      _addStatBubble(
        'CONNECTIVITY',
        _gameState.connectivity - oldStats['CONNECTIVITY']!,
      );
    }
    if (oldStats['VITALITY'] != _gameState.vitality) {
      _addStatBubble('VITALITY', _gameState.vitality - oldStats['VITALITY']!);
    }
    if (oldStats['TRANSIENCE'] != _gameState.transience) {
      _addStatBubble(
        'TRANSIENCE',
        _gameState.transience - oldStats['TRANSIENCE']!,
      );
    }
    if (oldStats['WARMTH'] != _gameState.seedWarmth) {
      final delta = _gameState.seedWarmth - oldStats['WARMTH']!;
      _addBubble(
        StoryMessage(
          'Seed Warmth: ${delta > 0 ? '+' : ''}$delta%',
          character: StoryCharacter.system,
          kind: MessageKind.system,
        ),
      );
    }
    for (final item in _gameState.inventory) {
      if (!oldInventory.contains(item)) {
        _addBubble(
          StoryMessage(
            'Inventory: [$item obtained]',
            character: StoryCharacter.system,
            kind: MessageKind.system,
          ),
        );
      }
    }

    if (_gameState.currentEpisode == widget.episode.number) {
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
        : 600 + (msg.text.length * 5);

    _typeTimer?.cancel();

    if (_currentMsgIdx >= lines.length &&
        _currentScene?.inputType == InputType.none) {
      _typeTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted) _pushNextMessage();
      });
      return;
    }

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
    final brightness = Theme.of(context).brightness;
    final mode = brightness == Brightness.dark ? 'dark' : 'light';
    String? pfpAsset;
    String? pfpName;

    if (_gameState.currentEpisode == 1) {
      if (_gameState.chosenPath == 'apple') {
        _gameState.newtonUnlocked = true;
        _gameState.darwinUnlocked = false;
        pfpAsset = 'assets/story/characters/ep1/newton_$mode.png';
        pfpName = 'Newton';
        GroveProgressService.unlockProfilePicture('newton');
        GroveProgressService.lockProfilePicture('darwin');
        markStoryPfpUnlocked('newton');
        lockStoryPfp('darwin');
      } else {
        _gameState.darwinUnlocked = true;
        _gameState.newtonUnlocked = false;
        pfpAsset = 'assets/story/characters/ep1/darwin_$mode.png';
        pfpName = 'Darwin';
        GroveProgressService.unlockProfilePicture('darwin');
        GroveProgressService.lockProfilePicture('newton');
        markStoryPfpUnlocked('darwin');
        lockStoryPfp('newton');
      }
    } else if (_gameState.currentEpisode == 2) {
      _gameState.salixUnlocked = true;
      pfpAsset = 'assets/story/characters/ep2/salix_$mode.png';
      pfpName = 'Salix';
      GroveProgressService.unlockProfilePicture('salix');
      markStoryPfpUnlocked('salix');
    } else if (_gameState.currentEpisode == 3) {
      _gameState.londonUnlocked = true;
      pfpAsset = 'assets/story/characters/ep3/london_$mode.png';
      pfpName = 'London';
      GroveProgressService.unlockProfilePicture('london');
      markStoryPfpUnlocked('london');
    }

    if (_gameState.currentEpisode == widget.episode.number) {
      _gameState.currentEpisode = widget.episode.number + 1;
      _gameState.currentScene = '';

      _gameState.busyUntil = DateTime.now()
          .add(const Duration(hours: 5))
          .millisecondsSinceEpoch;
      _gameState.episodeComplete = true;

      _gameState.seedWarmth = (_gameState.seedWarmth - 10).clamp(0, 100);

      GroveProgressService.save(_gameState);
      widget.onProgressUpdated(_gameState);
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        EpisodeCompleteSheet.show(
          context: context,
          title: widget.episode.title,
          state: _gameState,
          unlockedPfpAsset: pfpAsset,
          unlockedPfpName: pfpName,
          onReturnToChapters: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        );
      });
    }
  }

  void _handleChoice(SceneChoice choice) {
    HapticFeedback.mediumImpact();

    _addBubble(
      StoryMessage(
        choice.label,
        character: StoryCharacter.player,
        kind: MessageKind.playerChoice,
      ),
    );
    _showInput = false;

    if (choice.statEffects.isNotEmpty) {
      choice.statEffects.forEach((stat, value) {
        if (value == 0) return;
        switch (stat) {
          case 'stability':
            _gameState.stability += value;
            _addStatBubble('STABILITY', value);
          case 'connectivity':
            _gameState.connectivity += value;
            _addStatBubble('CONNECTIVITY', value);
          case 'vitality':
            _gameState.vitality += value;
            _addStatBubble('VITALITY', value);
          case 'transience':
            _gameState.transience += value;
            _addStatBubble('TRANSIENCE', value);
        }
      });
    }
    for (final item in choice.addItems) {
      final isVessel = item.toLowerCase().contains('pot');
      final alreadyHasVessel =
          isVessel &&
          _gameState.inventory.any(
            (held) => held.toLowerCase().contains('pot'),
          );
      if (alreadyHasVessel) {
        _addBubble(
          StoryMessage(
            'Inventory: [No room for another vessel]',
            character: StoryCharacter.system,
            kind: MessageKind.system,
          ),
        );
        continue;
      }

      if (!_gameState.inventory.contains(item)) {
        _gameState.inventory.add(item);
        _addBubble(
          StoryMessage(
            'Inventory: [$item obtained]',
            character: StoryCharacter.system,
            kind: MessageKind.system,
          ),
        );
      }
    }
    if (choice.warmthChange != 0) {
      _gameState.seedWarmth = (_gameState.seedWarmth + choice.warmthChange)
          .clamp(0, 100);
      _addBubble(
        StoryMessage(
          'Seed Warmth: ${choice.warmthChange > 0 ? '+' : ''}${choice.warmthChange}%',
          character: StoryCharacter.system,
          kind: MessageKind.system,
        ),
      );
    }
    if (choice.setPath != null) _gameState.chosenPath = choice.setPath;

    GroveProgressService.save(_gameState);

    if (choice.waitDuration != null) {
      _gameState.busyUntil = DateTime.now()
          .add(choice.waitDuration!)
          .millisecondsSinceEpoch;
      _gameState.pendingScene = choice.nextScene;
      GroveProgressService.save(_gameState);
      widget.onProgressUpdated(_gameState);
      _startWaitTimer();
    }

    setState(() {});

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

  void _addBubble(StoryMessage msg) {
    _bubbles.add(_ChatBubbleData(message: msg));
    final epKey = widget.episode.id;
    _gameState.episodeHistories.putIfAbsent(epKey, () => []);
    _gameState.episodeHistories[epKey]!.add(msg.toJson());
  }

  void _addStatBubble(String stat, int delta) {
    if (delta == 0) return;
    final sign = delta > 0 ? '+' : '';
    _addBubble(
      StoryMessage(
        '$stat $sign$delta',
        character: StoryCharacter.system,
        kind: MessageKind.system,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pc = colors.primary;

    if (_scenes == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(child: CircularProgressIndicator(color: pc)),
      );
    }

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
        actions: [
          if (widget.isBetaTester)
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: _skipTyping,
              tooltip: 'Skip Dialogue',
            ),
        ],
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
            if (_gameState.skips5h > 0) ...[
              const SizedBox(height: 12),
              _buildSkipButton(5, _gameState.skips5h),
            ],
            if (_gameState.skips3h > 0) ...[
              const SizedBox(height: 12),
              _buildSkipButton(3, _gameState.skips3h),
            ],
            if (_gameState.skips1h > 0) ...[
              const SizedBox(height: 12),
              _buildSkipButton(1, _gameState.skips1h),
            ],
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
                  child: RemoteAssetImage(
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

    final isStat = msg.text.contains(
      RegExp(r'STA|CON|VIT|TRA|STABILITY|CONNECTIVITY|VITALITY|TRANSIENCE'),
    );
    final isWarmth = msg.text.contains('Warmth');
    final isInventory =
        msg.text.contains('[') && msg.text.contains('obtained]');

    Color displayColor = sysColor;
    IconData icon = Icons.info_outline_rounded;

    if (isStat) {
      final isUp = msg.text.contains('+');
      displayColor = isUp ? const Color(0xFF00B894) : const Color(0xFFD63031);
      icon = Icons.auto_graph_rounded;
    } else if (isWarmth) {
      displayColor = const Color(0xFFF1C40F);
      icon = Icons.local_fire_department_rounded;
    } else if (isInventory) {
      displayColor = const Color(0xFFE58E26);
      icon = Icons.backpack_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: displayColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: displayColor.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: displayColor.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: displayColor.withOpacity(0.8)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                msg.text,
                style: widget.textTheme.bodySmall?.copyWith(
                  fontFamily: 'JetBrains Mono',
                  color: displayColor.withOpacity(0.9),
                  height: 1.0,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
