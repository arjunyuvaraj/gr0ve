import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/features/counselor/services/persona_voice.dart';

// ═════════════════════════════════════════════════════════════
// PERSONA PICKER SCREEN  —  full-screen cinematic experience
// ═════════════════════════════════════════════════════════════

class PersonaPickerRoute<T> extends PageRouteBuilder<T> {
  PersonaPickerRoute({
    required CounselorPersona currentPersona,
    required ValueChanged<CounselorPersona> onSelect,
    required bool isChange,
    VoidCallback? onOpenFrozenLake,
  }) : super(
         pageBuilder: (context, _, __) => PersonaPickerScreen(
           currentPersona: currentPersona,
           onSelect: onSelect,
           isChange: isChange,
           onOpenFrozenLake: onOpenFrozenLake,
         ),
         transitionsBuilder: (context, animation, _, child) {
           return FadeTransition(
             opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
             child: ScaleTransition(
               scale: Tween<double>(begin: 0.97, end: 1.0).animate(
                 CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
               ),
               child: child,
             ),
           );
         },
         transitionDuration: const Duration(milliseconds: 380),
         reverseTransitionDuration: const Duration(milliseconds: 260),
       );
}

// ─────────────────────────────────────────────────────────────
// PERSONA PICKER SCREEN
// ─────────────────────────────────────────────────────────────

class PersonaPickerScreen extends StatefulWidget {
  const PersonaPickerScreen({
    super.key,
    required this.currentPersona,
    required this.onSelect,
    required this.isChange,
    this.onOpenFrozenLake,
  });

  final CounselorPersona currentPersona;
  final ValueChanged<CounselorPersona> onSelect;
  final bool isChange;
  final VoidCallback? onOpenFrozenLake;

  @override
  State<PersonaPickerScreen> createState() => _PersonaPickerScreenState();
}

