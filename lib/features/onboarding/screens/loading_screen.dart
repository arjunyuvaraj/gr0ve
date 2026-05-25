import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:confetti/confetti.dart';
import 'package:gr0ve/main.dart' show debugNow;

class LogoLoadingScreen extends StatefulWidget {
  const LogoLoadingScreen({super.key});

  @override
  State<LogoLoadingScreen> createState() => _LogoLoadingScreenState();
}

class _LogoLoadingScreenState extends State<LogoLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _version = '';

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoGlow;

  late List<Animation<double>> _treeOpacities;
  late List<Animation<double>> _treeScales;
  late List<Animation<double>> _treeRotations;
  late List<Animation<Offset>> _treeSlides;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted)
        setState(() => _version = 'Version ${info.version}: Orchard');
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeInOut),
      ),
    );

    _treeOpacities = List.generate(4, (index) {
      double start = 0.4 + (index * 0.1);
      double end = (start + 0.2).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _treeScales = List.generate(4, (index) {
      double start = 0.4 + (index * 0.1);
      double end = (start + 0.3).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.elasticOut),
        ),
      );
    });

    _treeRotations = List.generate(4, (index) {
      double start = 0.4 + (index * 0.1);
      double end = (start + 0.25).clamp(0.0, 1.0);
      final direction = index.isEven ? 1.0 : -1.0;
      return Tween<double>(begin: 0.0, end: direction * 6.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _treeSlides = List.generate(4, (index) {
      double start = 0.4 + (index * 0.1);
      double end = (start + 0.3).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.8),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _controller.forward();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 10),
    );

    if (debugNow.weekday == DateTime.wednesday) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final trees = ['grover', 'aspen', 'rowan', 'sakura'];

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: true,
              colors: [
                colors.primary,
                colors.secondary,
                colors.tertiary,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_logoGlow.value > 0.01)
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.primary.withOpacity(
                                        0.15 * _logoGlow.value,
                                      ),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),

                            Text(
                              "gr0ve",
                              style: text.displayLarge?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 60),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final treeName = trees[index];
                          final asset =
                              'assets/app_icons/png/${treeName}_${isDark ? 'dark' : 'light'}.png';
                          final opacity = _treeOpacities[index].value;

                          return Transform.translate(
                            offset: _treeSlides[index].value * 20,
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.rotate(
                                angle:
                                    (_treeRotations[index].value * 3.14159) /
                                    180.0,
                                child: Transform.scale(
                                  scale: _treeScales[index].value,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: _buildTreeShadow(
                                        isDark: isDark,
                                        colors: colors,
                                        opacity: opacity,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.asset(
                                        asset,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AnimatedOpacity(
                opacity: _version.isEmpty ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    if (debugNow.weekday == DateTime.wednesday) ...[
                      Text(
                        'GR0VE / Happy Half-Year Anniversary!',
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(
                          color: colors.primary.withOpacity(0.8),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      _version,
                      textAlign: TextAlign.center,
                      style: text.labelSmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.3),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BoxShadow> _buildTreeShadow({
    required bool isDark,
    required dynamic colors,
    required double opacity,
  }) {
    if (isDark) {
      return [
        BoxShadow(
          color: colors.primary.withOpacity(0.15 * opacity),
          blurRadius: 16,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: colors.primary.withOpacity(0.08 * opacity),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.08 * opacity),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04 * opacity),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];
    }
  }
}
