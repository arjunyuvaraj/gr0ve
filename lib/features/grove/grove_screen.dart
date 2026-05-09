import 'package:flutter/material.dart';
import 'package:gr0ve/features/account/services/dawn_unlock_service.dart';
import 'package:gr0ve/features/grove/screens/chapter_selection_screen.dart';

class GroveScreen extends StatefulWidget {
  final bool isBetaTester;
  const GroveScreen({super.key, this.isBetaTester = false});

  @override
  State<GroveScreen> createState() => _GroveScreenState();
}

class _GroveScreenState extends State<GroveScreen>
    with TickerProviderStateMixin {
  bool _dawnUnlocked = false;
  bool _isLoading = true;

  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkDawnAndLoad();
  }

  Future<void> _checkDawnAndLoad() async {
    _dawnUnlocked = DawnUnlockService.isUnlocked.value;
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeCtrl.forward();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: colors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final targetDate = DateTime(2026, 5, 20, 8, 0, 0);
    final isBeforeAnniversary = DateTime.now().isBefore(targetDate);

    // If it's before the anniversary, or Dawn is unlocked, show the chapter screen
    // (The ChapterSelectionScreen handles the actual full-screen countdown overlay)
    if (!_dawnUnlocked && !isBeforeAnniversary) {
      return _buildLockedScreen(colors, isDark);
    }

    return ChapterSelectionScreen(isBetaTester: widget.isBetaTester);
  }

  Widget _buildLockedScreen(ColorScheme colors, bool isDark) {
    final dawnColor = const Color(0xFFF1C40F);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) => Opacity(
                      opacity: 0.4 + _pulseCtrl.value * 0.3,
                      child: child,
                    ),
                    child: Image.asset(
                      isDark
                          ? 'assets/story/characters/ep0/dawn_dark.png'
                          : 'assets/story/characters/ep0/dawn_light.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'the gr0ve',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: dawnColor.withOpacity(0.6),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'the grove remembers\nthose who rest.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      color: colors.onSurface.withOpacity(0.35),
                      letterSpacing: 0.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'find dawn to begin.',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      color: colors.onSurface.withOpacity(0.2),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