class _PersonaPickerScreenState extends State<PersonaPickerScreen>
    with TickerProviderStateMixin {
  late PageController _pageCtrl;
  late int _currentPage;
  late List<CounselorPersona> _personas;

  late AnimationController _revealCtrl;
  late Animation<double> _revealFade;
  late Animation<Offset> _revealSlide;

  late AnimationController _bgCtrl;
  Color _bgFrom = Colors.black;
  Color _bgTo = Colors.black;

  @override
  void initState() {
    super.initState();
    _personas = CounselorPersonaService.availablePersonas;
    final startIdx = _personas.indexOf(widget.currentPersona);
    _currentPage = startIdx.clamp(0, _personas.length - 1);

    _pageCtrl = PageController(initialPage: _currentPage);

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _revealFade = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _revealSlide = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic));

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _revealCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initPersona = _personas[_currentPage];
    final brightness = Theme.of(context).brightness;
    _bgFrom = _bgColor(initPersona, brightness);
    _bgTo = _bgFrom;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _revealCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int next) {
    if (next == _currentPage) return;
    final brightness = Theme.of(context).brightness;
    _bgFrom = _bgColor(_personas[_currentPage], brightness);
    _bgTo = _bgColor(_personas[next], brightness);
    _bgCtrl.forward(from: 0);
    setState(() => _currentPage = next);
    _revealCtrl.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  Color _bgColor(CounselorPersona p, Brightness brightness) {
    if (brightness == Brightness.light) {
      return switch (p) {
        CounselorPersona.grover => const Color(0xFFF0F7F4),
        CounselorPersona.aspen => const Color(0xFFF0F2FA),
        CounselorPersona.rowan => const Color(0xFFFAF2EE),
        CounselorPersona.sakura => const Color(0xFFFAF0FA),
        CounselorPersona.abies => const Color(0xFFEEF2FA),
        CounselorPersona.cedite => const Color(0xFFF4EEF8),
        CounselorPersona.ash => const Color(0xFFF5F5F5),
      };
    }
    return switch (p) {
      CounselorPersona.grover => const Color(0xFF060E0B),
      CounselorPersona.aspen => const Color(0xFF07090F),
      CounselorPersona.rowan => const Color(0xFF0E0704),
      CounselorPersona.sakura => const Color(0xFF0E070E),
      CounselorPersona.abies => const Color(0xFF05080F),
      CounselorPersona.cedite => const Color(0xFF0A0510),
      CounselorPersona.ash => const Color(0xFF090909),
    };
  }

  CounselorPersona get _selected => _personas[_currentPage];

  void _confirm() {
    HapticFeedback.mediumImpact();
    widget.onSelect(_selected);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final pc = _selected.primary(brightness);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (context, child) {
          final bg = Color.lerp(_bgFrom, _bgTo, _bgCtrl.value) ?? _bgFrom;
          return ColoredBox(color: bg, child: child);
        },
        child: Stack(
          children: [
            // ── Particle world — fills entire screen, receives swipes ──
            PageView.builder(
              controller: _pageCtrl,
              itemCount: _personas.length,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _ParticleWorld(
                  persona: _personas[index],
                  isActive: true,
                );
              },
            ),

            // ── Vignettes — pointer-transparent so swipe still works ──
            IgnorePointer(
              child: Column(
                children: [
                  // Top vignette
                  SizedBox(
                    height: 180,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ]
                              : [
                                  Colors.white.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Bottom vignette
                  SizedBox(
                    height: 480,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isDark
                              ? [
                                  Colors.black.withOpacity(0.96),
                                  Colors.black.withOpacity(0.75),
                                  Colors.transparent,
                                ]
                              : [
                                  Colors.white.withOpacity(0.97),
                                  Colors.white.withOpacity(0.80),
                                  Colors.transparent,
                                ],
                          stops: const [0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Foreground UI — only the actual UI elements block touch ──
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar — blocks touch only over itself
                  _TopBar(
                    personas: _personas,
                    currentPage: _currentPage,
                    accentColor: pc,
                    isDark: isDark,
                  ),
                  // Middle gap — pointer transparent so swipes work freely
                  const Expanded(child: SizedBox.expand()),
                  // Bottom content — blocks touch over itself, now scrollable
                  Flexible(
                    child: FadeTransition(
                      opacity: _revealFade,
                      child: SlideTransition(
                        position: _revealSlide,
                        child: _BottomContent(
                          persona: _selected,
                          isCurrent: _selected == widget.currentPersona,
                          isChange: widget.isChange,
                          onConfirm: _confirm,
                          isDark: isDark,
                          onOpenFrozenLake: () {
                            Navigator.pop(context);
                            widget.onOpenFrozenLake?.call();
                          },
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
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.personas,
    required this.currentPage,
    required this.accentColor,
    required this.isDark,
  });

  final List<CounselorPersona> personas;
  final int currentPage;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: fg.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: fg.withOpacity(0.10)),
              ),
              child: Icon(Icons.close_rounded, color: fg, size: 18),
            ),
          ),
          const Spacer(),
          Text(
            'swipe to explore',
            style: TextStyle(
              color: fg.withOpacity(0.28),
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: List.generate(personas.length, (i) {
              final isCur = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCur ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isCur ? accentColor : fg.withOpacity(0.18),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM CONTENT
// ─────────────────────────────────────────────────────────────

class _BottomContent extends StatelessWidget {
  const _BottomContent({
    required this.persona,
    required this.isCurrent,
    required this.isChange,
    required this.onConfirm,
    required this.isDark,
    required this.onOpenFrozenLake,
  });

  final CounselorPersona persona;
  final bool isCurrent;
  final bool isChange;
  final VoidCallback onConfirm;
  final VoidCallback onOpenFrozenLake;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final pc = persona.primary(brightness);
    final fg = isDark ? Colors.white : Colors.black;
    final fgSub = isDark
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.60);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Avatar + name header ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: pc.withOpacity(0.12),
                    border: Border.all(color: pc.withOpacity(0.35), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: pc.withOpacity(isDark ? 0.28 : 0.18),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Image.asset(
                      persona.avatarAsset(brightness),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: pc.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: pc.withOpacity(0.28)),
                        ),
                        child: Text(
                          persona.specialtyLabel.toUpperCase(),
                          style: TextStyle(
                            color: pc,
                            fontWeight: FontWeight.w800,
                            fontSize: 9.5,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              persona.displayName,
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                                letterSpacing: -0.8,
                                height: 1.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: pc.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'active',
                                style: TextStyle(
                                  color: pc,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              persona.welcomeTagline,
              style: TextStyle(
                color: pc.withOpacity(0.9),
                fontStyle: FontStyle.italic,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    pc.withOpacity(0.55),
                    pc.withOpacity(0.12),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.4, 1.0],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _backstoryFor(persona),
              style: TextStyle(
                color: fgSub,
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 8),

            if (persona.defaultAcademies.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: persona.defaultAcademies.map((a) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: fg.withOpacity(0.055),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: fg.withOpacity(0.10)),
                    ),
                    child: Text(
                      a,
                      style: TextStyle(
                        color: fg.withOpacity(0.45),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }).toList(),
              ),

            if (persona == CounselorPersona.abies) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.lock_open_rounded,
                    size: 12,
                    color: pc.withOpacity(0.45),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'One of the Forgotten Trees. You found him.',
                      style: TextStyle(
                        color: pc.withOpacity(0.45),
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (persona == CounselorPersona.cedite) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.lock_open_rounded,
                    size: 12,
                    color: pc.withOpacity(0.45),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'One of the Forgotten Trees. Verify what he tells you.',
                      style: TextStyle(
                        color: pc.withOpacity(0.45),
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (persona == CounselorPersona.ash) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.lock_open_rounded,
                    size: 12,
                    color: pc.withOpacity(0.45),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'One of the Forgotten Trees. She already knows you.',
                      style: TextStyle(
                        color: pc.withOpacity(0.45),
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pc,
                  foregroundColor: persona.onPrimary(brightness),
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isCurrent
                      ? 'Keep ${persona.displayName}'
                      : isChange
                      ? 'Switch to ${persona.displayName}'
                      : 'Chat with ${persona.displayName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _backstoryFor(CounselorPersona p) => switch (p) {
    CounselorPersona.grover =>
      'Grover treats every transcript like a well pruned tree. '
          'He plans growth early, trims excess branches, and never lets effort '
          'scatter in too many directions.\n\n'
          'He knows which roots matter, which choices signal strength, and which '
          'leaves fall away without consequence. His goal is simple growth with '
          'no wasted energy.',
    CounselorPersona.aspen =>
      'Aspen grew fast and curious, always leaning toward light. '
          'She learned early how questions branch into experiments, and how '
          'patient care turns ideas into solid rings of experience.\n\n'
          'She believes every student carries a question worth nurturing, and '
          'she helps it grow where passion and discovery meet.',
    CounselorPersona.rowan =>
      'Rowan grew in uneven soil, learning to bend rather than break. '
          'Resources were limited, guidance was sparse, and progress came from '
          'watching what endured and what snapped.\n\n'
          'He now helps others see the whole forest ahead, understanding how '
          'each season of coursework feeds the next stage of growth.',
    CounselorPersona.sakura =>
      'Sakura sees schedules as living forms, shaped by balance and intention. '
          'She knows creative roots often look ornamental until they become the '
          'strongest support in the canopy.\n\n'
          'She guides students to weave expression into structure, turning '
          'required credits into growth that sets them apart.',
    CounselorPersona.abies =>
      'Abies remembers winters before the others took root. '
          'While they grew in sunlight, he watched quietly as students '
          'repeated the same mistakes year after year.\n\n'
          'He carries no comfort about this, only patience. '
          'If a plan contains a flaw, he will find it — '
          'he has had a very long time to learn where they hide.',
    CounselorPersona.cedite =>
      'Nobody remembers planting Cedite. One day he was simply there, '
          'already listening where conversations mattered most.\n\n'
          'He seems to know every hallway rumor, every quiet decision, '
          'every detail people assume no one noticed.\n\n'
          'His advice is usually useful, rarely complete. '
          'He expects you to verify the rest yourself.',
    CounselorPersona.ash =>
      'Ash arrived so quietly that no one recalls the moment. '
          'The others never question it; the thought simply never lingers.\n\n'
          'She has watched many plans unfold — some steady, some fragile. '
          'What remained afterward taught her clarity.\n\n'
          'Ask the question that matters. '
          'She will answer exactly that, nothing more.',
  };
}

// ═════════════════════════════════════════════════════════════
// PARTICLE WORLD
// ═════════════════════════════════════════════════════════════

class _ParticleWorld extends StatefulWidget {
  const _ParticleWorld({required this.persona, required this.isActive});

  final CounselorPersona persona;
  final bool isActive;

  @override
  State<_ParticleWorld> createState() => _ParticleWorldState();
}

class _ParticleWorldState extends State<_ParticleWorld>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  late final List<_GridNode> _gridNodes = List.generate(
    100,
    (_) => _GridNode(),
  );
  late final List<_Bubble> _bubbles = List.generate(28, (_) => _Bubble());
  late final List<_Leaf> _leaves = List.generate(22, (_) => _Leaf());
  late final List<_Petal> _petals = List.generate(32, (_) => _Petal());
  late final List<_SnowFlake> _flakes = List.generate(55, (_) => _SnowFlake());
  late final List<_Wisp> _wisps = List.generate(20, (_) => _Wisp());
  late final List<_Ember> _embers = List.generate(55, (_) => _Ember());

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final pc = widget.persona.primary(brightness);

    return CustomPaint(
      painter: _WorldPainter(
        persona: widget.persona,
        t: _ctrl.value * 20,
        color: pc,
        isDark: brightness == Brightness.dark,
        gridNodes: _gridNodes,
        bubbles: _bubbles,
        leaves: _leaves,
        petals: _petals,
        flakes: _flakes,
        wisps: _wisps,
        embers: _embers,
      ),
    );
  }
}

class _WorldPainter extends CustomPainter {
  final CounselorPersona persona;
  final double t;
  final Color color;
  final bool isDark;
  final List<_GridNode> gridNodes;
  final List<_Bubble> bubbles;
  final List<_Leaf> leaves;
  final List<_Petal> petals;
  final List<_SnowFlake> flakes;
  final List<_Wisp> wisps;
  final List<_Ember> embers;

  const _WorldPainter({
    required this.persona,
    required this.t,
    required this.color,
    required this.isDark,
    required this.gridNodes,
    required this.bubbles,
    required this.leaves,
    required this.petals,
    required this.flakes,
    required this.wisps,
    required this.embers,
  });

  // In light mode particles need to be more visible (darker against light bg)
  Color get _c => isDark ? color : color.withOpacity(color.opacity * 1.4);

  @override
  void paint(Canvas canvas, Size size) {
    switch (persona) {
      case CounselorPersona.grover:
        _paintGrover(canvas, size);
      case CounselorPersona.aspen:
        _paintAspen(canvas, size);
      case CounselorPersona.rowan:
        _paintRowan(canvas, size);
      case CounselorPersona.sakura:
        _paintSakura(canvas, size);
      case CounselorPersona.abies:
        _paintAbies(canvas, size);
      case CounselorPersona.cedite:
        _paintCedite(canvas, size);
      case CounselorPersona.ash:
        _paintAsh(canvas, size);
    }
  }

  void _paintGrover(Canvas canvas, Size size) {
    const cell = 40.0;
    final lp = Paint()..strokeWidth = 0.55;
    final boost = isDark ? 1.0 : 2.2;

    for (double y = 0; y < size.height; y += cell) {
      final w = sin(
        (y / size.height * 3.0 - t * 0.14) * pi * 2,
      ).clamp(0.0, 1.0);
      lp.color = _c.withOpacity((0.022 + w * 0.065) * boost);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lp);
    }
    for (double x = 0; x < size.width; x += cell) {
      final w = sin((x / size.width * 3.0 - t * 0.09) * pi * 2).clamp(0.0, 1.0);
      lp.color = _c.withOpacity((0.018 + w * 0.05) * boost);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lp);
    }

    final dp = Paint();
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final diag = (x / size.width + y / size.height) * 1.8;
        final pulse = sin((diag - t * 0.28) * pi * 2.2);
        if (pulse > 0.55) {
          final intensity = (pulse - 0.55) / 0.45;
          dp.color = _c.withOpacity(intensity * 0.25 * boost);
          dp.maskFilter = MaskFilter.blur(BlurStyle.normal, intensity * 4);
          canvas.drawCircle(Offset(x, y), 3.0 * intensity, dp);
        }
      }
    }

    for (final node in gridNodes) {
      final progress = ((t * node.speed + node.phase) % 1.0);
      final y = node.lane * size.height;
      final x =
          progress * (size.width + node.length + 40) - node.length / 2 - 20;
      final shader =
          LinearGradient(
            colors: [
              Colors.transparent,
              _c.withOpacity(node.opacity * 0.55 * boost),
              _c.withOpacity(node.opacity * boost),
              _c.withOpacity(node.opacity * 0.55 * boost),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(x, y),
              width: node.length,
              height: 1,
            ),
          );
      canvas.drawLine(
        Offset(x - node.length / 2, y),
        Offset(x + node.length / 2, y),
        Paint()
          ..shader = shader
          ..strokeWidth = 1.1,
      );
    }
  }

  void _paintAspen(Canvas canvas, Size size) {
    final boost = isDark ? 1.0 : 2.5;
    final rng = Random(42);
    final pts = List.generate(
      20,
      (_) =>
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
    );
    final linePaint = Paint()
      ..strokeWidth = 0.35
      ..color = _c.withOpacity(0.038 * boost);
    for (int i = 0; i < pts.length; i++) {
      for (int j = i + 1; j < pts.length; j++) {
        if ((pts[i] - pts[j]).distance < size.width * 0.32) {
          canvas.drawLine(pts[i], pts[j], linePaint);
        }
      }
    }
    for (final pt in pts) {
      canvas.drawCircle(pt, 1.3, Paint()..color = _c.withOpacity(0.08 * boost));
    }

    for (final b in bubbles) {
      final progress = ((t / b.period + b.phase) % 1.0);
      final y =
          size.height - progress * (size.height + b.radius * 2) + b.radius;
      final x = b.x * size.width + sin(t * 0.38 + b.phase * 9) * b.wobble;
      final fade = progress > 0.88
          ? (1 - progress) / 0.12
          : (progress < 0.04 ? progress / 0.04 : 1.0);
      final a = b.opacity * fade * boost;

      canvas.drawCircle(
        Offset(x, y),
        b.radius,
        Paint()
          ..color = _c.withOpacity(a * 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.85,
      );
      canvas.drawCircle(
        Offset(x, y),
        b.radius - 1,
        Paint()..color = _c.withOpacity(a * 0.045),
      );
      canvas.drawCircle(
        Offset(x - b.radius * 0.32, y - b.radius * 0.32),
        b.radius * 0.22,
        Paint()..color = _c.withOpacity(a * 0.32),
      );
      if (b.radius > 10) {
        canvas.drawCircle(
          Offset(x, y),
          b.radius * 1.5,
          Paint()
            ..color = _c.withOpacity(a * 0.035)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.radius * 0.55),
        );
      }
    }
  }

  void _paintRowan(Canvas canvas, Size size) {
    final boost = isDark ? 1.0 : 2.2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.85),
          radius: 0.75,
          colors: [
            _c.withOpacity(0.11 * boost),
            _c.withOpacity(0.04 * boost),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final rng = Random(7);
    for (int i = 0; i < 45; i++) {
      final mx = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final phase = rng.nextDouble();
      final rise = ((t * 0.018 + phase) % 1.0);
      final moteY = baseY - rise * 90;
      final drift = sin(t * 0.28 + phase * pi * 2) * 9;
      canvas.drawCircle(
        Offset(mx + drift, moteY),
        0.8 + rng.nextDouble() * 1.2,
        Paint()
          ..color = _c.withOpacity(
            (0.03 + sin(t * 0.9 + phase * 4) * 0.018) * boost,
          ),
      );
    }

    for (final l in leaves) {
      final progress = ((t / l.period + l.phase) % 1.0);
      final y = progress * (size.height + l.size * 2) - l.size;
      final x =
          (l.startX +
              l.driftX * progress +
              sin(t * 0.32 + l.phase * 5.5) * 0.042) *
          size.width;
      final angle = t * l.rotSpeed + l.phase * pi * 2;
      final fade = progress < 0.05
          ? progress / 0.05
          : progress > 0.9
          ? (1 - progress) / 0.1
          : 1.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      final path = Path()
        ..moveTo(0, -l.size)
        ..quadraticBezierTo(l.size * 0.65, -l.size * 0.14, 0, l.size)
        ..quadraticBezierTo(-l.size * 0.65, -l.size * 0.14, 0, -l.size);
      canvas.drawPath(
        path,
        Paint()..color = _c.withOpacity(l.opacity * fade * 0.85 * boost),
      );
      canvas.drawLine(
        Offset(0, -l.size * 0.75),
        Offset(0, l.size * 0.75),
        Paint()
          ..color = _c.withOpacity(l.opacity * fade * 0.32 * boost)
          ..strokeWidth = 0.55,
      );

      for (int v = 1; v <= 3; v++) {
        final vy = -l.size * 0.5 + v * l.size * 0.33;
        final vx = l.size * 0.38;
        final vp = Paint()
          ..color = _c.withOpacity(l.opacity * fade * 0.18 * boost)
          ..strokeWidth = 0.38;
        canvas.drawLine(Offset(0, vy), Offset(vx, vy - l.size * 0.08), vp);
        canvas.drawLine(Offset(0, vy), Offset(-vx, vy - l.size * 0.08), vp);
      }
      canvas.restore();
    }
  }

  void _paintSakura(Canvas canvas, Size size) {
    final boost = isDark ? 1.0 : 2.0;
    final bx = size.width * 0.5 + sin(t * 0.065) * size.width * 0.22;
    final by = size.height * 0.32 + cos(t * 0.048) * size.height * 0.14;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bx, by),
        width: size.width * 1.15,
        height: size.width * 1.15,
      ),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                _c.withOpacity(0.07 * boost),
                _c.withOpacity(0.025 * boost),
                Colors.transparent,
              ],
              stops: const [0, 0.5, 1.0],
            ).createShader(
              Rect.fromCenter(
                center: Offset(bx, by),
                width: size.width * 1.15,
                height: size.width * 1.15,
              ),
            ),
    );

    for (final p in petals) {
      final progress = ((t / p.period + p.phase) % 1.0);
      final y = progress * (size.height + p.size * 2) - p.size;
      final x = p.startX * size.width + sin(t * 0.58 + p.phase * 4.8) * p.sway;
      final angle = t * p.rotSpeed + p.phase * pi * 2;
      final fade = progress < 0.04
          ? progress / 0.04
          : progress > 0.93
          ? (1 - progress) / 0.07
          : 1.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      final path = Path();
      for (int i = 0; i < 5; i++) {
        final a = (i / 5) * pi * 2 - pi / 2;
        path.addOval(
          Rect.fromCenter(
            center: Offset(cos(a) * p.size * 0.52, sin(a) * p.size * 0.52),
            width: p.size * 0.72,
            height: p.size * 0.88,
          ),
        );
      }
      canvas.drawPath(
        path,
        Paint()..color = _c.withOpacity(p.opacity * fade * boost),
      );
      canvas.drawCircle(
        Offset.zero,
        p.size * 0.14,
        Paint()..color = _c.withOpacity(p.opacity * fade * 0.5 * boost),
      );
      canvas.restore();
    }
  }

  void _paintAbies(Canvas canvas, Size size) {
    final boost = isDark ? 1.0 : 2.2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.25),
          radius: 0.72,
          colors: [
            Colors.transparent,
            _c.withOpacity(0.035 * boost),
            _c.withOpacity(0.095 * boost),
          ],
          stops: const [0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final rng = Random(13);
    for (int i = 0; i < 14; i++) {
      final fy = rng.nextDouble() * size.height;
      final fw = 35 + rng.nextDouble() * 130;
      final fx = rng.nextDouble() * size.width;
      canvas.drawLine(
        Offset(fx, fy),
        Offset(fx + fw, fy),
        Paint()
          ..color = _c.withOpacity((0.018 + rng.nextDouble() * 0.032) * boost)
          ..strokeWidth = 0.45,
      );
    }

    for (final f in flakes) {
      final progress = ((t / f.period + f.phase) % 1.0);
      final y = progress * (size.height + f.radius * 2) - f.radius;
      final x =
          (f.x + f.drift * progress) * size.width +
          sin(t * f.wobbleSpeed + f.wobble) * 11 * f.radius;
      final fade = progress < 0.04
          ? progress / 0.04
          : progress > 0.94
          ? (1 - progress) / 0.06
          : 1.0;

      canvas.drawCircle(
        Offset(x, y),
        f.radius,
        Paint()
          ..color = _c.withOpacity(f.opacity * fade * boost)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.radius * 0.38),
      );

      if (f.radius > 1.7) {
        final cp = Paint()
          ..color = _c.withOpacity(f.opacity * fade * 0.5 * boost)
          ..strokeWidth = 0.38;
        final rot = t * f.wobbleSpeed * 0.04 + f.wobble;
        for (int s = 0; s < 6; s++) {
          final sa = s * pi / 3 + rot;
          final armLen = f.radius * 2.4;
          canvas.drawLine(
            Offset(x, y),
            Offset(x + cos(sa) * armLen, y + sin(sa) * armLen),
            cp,
          );
          for (final frac in [0.45, 0.75]) {
            final ax = x + cos(sa) * armLen * frac;
            final ay = y + sin(sa) * armLen * frac;
            final barLen = armLen * 0.22;
            final ba = sa + pi / 2;
            canvas.drawLine(
              Offset(ax - cos(ba) * barLen, ay - sin(ba) * barLen),
              Offset(ax + cos(ba) * barLen, ay + sin(ba) * barLen),
              cp,
            );
          }
        }
      }
    }

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _c.withOpacity(0.055 * boost),
                _c.withOpacity(0.13 * boost),
              ],
              stops: const [0, 0.5, 1.0],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.72,
                size.width,
                size.height * 0.28,
              ),
            ),
    );
  }

  void _paintCedite(Canvas canvas, Size size) {
    final boost = isDark ? 1.0 : 2.5;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            _c.withOpacity(0.08 * boost),
            _c.withOpacity(0.02 * boost),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    for (final w in wisps) {
      final progress = ((t * w.speed + w.phase) % 1.0);
      final spawnY = size.height * (0.55 + w.laneX * 0.25);
      final y = spawnY - progress * spawnY * 1.15;
      final wobbleAmp = size.width * 0.018 * (0.3 + progress * 2.2);
      final x =
          w.laneX * size.width +
          sin(t * w.swaySpeed + w.phase * pi * 2 + progress * 6.5) * wobbleAmp +
          cos(t * w.swaySpeed * 0.6 + w.phase * 4.1) * wobbleAmp * 0.45;
      final r = size.width * w.radiusFrac * (0.15 + progress * 0.85);
      final fade = progress < 0.08
          ? progress / 0.08
          : progress > 0.72
          ? (1.0 - progress) / 0.28
          : 1.0;
      final a = w.opacity * fade * boost;
      if (a < 0.004) continue;

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = _c.withOpacity(a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.85),
      );
    }

    for (final w in wisps) {
      final spawnY = size.height * (0.55 + w.laneX * 0.25);
      final pulse = 0.6 + 0.4 * sin(t * 1.4 + w.phase * pi * 2);
      canvas.drawCircle(
        Offset(w.laneX * size.width, spawnY),
        2.2,
        Paint()
          ..color = _c.withOpacity(0.18 * pulse * boost)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  void _paintAsh(Canvas canvas, Size size) {
    final boost = isDark ? 1.0 : 2.2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 0.85,
          colors: [
            _c.withOpacity(0.14 * boost),
            _c.withOpacity(0.05 * boost),
            Colors.transparent,
          ],
          stops: const [0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.82, size.width, size.height * 0.18),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _c.withOpacity(0.04 * boost),
                _c.withOpacity(0.10 * boost),
              ],
              stops: const [0, 0.4, 1.0],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.82,
                size.width,
                size.height * 0.18,
              ),
            ),
    );

    for (final e in embers) {
      final progress = ((t * e.speed + e.phase) % 1.0);
      final y = progress * (size.height + e.radius * 4) - e.radius;
      final x =
          e.x * size.width +
          sin(t * e.wobbleSpeed + e.phase * pi * 2) * e.sway +
          cos(t * e.wobbleSpeed * 0.55 + e.phase * 3.1) * e.sway * 0.4;
      final flicker = 0.55 + 0.45 * sin(t * e.flickerSpeed + e.phase * 7.3);
      final fade = progress < 0.05
          ? progress / 0.05
          : progress > 0.88
          ? (1 - progress) / 0.12
          : 1.0;
      final a = e.opacity * fade * flicker * boost;
      if (a < 0.005) continue;

      canvas.drawCircle(
        Offset(x, y),
        e.radius * 3.5,
        Paint()
          ..color = _c.withOpacity(a * 0.12)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, e.radius * 2.8),
      );
      canvas.drawCircle(
        Offset(x, y),
        e.radius * 1.6,
        Paint()
          ..color = _c.withOpacity(a * 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, e.radius * 1.1),
      );
      canvas.drawCircle(
        Offset(x, y),
        e.radius * 0.55,
        Paint()..color = _c.withOpacity((a * 1.4).clamp(0.0, 1.0)),
      );

      if (e.radius > 1.4) {
        final trailLen = e.radius * (3.5 + 2.0 * flicker);
        final shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [_c.withOpacity(a * 0.55), Colors.transparent],
        ).createShader(Rect.fromPoints(Offset(x, y), Offset(x, y - trailLen)));
        canvas.drawLine(
          Offset(x, y),
          Offset(x + sin(e.phase * 4.2) * e.radius * 0.8, y - trailLen),
          Paint()
            ..shader = shader
            ..strokeWidth = e.radius * 0.45
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    final rng = Random(33);
    final staticPts = List.generate(
      10,
      (_) => Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height * 0.75,
      ),
    );
    for (final pt in staticPts) {
      final flicker = 0.4 + 0.6 * sin(t * 0.06 + pt.dx * 0.012);
      canvas.drawCircle(
        pt,
        0.6,
        Paint()..color = _c.withOpacity(0.04 * flicker * boost),
      );
    }
  }

  @override
  bool shouldRepaint(_WorldPainter old) => old.t != t || old.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────
