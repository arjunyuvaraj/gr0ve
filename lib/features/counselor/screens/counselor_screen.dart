import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/counselor/screens/counselor_chat_view.dart';
import 'package:gr0ve/features/counselor/screens/counselor_persona_picker.dart';
import 'package:gr0ve/features/counselor/screens/counselor_voice_screen.dart';
import 'package:gr0ve/features/counselor/screens/counselor_welcome_view.dart';
import 'package:gr0ve/features/counselor/screens/voice_test.dart';
import 'package:gr0ve/features/counselor/services/counselor_service.dart';
import 'package:gr0ve/features/counselor/services/persona_voice.dart';
import 'package:gr0ve/legal/legal.dart';
import 'package:gr0ve/models/counselor.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/features/easter_eggs/abies_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  bool _isHomeworkHelp = false;
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

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
    setState(() => _isInitializing = true);

    final hasAcceptedTerms = await TermsOfServiceService.hasAcceptedTerms();

    if (!hasAcceptedTerms) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _termsAccepted = false;
        });
      }
      return;
    }

    setState(() => _termsAccepted = true);

    final results = await Future.wait([
      CounselorPersonaService.load(),
      _loadUserProfile(),
    ]);
    final persona = results[0] as CounselorPersona;
    final profile = results[1] as UserProfile;
    final history = await ChatHistoryService.load(
      persona,
      isHomework: _isHomeworkHelp,
    );
    KnowledgeBaseService.load();
    CourseCatalogService.buildPromptString(academy: profile.academy);

    if (!mounted) return;
    setState(() {
      _persona = persona;
      _profile = profile;
      _messages = history;
      _hasStarted = history.isNotEmpty;
      _isInitializing = false;
    });
    if (history.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<UserProfile> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return UserProfile.empty;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      return UserProfile(
        name: user.displayName ?? '',
        academy: data?['academy'] as String? ?? '',
        grade: data?['grade']?.toString() ?? '',
      );
    } catch (_) {
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
        imagePath: current.imagePath,
      );
    });
    _scrollToBottom();
  }

  void _removeMsg(String id) =>
      setState(() => _messages.removeWhere((m) => m.id == id));

  // ══════════════════════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if ((trimmed.isEmpty && _selectedImagePath == null) || _isTyping) return;

    _controller.clear();
    final imagePath = _selectedImagePath;
    final isHomeworkHelp = _isHomeworkHelp;

    setState(() {
      _hasStarted = true;
      _isTyping = true;
      _messages.add(
        ChatMessage(
          text: trimmed,
          isUser: true,
          timestamp: DateTime.now(),
          imagePath: imagePath,
        ),
      );
      _selectedImagePath = null;
    });
    _scrollToBottom();

    final bubbleId = _addStreamingBubble(_persona);

    try {
      if (_persona == CounselorPersona.abies &&
          !CounselorPersonaService.abiesUnlocked) {
        await Future.delayed(const Duration(milliseconds: 1200));
        final line = abiesVoiceLine(unlocked: false);
        _appendToken(bubbleId, line);
      } else {
        final closureState = await OllamaCounselorService.sendMessage(
          history: _messages.where((m) => !m.isLoading).toList(),
          question: trimmed.isEmpty ? "What's in this photo?" : trimmed,
          persona: _persona,
          profile: _profile,
          onToken: (token) => _appendToken(bubbleId, token),
          isHomeworkHelp: isHomeworkHelp,
          imagePath: imagePath,
        );

        if (closureState.shouldCloseScreen && mounted) {
          print('[CounselorScreen] Closing window due to conversation end');
          await Future.delayed(const Duration(milliseconds: 2500));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      }

      ChatHistoryService.save(_persona, _messages, isHomework: isHomeworkHelp);
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
        if (!_isHomeworkHelp) {
          _isHomeworkHelp = true;
          _initialize();
        }
      });
    }
  }

  Future<void> _toggleHomeworkHelp() async {
    setState(() {
      _isHomeworkHelp = !_isHomeworkHelp;
      _selectedImagePath = null;
    });
    await _initialize();
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
    final pc = CounselorPersona.abies.primary(brightness);

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
    await ChatHistoryService.clear(_persona, isHomework: _isHomeworkHelp);
    setState(() {
      _messages.clear();
      _hasStarted = false;
    });
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
    final pc = _persona.primary(brightness);

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
                'Please visit your Account page to agree to the Terms of Service before using the counselor.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.7),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(colors, textTheme, brightness, pc),
        Expanded(
          child: _hasStarted
              ? _buildChatView(colors, textTheme, brightness)
              : _buildWelcomeView(colors, textTheme, brightness),
        ),
        _buildInputBar(colors, textTheme, pc),
      ],
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
          GestureDetector(
            onTap: _toggleHomeworkHelp,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.outline.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modePill(
                    active: !_isHomeworkHelp,
                    icon: HugeIcons.strokeRoundedChatBot,
                    label: 'Counselor',
                    activeColor: pc,
                    colors: colors,
                  ),
                  _modePill(
                    active: _isHomeworkHelp,
                    icon: HugeIcons.strokeRoundedBook02,
                    label: 'Homework',
                    activeColor: colors.primary,
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_hasStarted)
            GestureDetector(
              onTap: () => _confirmClear(colors, Theme.of(context).textTheme),
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
      pc: _persona.primary(brightness),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.outline.withOpacity(0.07)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedImagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.primary.withOpacity(0.3),
                        ),
                        image: DecorationImage(
                          image: FileImage(File(_selectedImagePath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImagePath = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 2),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isHomeworkHelp)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _isHomeworkHelp
                            ? colors.primary.withOpacity(0.2)
                            : colors.outline.withOpacity(0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 5,
                      minLines: 1,
                      style: textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: _isHomeworkHelp
                            ? 'Analyze homework/notes...'
                            : 'Ask ${_persona.displayName}...',
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
                if (!_isHomeworkHelp)
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
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MODE PILL
  // ──────────────────────────────────────────────────────────────────────────

  Widget _modePill({
    required bool active,
    required List<List<dynamic>> icon,
    required String label,
    required Color activeColor,
    required ColorScheme colors,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: active
            ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: icon,
            size: 14,
            color: active ? Colors.white : colors.onSurface.withOpacity(0.3),
          ),
          if (active) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
