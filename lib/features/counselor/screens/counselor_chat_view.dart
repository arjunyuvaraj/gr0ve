import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gr0ve/features/counselor/services/persona_voice.dart';
import 'package:gr0ve/models/counselor.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'dart:io' as io; // Guarded usage

// ─────────────────────────────────────────────────────────────
// MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.showSpeakerLabel,
    required this.colors,
    required this.textTheme,
    required this.fallbackPersona,
    required this.brightness,
    this.onDoubleTap, // ← lifted up to CounselorScreen
  });

  final ChatMessage message;
  final bool showSpeakerLabel;
  final ColorScheme colors;
  final TextTheme textTheme;
  final CounselorPersona fallbackPersona;
  final Brightness brightness;
  final VoidCallback? onDoubleTap;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
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
    final msg = widget.message;
    final persona = msg.speaker ?? widget.fallbackPersona;
    final pc = widget.colors.primary;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onDoubleTap: widget.onDoubleTap, // ← just fires the callback
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: msg.isUser
                ? _userBubble(context, msg, pc)
                : _aiBubble(context, msg, persona, pc),
          ),
        ),
      ),
    );
  }

  Widget _userBubble(BuildContext context, ChatMessage msg, Color pc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: pc,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (msg.imagePath != null) ...[
                  _buildImage(msg.imagePath!, pc),
                  const SizedBox(height: 8),
                ],
                Text(
                  msg.text,
                  style: widget.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String path, Color pc) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.5,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: kIsWeb
            ? Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                ),
              )
            : Image.file(
                io.File(path),
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _aiBubble(
    BuildContext context,
    ChatMessage msg,
    CounselorPersona persona,
    Color pc,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: widget.showSpeakerLabel
              ? SizedBox(
                  width: 28,
                  height: 28,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      persona.avatarAsset(widget.brightness),
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : null,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showSpeakerLabel) ...[
                Text(
                  persona.displayName,
                  style: widget.textTheme.labelSmall?.copyWith(
                    color: pc,
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
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: pc.withOpacity(0.07),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(widget.showSpeakerLabel ? 4 : 14),
                    topRight: const Radius.circular(16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.imagePath != null) ...[
                      _buildImage(msg.imagePath!, pc),
                      const SizedBox(height: 8),
                    ],
                    msg.isLoading || msg.text.isEmpty
                        ? MiniTypingIndicator(color: pc)
                        : MarkdownBody(
                            data: msg.text,
                            styleSheet: MarkdownStyleSheet(
                              p: widget.textTheme.bodySmall?.copyWith(
                                color: widget.colors.onSurface.withOpacity(0.88),
                                height: 1.5,
                                fontSize: 13,
                              ),
                              strong: widget.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: widget.colors.onSurface,
                                fontSize: 13,
                              ),
                              listBullet: widget.textTheme.bodySmall?.copyWith(
                                color: pc,
                                fontSize: 13,
                              ),
                              blockSpacing: 10,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHIME PROMPT BUBBLE
// ─────────────────────────────────────────────────────────────

class ChimePromptBubble extends StatefulWidget {
  const ChimePromptBubble({
    super.key,
    required this.persona,
    required this.prevSpeakerName,
    required this.brightness,
    required this.colors,
    required this.textTheme,
    required this.onYes,
    required this.onNo,
  });

  final CounselorPersona persona;
  final String prevSpeakerName;
  final Brightness brightness;
  final ColorScheme colors;
  final TextTheme textTheme;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  State<ChimePromptBubble> createState() => _ChimePromptBubbleState();
}

class _ChimePromptBubbleState extends State<ChimePromptBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
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
    final accent = widget.colors.primary;
    final invite = widget.persona.chimeInvite(
      widget.prevSpeakerName.isNotEmpty ? widget.prevSpeakerName : 'them',
    );

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      widget.persona.avatarAsset(widget.brightness),
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.06),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: accent.withOpacity(0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.persona.displayName,
                        style: widget.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invite,
                        style: widget.textTheme.bodySmall?.copyWith(
                          color: widget.colors.onSurface.withOpacity(0.7),
                          fontSize: 13,
                          height: 1.45,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _ChimeBtn(
                            label: 'Hear it',
                            accent: accent,
                            filled: true,
                            onTap: widget.onYes,
                            textTheme: widget.textTheme,
                          ),
                          const SizedBox(width: 8),
                          _ChimeBtn(
                            label: 'Skip',
                            accent: accent,
                            filled: false,
                            onTap: widget.onNo,
                            textTheme: widget.textTheme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChimeBtn extends StatelessWidget {
  const _ChimeBtn({
    required this.label,
    required this.accent,
    required this.filled,
    required this.onTap,
    required this.textTheme,
  });

  final String label;
  final Color accent;
  final bool filled;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: filled ? accent : accent.withOpacity(0.35)),
        ),
        child: Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: filled ? Colors.white : accent,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MINI TYPING INDICATOR
// ─────────────────────────────────────────────────────────────

class MiniTypingIndicator extends StatefulWidget {
  const MiniTypingIndicator({super.key, required this.color});
  final Color color;

  @override
  State<MiniTypingIndicator> createState() => _MiniTypingIndicatorState();
}

class _MiniTypingIndicatorState extends State<MiniTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * (0.5 - (phase - 0.5).abs()) * 2;
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 6 * scale,
              height: 6 * scale,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATE SEPARATOR
// ─────────────────────────────────────────────────────────────

class DateSeparator extends StatelessWidget {
  const DateSeparator({
    super.key,
    required this.date,
    required this.colors,
    required this.textTheme,
  });

  final DateTime date;
  final ColorScheme colors;
  final TextTheme textTheme;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${_month(date.month)} ${date.day}';
  }

  String _month(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: colors.onSurface.withOpacity(0.07),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withOpacity(0.3),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: colors.onSurface.withOpacity(0.07),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