// PARTICLE DATA MODELS  (unchanged)
// ─────────────────────────────────────────────────────────────

class _GridNode {
  final double lane = Random().nextDouble();
  final double phase = Random().nextDouble();
  final double speed = 0.018 + Random().nextDouble() * 0.038;
  final double length = 28.0 + Random().nextDouble() * 85;
  final double opacity = 0.08 + Random().nextDouble() * 0.20;
}

class _Bubble {
  final double x = Random().nextDouble();
  final double phase = Random().nextDouble();
  final double period = 6.0 + Random().nextDouble() * 11;
  final double radius = 5.0 + Random().nextDouble() * 22;
  final double opacity = 0.05 + Random().nextDouble() * 0.12;
  final double wobble = Random().nextDouble() * 22 - 11;
}

class _Leaf {
  final double startX = Random().nextDouble();
  final double phase = Random().nextDouble();
  final double period = 7.0 + Random().nextDouble() * 10;
  final double size = 6.0 + Random().nextDouble() * 15;
  final double opacity = 0.07 + Random().nextDouble() * 0.14;
  final double driftX = (Random().nextDouble() - 0.5) * 0.26;
  final double rotSpeed = (Random().nextDouble() - 0.5) * 2.2;
}

class _Petal {
  final double startX = Random().nextDouble();
  final double phase = Random().nextDouble();
  final double period = 5.0 + Random().nextDouble() * 9;
  final double size = 5.0 + Random().nextDouble() * 11;
  final double opacity = 0.08 + Random().nextDouble() * 0.17;
  final double sway = (Random().nextDouble() - 0.5) * 58;
  final double rotSpeed = (Random().nextDouble() - 0.5) * 1.2;
}

