// counselor_welcome_view.dart
//
// REFACTOR NOTES:
// - The "other counselors" avatar row has been removed from the welcome screen.
//   Switching counselors is now a hidden action (long-press on header chip).
// - The `others` and `onSwitchPersona` props have been dropped.
// - Everything else (greeting, subtitle, academy chip, random button) is unchanged.

import 'package:flutter/material.dart';
import 'package:gr0ve/features/counselor/services/counselor_service.dart';
import 'package:gr0ve/features/counselor/services/persona_voice.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({
    super.key,
    required this.persona,
    required this.brightness,
    required this.colors,
    required this.textTheme,
    required this.pc,
    required this.greeting,
    required this.profile,
    required this.randomBtnScale,
    required this.onSendRandom,
    required this.onOpenVoiceMode,
    // REMOVED: others, onSwitchPersona
  });

  final CounselorPersona persona;
  final Brightness brightness;
  final ColorScheme colors;
  final TextTheme textTheme;
  final Color pc;
  final String greeting;
  final UserProfile profile;
  final Animation<double> randomBtnScale;
  final VoidCallback onSendRandom;
  final VoidCallback onOpenVoiceMode;
  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pc = widget.pc;
    final colors = widget.colors;
    final textTheme = widget.textTheme;
    final brightness = widget.brightness;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Avatar
              SizedBox(
                width: 96,
                height: 96,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pc.withOpacity(0.08),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      widget.persona.avatarAsset(brightness),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Greeting
              Text(
                widget.greeting,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.persona.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.5),
                  height: 1.5,
                ),
              ),

              // Academy chip
              if (widget.profile.academy.isNotEmpty ||
                  widget.profile.grade.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pc.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    [
                      if (widget.profile.academy.isNotEmpty)
                        widget.profile.academy,
                      if (widget.profile.grade.isNotEmpty)
                        'Grade ${widget.profile.grade}',
                    ].join(' · '),
                    style: textTheme.labelSmall?.copyWith(
                      color: pc,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Random question button
              ScaleTransition(
                scale: widget.randomBtnScale,
                child: GestureDetector(
                  onTap: widget.onSendRandom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: pc,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedShuffle,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ask a random question',
                          style: textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: widget.onOpenVoiceMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: pc.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: pc.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded, color: pc, size: 15),
                      const SizedBox(width: 8),
                      Text(
                        'Prefer to talk? Open Voice Mode',
                        style: textTheme.labelMedium?.copyWith(
                          color: pc.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'Always confirm with your real counselor.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.3),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
