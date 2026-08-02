import 'package:flutter/material.dart';
import 'package:gr0ve/core/widgets/images/remote_asset_image.dart';
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

    if (!_dawnUnlocked && !isBeforeAnniversary) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showDawnRequirementDialog(context);
      });
      return _buildLockedScreen(colors, isDark);
    }

    return ChapterSelectionScreen(isBetaTester: widget.isBetaTester);
  }

  void _showDawnRequirementDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dawnColor = const Color(0xFFF1C40F);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colors.outline.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: dawnColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(
                      3,
                      (i) => Container(
                        width: 100.0 + (i * 40.0),
                        height: 100.0 + (i * 40.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: dawnColor.withOpacity(0.1 - (i * 0.03)),
                          ),
                        ),
                      ),
                    ),

                    RemoteAssetImage(
                      isDark
                          ? 'assets/story/characters/ep0/dawn_dark.png'
                          : 'assets/story/characters/ep0/dawn_light.png',
                      width: 110,
                      height: 110,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                child: Column(
                  children: [
                    Text(
                      'DAWN REQUIRED',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The Gr0ve is a path forged in silence and rest. To begin this journey, you must first find the one who carries the light.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.outline.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: dawnColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hint: Check in when the world rests (weekends or holidays).',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurface.withOpacity(0.5),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'UNDERSTOOD',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    child: RemoteAssetImage(
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
                  const SizedBox(height: 32),
                  IconButton(
                    onPressed: () => _showDawnRequirementDialog(context),
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: colors.onSurface.withOpacity(0.1),
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
