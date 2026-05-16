import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';

class OriginalSeedScreen extends StatefulWidget {
  const OriginalSeedScreen({super.key});

  @override
  State<OriginalSeedScreen> createState() => _OriginalSeedScreenState();
}

class _OriginalSeedScreenState extends State<OriginalSeedScreen>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _iconFade;
  late Animation<double> _iconScale;
  late Animation<double> _titleFade;
  late List<Animation<double>> _stanzaFades;
  late Animation<double> _btnFade;

  final List<String> _stanzas = [
    "Beneath the hush of fading dawn,\nA dying branch, nearly gone,\nYet still the final light shone on,\nAnd pulled the carrier onward still.",
    "Through orchards dense with heavy bloom,\nPast weeping willows drowned in gloom,\nThrough tangled rainforests that consume,\nAnd pulled the carrier onward still.",
    "At open shores with breaking skies,\nThe unnamed waters surged and cried,\nA frigid landfall stretched out wide,\nAnd pulled the carrier onward still.",
    "Through frozen lakes of forgotten past,\nPast warped canyons where shadows clashed,\nAcross arid deserts where nothing lasts,\nAnd pulled the carrier onward still.",
    "Beyond the Thunderveil’s hidden cove,\nPast Verdant Garden’s sacred home,\nThere, plant the seed, no more alone,\nWithin the holy, living Gr0ve."
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    _iconFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.35, curve: Curves.easeOut),
    );

    _stanzaFades = [];
    for (int i = 0; i < _stanzas.length; i++) {
      final start = 0.3 + (i * 0.1);
      final end = start + 0.2;
      _stanzaFades.add(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    }

    _btnFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final pc = colors.primary;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _iconFade,
                    child: ScaleTransition(
                      scale: _iconScale,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pc.withOpacity(0.08),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSparkles,
                            color: pc,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _titleFade,
                    child: Column(
                      children: [
                        Text(
                          'The Original Seed',
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: pc.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: pc.withOpacity(0.25)),
                          ),
                          child: Text(
                            'Origin',
                            style: text.labelSmall?.copyWith(
                              color: pc,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'The final light shone on...',
                          style: text.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(0.3),
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  ...List.generate(_stanzas.length, (index) {
                    return FadeTransition(
                      opacity: _stanzaFades[index],
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          _stanzas[index],
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurface.withOpacity(0.8),
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _btnFade,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pc,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
