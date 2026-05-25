import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/counselor/services/polly_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/features/counselor/services/counselor_service.dart';
import 'package:gr0ve/features/counselor/services/persona_voice.dart';
import 'package:gr0ve/models/counselor.dart';
import 'package:gr0ve/services/settings/accessibility_service.dart';

class CounselorVoiceRoute<T> extends PageRouteBuilder<T> {
  CounselorVoiceRoute({
    required CounselorPersona persona,
    required UserProfile profile,
    required List<ChatMessage> history,
    required void Function(List<ChatMessage> updated) onHistoryUpdated,
  }) : super(
         pageBuilder: (context, _, __) => CounselorVoiceScreen(
           persona: persona,
           profile: profile,
           history: history,
           onHistoryUpdated: onHistoryUpdated,
         ),
         transitionsBuilder: (context, animation, _, child) =>
             _VoiceScreenTransition(animation: animation, child: child),
         transitionDuration: const Duration(milliseconds: 380),
         reverseTransitionDuration: const Duration(milliseconds: 260),
       );
}

class _VoiceScreenTransition extends StatelessWidget {
  const _VoiceScreenTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

class _VoiceThemeManager {
  static _VoiceTheme forPersona(CounselorPersona persona, bool isLight) {
    return isLight ? _VoiceTheme.light() : _VoiceTheme.dark();
  }
}

@immutable
class _VoiceTheme {
  final Color bg;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final Color waveformInactive;

  const _VoiceTheme({
    required this.bg,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.waveformInactive,
  });

  factory _VoiceTheme.light() => _VoiceTheme(
    bg: const Color(0xFFFAFAFA),
    textPrimary: const Color(0xFF1F1F1F),
    textSecondary: const Color(0xFF666666),
    cardBg: Colors.black.withOpacity(0.04),
    cardBorder: Colors.black.withOpacity(0.08),
    waveformInactive: Colors.black.withOpacity(0.12),
  );

  factory _VoiceTheme.dark() => _VoiceTheme(
    bg: const Color(0xFF060D0C),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    cardBg: Colors.white.withOpacity(0.06),
    cardBorder: Colors.white.withOpacity(0.10),
    waveformInactive: Colors.white.withOpacity(0.12),
  );
}

enum _VoicePhase { greeting, idle, listening, thinking, speaking }

extension _VoicePhaseExt on _VoicePhase {
  bool get isActive =>
      this == _VoicePhase.speaking || this == _VoicePhase.listening;

  bool get isAnimated => isActive || this == _VoicePhase.thinking;
}

class CounselorVoiceScreen extends StatefulWidget {
  const CounselorVoiceScreen({
    super.key,
    required this.persona,
    required this.profile,
    required this.history,
    required this.onHistoryUpdated,
  });

  final CounselorPersona persona;
  final UserProfile profile;
  final List<ChatMessage> history;
  final void Function(List<ChatMessage> updated) onHistoryUpdated;

