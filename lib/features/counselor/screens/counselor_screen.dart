import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/counselor/screens/counselor_chat_view.dart';
import 'package:gr0ve/features/counselor/screens/counselor_persona_picker.dart';
import 'package:gr0ve/features/counselor/screens/counselor_voice_screen.dart';
import 'package:gr0ve/features/counselor/screens/counselor_welcome_view.dart';
import 'package:gr0ve/features/counselor/services/counselor_service.dart';
import 'package:gr0ve/features/counselor/services/persona_voice.dart';
import 'package:gr0ve/legal/legal.dart';
import 'package:gr0ve/models/counselor.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gr0ve/configuration/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/features/easter_eggs/abies_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:gr0ve/core/widgets/misc/email_verification_gate.dart';
import 'package:gr0ve/services/settings/fun_mode_service.dart';

class CounselorScreen extends StatefulWidget {
  const CounselorScreen({super.key});

  @override
  State<CounselorScreen> createState() => _CounselorScreenState();
}

class _CounselorScreenState extends State<CounselorScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _hasStarted = false;
  bool _isInitializing = true;
  bool _termsAccepted = false;

  CounselorPersona _persona = CounselorPersona.grover;
  UserProfile _profile = UserProfile.empty;

  late AnimationController _randomBtnCtrl;
  late Animation<double> _randomBtnScale;

  // ══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _randomBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _randomBtnScale = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _randomBtnCtrl, curve: Curves.easeOut));
    FirebaseAnalytics.instance.logEvent(name: 'screen_counselor');
    _initialize();
  }

  Future<void> _initialize() async {
    // Ensure Firebase is initialized even after a hot reload
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 2));
    } catch (e) {
      if (kDebugMode) print('[CounselorScreen] Firebase init error (ignored if already init): $e');
    }
    if (!mounted) return;
    setState(() => _isInitializing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isInitializing = false);
        return;
      }

      // Check ToS first
      final hasAcceptedTerms = await TermsOfServiceService.hasAcceptedTerms()
          .timeout(const Duration(seconds: 5), onTimeout: () => true);

      if (!hasAcceptedTerms) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _termsAccepted = false;
          });
        }
        return;
      }

      if (mounted) setState(() => _termsAccepted = true);

      // Parallel load essential data with fail-safes
      final results = await Future.wait([
        CounselorPersonaService.load().timeout(const Duration(seconds: 5)),
        _loadUserProfile().timeout(const Duration(seconds: 5)),
      ]).timeout(const Duration(seconds: 8));

      final persona = results[0] as CounselorPersona;
      final profile = results[1] as UserProfile;

      // History load
      final history = await ChatHistoryService.load(
        persona,
      ).timeout(const Duration(seconds: 5), onTimeout: () => []);

      // Non-blocking background loads
      KnowledgeBaseService.load();
      CourseCatalogService.buildPromptString(academy: profile.academy);

      if (mounted) {
        setState(() {
          _persona = persona;
          _profile = profile;
          _messages = history;
          _hasStarted = history.isNotEmpty;
          _isInitializing = false;
        });

        if (history.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
      }
    } catch (e) {
      debugPrint('[CounselorScreen] Initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasStarted = false;
          // Set defaults to avoid null crashes in build
          _persona = CounselorPersona.grover;
          _profile = UserProfile.empty;
          _messages = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connection slow. Some features might be limited."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<UserProfile> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return UserProfile.empty;
    try {
      // Use cache to avoid redundant gRPC calls and potential hangs
      final Map<String, dynamic>? data = await UserDocCache.get();
      return UserProfile(
        name: user.displayName ?? '',
        academy: data?['academy'] as String? ?? '',
        grade: data?['grade']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('[CounselorScreen] Profile load error: $e');
      return UserProfile(name: user.displayName ?? '', academy: '', grade: '');
    }
  }

  @override
  void dispose() {
    _randomBtnCtrl.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCROLL
  // ══════════════════════════════════════════════════════════════════════════

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MESSAGE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  String _addStreamingBubble(CounselorPersona speaker) {
    final msg = ChatMessage(
      text: '',
      isUser: false,
      speaker: speaker,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    setState(() => _messages.add(msg));
    _scrollToBottom();
    return msg.id;
  }

  void _appendToken(String id, String token) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx < 0 || !mounted) return;
    final current = _messages[idx];
    setState(() {
      _messages[idx] = ChatMessage(
        id: current.id,
        text: current.text + token,
        isUser: false,
        speaker: current.speaker,
        timestamp: current.timestamp,
        isLoading: false,
      );
    });
    _scrollToBottom();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _controller.clear();

    setState(() {
      _hasStarted = true;
      _isTyping = true;
      _messages.add(
        ChatMessage(text: trimmed, isUser: true, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();

    final bubbleId = _addStreamingBubble(_persona);

    try {
      if (_persona.isHidden &&
          !CounselorPersonaService.isPersonaUnlocked(_persona)) {
        await Future.delayed(const Duration(milliseconds: 600));
        final line = _persona.lockedVoiceLine(unlocked: false);
        _appendToken(bubbleId, line);
      } else {
        final closureState = await OllamaCounselorService.sendMessage(
          history: _messages.where((m) => !m.isLoading).toList(),
          question: trimmed,
          persona: _persona,
          profile: _profile,
          onToken: (token) => _appendToken(bubbleId, token),
        );

        // Strip [[CLOSE]] marker from the displayed message
        if (closureState.shouldCloseScreen && mounted) {
          final idx = _messages.indexWhere((m) => m.id == bubbleId);
          if (idx >= 0) {
            final current = _messages[idx];
            setState(() {
              _messages[idx] = ChatMessage(
                id: current.id,
                text: closureState.displayMessage,
                isUser: false,
                speaker: current.speaker,
                timestamp: current.timestamp,
                isLoading: false,
              );
            });
          }

          print('[CounselorScreen] Closing window due to conversation end');
          await Future.delayed(const Duration(milliseconds: 2500));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      }

      ChatHistoryService.save(_persona, _messages);
    } catch (e) {
      _appendToken(bubbleId, 'Could not reach the counselor service.');
      print('[CounselorScreen] Error: $e');
    }

    setState(() => _isTyping = false);
  }

  void _sendRandom() async {
    await _randomBtnCtrl.forward();
    await _randomBtnCtrl.reverse();
    _send(randomQuestion(_persona));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PERSONA SWITCHING
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _switchToPersona(CounselorPersona persona) async {
    await CounselorPersonaService.setPersona(persona);
    final history = await ChatHistoryService.load(persona);
    if (!mounted) return;
    setState(() {
      _persona = persona;
      _messages = history;
      _hasStarted = history.isNotEmpty;
    });
    if (history.isNotEmpty) _scrollToBottom();
  }

  void _showPersonaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PersonaPickerSheet(
        currentPersona: _persona,
        isChange: true,
        onSelect: _switchToPersona,
        onOpenFrozenLake: _openFrozenLake,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EASTER EGGS
  // ══════════════════════════════════════════════════════════════════════════

  void _onBubbleDoubleTap() => _openFrozenLake();

  void _openFrozenLake() {
    if (!FunModeService.isFunMode.value) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, _) => FrozenLakeScreen(
          onUnlocked: () {
            CounselorPersonaService.markAbiesUnlocked();
            if (Navigator.canPop(ctx)) Navigator.pop(ctx);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _offerSwitchToAbies();
            });
          },
        ),
        transitionsBuilder: (ctx, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _offerSwitchToAbies() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final pc = colors.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: pc.withOpacity(0.15)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                CounselorPersona.abies.avatarAsset(brightness),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Abies is available.',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "He has been waiting.\nLonger than you might think.",
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withOpacity(0.4),
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: colors.outline.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Later',
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _switchToPersona(CounselorPersona.abies);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pc,
                      foregroundColor: CounselorPersona.abies.onPrimary(
                        brightness,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Speak with Abies',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CLEAR HISTORY
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _clearHistory() async {
    if (_isTyping)
      return; // Guard against clearing while a message is in flight

    setState(() {
      _messages.clear();
      _hasStarted = false;
    });

    try {
      await ChatHistoryService.clear(_persona);
    } catch (e) {
      print('[CounselorScreen] Error clearing history: $e');
    }
  }

  void _confirmClear(ColorScheme colors, TextTheme textTheme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text(
          'This will delete your conversation history with this counselor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearHistory();
            },
            child: Text('Clear', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pc = colors.primary;

    if (_isInitializing) {
      return Center(child: CircularProgressIndicator(color: pc));
    }

    if (!_termsAccepted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 40,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to gr0ve',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please accept the Terms of Service to use the counselor.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.7),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => TermsOfServiceModal(
                      isBlockingCounselorAccess: true,
                      onAccepted: () {
                        if (mounted) _initialize();
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'View Terms of Service',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: EmailVerificationGate(
        description:
            "Please verify your email address to talk with the counselor.",
        child: Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: MediaQuery.of(context).viewInsets.bottom > 100
                  ? const SizedBox(width: double.infinity, height: 0)
                  : TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildHeader(colors, textTheme, brightness, pc),
                    ),
            ),
            Expanded(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 15 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _hasStarted
                    ? _buildChatView(colors, textTheme, brightness)
                    : _buildWelcomeView(colors, textTheme, brightness),
              ),
            ),
            _buildInputBar(colors, textTheme, pc),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HEADER
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    ColorScheme colors,
    TextTheme textTheme,
    Brightness brightness,
    Color pc,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: _showPersonaPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pc.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pc.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        _persona.avatarAsset(brightness),
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _persona.displayName,
                    style: textTheme.labelSmall?.copyWith(
                      color: pc,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (_hasStarted)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isTyping ? null : () => _confirmClear(colors, textTheme),
              child: Opacity(
                opacity: _isTyping ? 0.3 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 18,
                    color: colors.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // WELCOME VIEW
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildWelcomeView(
    ColorScheme colors,
    TextTheme textTheme,
    Brightness brightness,
  ) {
    return WelcomeView(
      persona: _persona,
      brightness: brightness,
      colors: colors,
      textTheme: textTheme,
      pc: colors.primary,
      greeting: _persona.welcomeGreeting(_profile.greetingName),
      profile: _profile,
      randomBtnScale: _randomBtnScale,
      onSendRandom: _sendRandom,
      onOpenVoiceMode: _openVoiceMode,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CHAT VIEW
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildChatView(
    ColorScheme colors,
    TextTheme textTheme,
    Brightness brightness,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) {
        final msg = _messages[i];
        if (msg.isChimePrompt) return const SizedBox.shrink();

        final showDateSep =
            i == 0 || !_isSameDay(_messages[i - 1].timestamp, msg.timestamp);
        final prev = i > 0 ? _messages[i - 1] : null;
        final showLabel =
            !msg.isUser &&
            msg.speaker != null &&
            (prev == null || prev.isUser || prev.speaker != msg.speaker);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateSep && !msg.isLoading)
              DateSeparator(
                date: msg.timestamp,
                colors: colors,
                textTheme: textTheme,
              ),
            MessageBubble(
              message: msg,
              showSpeakerLabel: showLabel,
              colors: colors,
              textTheme: textTheme,
              fallbackPersona: _persona,
              brightness: brightness,
              onDoubleTap: _onBubbleDoubleTap,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ──────────────────────────────────────────────────────────────────────────
  // VOICE MODE
  // ──────────────────────────────────────────────────────────────────────────

  void _openVoiceMode() {
    Navigator.of(context).push(
      CounselorVoiceRoute(
        persona: _persona,
        profile: _profile,
        history: _messages,
        onHistoryUpdated: (updated) {
          if (mounted) {
            setState(() {
              _messages = updated;
              _hasStarted = updated.isNotEmpty;
            });
            ChatHistoryService.save(_persona, updated);
            _scrollToBottom();
          }
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INPUT BAR
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildInputBar(ColorScheme colors, TextTheme textTheme, Color pc) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final bottomPadding = viewInsets.bottom > 0
        ? 12.0
        : (isWide ? 20.0 : MediaQuery.of(context).padding.bottom + 8.0);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.outline.withOpacity(0.07)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: colors.outline.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: viewInsets.bottom > 100 ? 3 : 5,
                    minLines: 1,
                    style: textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Ask ${_persona.displayName}...',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: _isTyping ? null : _send,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openVoiceMode,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: pc.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: pc.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.mic_rounded, color: pc, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isTyping ? null : () => _send(_controller.text),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isTyping ? pc.withOpacity(0.35) : pc,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _isTyping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : HugeIcon(
                            icon: HugeIcons.strokeRoundedSent,
                            size: 20,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