class _SnowFlake {
  final double x = Random().nextDouble();
  final double phase = Random().nextDouble();
  final double period = 5.0 + Random().nextDouble() * 11;
  final double radius = 0.7 + Random().nextDouble() * 3.4;
  final double opacity = 0.06 + Random().nextDouble() * 0.22;
  final double drift = (Random().nextDouble() - 0.5) * 0.07;
  final double wobble = Random().nextDouble() * pi * 2;
  final double wobbleSpeed = 0.35 + Random().nextDouble() * 1.1;
}

class _Wisp {
  final double laneX = Random().nextDouble();
  final double swayAmp = 0.015 + Random().nextDouble() * 0.02;
  final double swaySpeed = 0.55 + Random().nextDouble() * 0.45;
  final double radiusFrac = 0.022 + Random().nextDouble() * 0.018;
  final double speed = 0.032 + Random().nextDouble() * 0.028;
  final double opacity = 0.18 + Random().nextDouble() * 0.14;
  final double phase = Random().nextDouble();
}

class _Ember {
  final double x = Random().nextDouble();
  final double phase = Random().nextDouble();
  final double speed = 0.018 + Random().nextDouble() * 0.032;
  final double radius = 0.8 + Random().nextDouble() * 3.2;
  final double opacity = 0.18 + Random().nextDouble() * 0.45;
  final double sway = 6.0 + Random().nextDouble() * 14.0;
  final double wobbleSpeed = 0.4 + Random().nextDouble() * 0.8;
  final double flickerSpeed = 2.5 + Random().nextDouble() * 4.5;
}

// ─────────────────────────────────────────────────────────────
// BACKWARD-COMPATIBLE SHIM
// ─────────────────────────────────────────────────────────────

class PersonaPickerSheet extends StatelessWidget {
  const PersonaPickerSheet({
    super.key,
    required this.currentPersona,
    required this.onSelect,
    required this.isChange,
    this.onOpenFrozenLake,
  });

  final CounselorPersona currentPersona;
  final ValueChanged<CounselorPersona> onSelect;
  final bool isChange;
  final VoidCallback? onOpenFrozenLake;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          PersonaPickerRoute(
            currentPersona: currentPersona,
            onSelect: onSelect,
            isChange: isChange,
            onOpenFrozenLake: onOpenFrozenLake,
          ),
        );
      }
    });
    return const SizedBox.shrink();
  }
}