  @override
  State<CounselorVoiceScreen> createState() => _CounselorVoiceScreenState();
}

class _CounselorVoiceScreenState extends State<CounselorVoiceScreen>
    with TickerProviderStateMixin {
  late SpeechToText _stt;
  late List<ChatMessage> _messages;

  _VoicePhase _phase = _VoicePhase.greeting;
  String _transcript = '';
  String _lastResponse = '';
  bool _isProcessing = false;

  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  static const int _barCount = 28;
  final List<double> _barHeights = List.filled(_barCount, 4.0);

  bool _sttListening = false;
  Timer? _silenceTimer;
  String _accumulatedTranscript = '';
  DateTime? _lastSpeechDetected;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.history);
    _stt = SpeechToText();
    _setupAnimations();
    _initializeServices();
  }

  void _setupAnimations() {
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..addListener(_updateWaveform);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
  }

  Future<void> _initializeServices() async {
    final sttOk = await _stt.initialize();
    final pollyOk = await PollyService.initialize();

    if (!mounted) return;
    if (!pollyOk || !sttOk) {
      _showError('Failed to initialize voice services');
      return;
    }

    if (AccessibilityService.autoVoiceGreeting.value) {
      _playGreeting();
    } else {
      _setPhase(_VoicePhase.idle);
      Future.delayed(const Duration(milliseconds: 300), _startListening);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _entryCtrl.dispose();
    _scrollCtrl.dispose();
    _silenceTimer?.cancel();
    _stt.stop();
    PollyService.stop();
    super.dispose();
  }

  Future<void> _playGreeting() async {
    final name = widget.profile.greetingName;
    final greeting = widget.persona.welcomeGreeting(name);
    final intro = '$greeting ${widget.persona.welcomeSubtitle}';

    if (mounted) setState(() => _lastResponse = intro);
    _setPhase(_VoicePhase.greeting);

    await PollyService.speak(
      text: intro,
      persona: widget.persona,
      isGreeting: true,
      onReady: () => _setPhase(_VoicePhase.greeting),
      onDone: () {
        if (mounted) {
          _setPhase(_VoicePhase.idle);
          Future.delayed(const Duration(milliseconds: 300), _startListening);
        }
      },
    );
  }

  Future<void> _startListening() async {
    if (_phase == _VoicePhase.thinking || _phase == _VoicePhase.speaking) {
      return;
    }

    if (_sttListening) return;

    _sttListening = true;
    _accumulatedTranscript = '';
    _lastSpeechDetected = DateTime.now();

    _setPhase(_VoicePhase.listening);

    try {
      await _stt.listen(
        onResult: _handleSttResult,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        cancelOnError: true,
        partialResults: true,
      );

      _monitorSilence();
    } catch (e) {
      debugPrint('[Voice] STT error: $e');
      _sttListening = false;
    }
  }

  void _handleSttResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();

    if (words.isNotEmpty && words != _accumulatedTranscript) {
      _lastSpeechDetected = DateTime.now();
      _accumulatedTranscript = words;
    }

    if (mounted) {
      setState(() => _transcript = _accumulatedTranscript);
      _scrollToBottom();
    }
  }

  void _monitorSilence() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!_sttListening || _lastSpeechDetected == null) {
        _silenceTimer?.cancel();
        return;
      }

      final timeSinceLastSpeech = DateTime.now()
          .difference(_lastSpeechDetected!)
          .inMilliseconds;

      if (timeSinceLastSpeech > 1250 && _accumulatedTranscript.isNotEmpty) {
        _completeSpeech();
      }
    });
  }

  Future<void> _completeSpeech() async {
    _silenceTimer?.cancel();
    _sttListening = false;
    final finalText = _accumulatedTranscript.trim();

    if (finalText.isEmpty) {
      if (mounted) {
        _setPhase(_VoicePhase.idle);
        Future.delayed(const Duration(milliseconds: 500), _startListening);
      }
      return;
    }

    await _handleUserInput(finalText);
  }

  Future<void> _handleUserInput(String userText) async {
    if (_isProcessing) return;

    _isProcessing = true;
    _setPhase(_VoicePhase.thinking);

    debugPrint('[Voice] Stopping STT before response fetch...');
    await _stt.stop();
    _sttListening = false;
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      await _fetchAndPlayResponse(userText);
    } finally {
      _isProcessing = false;
    }
  }

  bool _isClosingMessage(String userMessage) {
    final lower = userMessage.toLowerCase().trim();

    final closingKeywords = [
      'bye',
      'goodbye',
      'see ya',
      'talk to you later',
      'ttyl',
      'catch ya',
      'gotta go',
      'see you',
      'bye bye',
      'that\'s all',
      'that is all',
      'we\'re done',
      'i\'m done',
      'i am done',
      'i\'m good',
      'i am good',
      'that\'s it',
      'nothing else',
    ];

    for (final keyword in closingKeywords) {
      if (lower.contains(keyword)) {
        debugPrint('[Voice] Matched closing keyword: "$keyword"');
        return true;
      }
    }

    return false;
  }

  Future<void> _fetchAndPlayResponse(String userText) async {
    _messages.add(
      ChatMessage(text: userText, isUser: true, timestamp: DateTime.now()),
    );

    final userSaidClosing = _isClosingMessage(userText);
    debugPrint('[Voice] User said: "$userText"');
    debugPrint('[Voice] Is closing? $userSaidClosing');

    try {
      final closureState = await OllamaCounselorService.sendMessage(
        history: _messages,
        question: userText,
        persona: widget.persona,
        profile: widget.profile,
        onToken: (_) {},
        isVoiceMode: true,
      );

      if (!mounted) return;

      var responseText = closureState.displayMessage;
      if (responseText.isNotEmpty) {
        final preview = responseText.length > 50
            ? responseText.substring(0, 50)
            : responseText;
        debugPrint('[Voice] Got response: "$preview"');
      }

      if (responseText.isEmpty) {
        debugPrint('[Voice] Response was empty');
        _setPhase(_VoicePhase.idle);
        return;
      }

      _messages.add(
        ChatMessage(
          text: responseText,
          isUser: false,
          speaker: widget.persona,
          timestamp: DateTime.now(),
        ),
      );

      await ChatHistoryService.save(widget.persona, _messages);
      widget.onHistoryUpdated(_messages);

      if (mounted) {
        setState(() {
          _lastResponse = responseText;
          _transcript = '';
        });
        _scrollToBottom();
      }

      final shouldClose = userSaidClosing || closureState.shouldCloseScreen;
      await _playResponse(responseText, shouldClose);
    } catch (e, st) {
      debugPrint('[Voice] Error fetching response: $e');
      debugPrint('[Voice] Stack trace: $st');
      if (mounted) {
        _showError('Failed to get response: $e');
        _setPhase(_VoicePhase.idle);
      }
    }
  }

  Future<void> _playResponse(String text, bool shouldClose) async {
    _setPhase(_VoicePhase.speaking);

    try {
      final preview = text.length > 50 ? text.substring(0, 50) : text;
      debugPrint(
        '[Voice] _playResponse: shouldClose=$shouldClose, text="$preview..."',
      );

      await PollyService.speak(
        text: text,
        persona: widget.persona,
        onReady: () {
          debugPrint('[Voice] Audio started playing');
          _setPhase(_VoicePhase.speaking);
        },
        onDone: () {
          debugPrint(
            '[Voice] Audio finished playing, shouldClose=$shouldClose',
          );
          if (mounted) {
            if (shouldClose) {
              debugPrint('[Voice] ✓ User said goodbye, closing screen');
              Navigator.pop(context);
            } else {
              debugPrint(
                '[Voice] User did not say goodbye, resuming listening',
              );
              _setPhase(_VoicePhase.idle);
              Future.delayed(
                const Duration(milliseconds: 300),
                _startListening,
              );
            }
          }
        },
      );
    } catch (e, st) {
      debugPrint('[Voice] Error in _playResponse: $e');
      debugPrint('[Voice] Stack: $st');
      if (mounted) {
        _showError('Playback error: $e');
        _setPhase(_VoicePhase.idle);
      }
    }
  }

  void _setPhase(_VoicePhase p) {
    if (!mounted) return;
    setState(() => _phase = p);

    if (p.isAnimated) {
      _pulseCtrl.repeat(reverse: true);
      _waveCtrl.repeat();
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
      _waveCtrl.stop();
    }
  }

  void _updateWaveform() {
    if (!mounted) return;
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final isActive = _phase.isActive;
    final isThinking = _phase == _VoicePhase.thinking;

    setState(() {
      for (int i = 0; i < _barCount; i++) {
        final center = _barCount / 2;
        final dist = (i - center).abs() / center;

        if (isActive) {
          final speed = _phase == _VoicePhase.speaking ? 0.38 : 0.65;
          final raw = (sin(t * speed * pi * 2 + i * 0.7)).abs() * 38 + 4;
          _barHeights[i] = raw * (1 - dist * 0.45);
        } else if (isThinking) {
          final raw = (sin(t * 0.4 + i * 0.2)).abs() * 6 + 4;
          _barHeights[i] = raw * (1 - dist * 0.45);
        } else {
          _barHeights[i] = 4.0;
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  String _statusText() => switch (_phase) {
    _VoicePhase.greeting => '${widget.persona.displayName} is saying hi…',
    _VoicePhase.idle => 'Go ahead, I\'m listening',
    _VoicePhase.listening => 'I hear you…',
    _VoicePhase.thinking => 'Just a sec…',
    _VoicePhase.speaking => '${widget.persona.displayName} is talking',
  };

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLight = brightness == Brightness.light;
    final theme = _VoiceThemeManager.forPersona(widget.persona, isLight);
    final pc = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Column(
              children: [
                _buildTopBar(theme, pc),

                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 32),
                        ScaleTransition(
                          scale: _pulseScale,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: pc.withOpacity(isLight ? 0.08 : 0.10),
                              border: Border.all(
                                color: pc.withOpacity(
                                  _phase.isActive ? 0.6 : 0.25,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: pc.withOpacity(
                                    _phase == _VoicePhase.speaking
                                        ? 0.30
                                        : 0.07,
                                  ),
                                  blurRadius: _phase == _VoicePhase.speaking
                                      ? 44
                                      : 14,
                                  spreadRadius: _phase == _VoicePhase.speaking
                                      ? 6
                                      : 0,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(27),
                              child: Image.asset(
                                widget.persona.avatarAsset(brightness),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          widget.persona.displayName,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.persona.welcomeTagline,
                          style: TextStyle(
                            color: pc.withOpacity(isLight ? 0.5 : 0.65),
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _buildWaveform(pc, theme),
                        const SizedBox(height: 20),
                        Text(
                          _statusText(),
                          style: TextStyle(
                            color: theme.textSecondary.withOpacity(0.55),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),

                        if (_transcript.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: _buildTranscriptBox(theme),
                          ),
                        ],

                        if (_lastResponse.isNotEmpty &&
                            _phase != _VoicePhase.listening) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: _buildResponseBox(pc, theme, isLight),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(_VoiceTheme theme, Color pc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              PollyService.stop();
              _stt.stop();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: theme.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Back',
                    style: TextStyle(color: theme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform(Color pc, _VoiceTheme theme) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _barCount,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 3,
            height: _barHeights[i].clamp(3.0, 46.0),
            margin: const EdgeInsets.symmetric(horizontal: 1.6),
            decoration: BoxDecoration(
              color: _phase.isAnimated
                  ? pc.withOpacity(
                      0.3 +
                          0.7 *
                              (1 - (_barCount / 2 - i).abs() / (_barCount / 2)),
                    )
                  : theme.waveformInactive,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptBox(_VoiceTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.cardBorder),
      ),

      child: Text(
        '"$_transcript"',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.textSecondary,
          fontSize: 13,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildResponseBox(Color pc, _VoiceTheme theme, bool isLight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: pc.withOpacity(isLight ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pc.withOpacity(isLight ? 0.12 : 0.15)),
      ),
      child: Text(
        _lastResponse,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.textSecondary.withOpacity(0.85),
          fontSize: 13,
          height: 1.6,
        ),
      ),
    );
  }
}
