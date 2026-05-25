import 'package:flutter/material.dart';

class StatScaleWidget extends StatelessWidget {
  final String label;
  final int value;
  final ColorScheme colors;
  final int maxRange;

  const StatScaleWidget({
    super.key,
    required this.label,
    required this.value,
    required this.colors,
    this.maxRange = 5,
  });

  @override
  Widget build(BuildContext context) {
    final double normalized = (value / maxRange).clamp(-1.0, 1.0);

    String leftLabel = '';
    String rightLabel = '';
    IconData icon;

    if (label == 'STABILITY') {
      leftLabel = 'CHAOTIC';
      rightLabel = 'STEADY';
      icon = Icons.balance_rounded;
    } else if (label == 'CONNECTIVITY') {
      leftLabel = 'ISOLATED';
      rightLabel = 'UNIFIED';
      icon = Icons.hub_rounded;
    } else if (label == 'VITALITY') {
      leftLabel = 'DRAINED';
      rightLabel = 'RADIANT';
      icon = Icons.auto_awesome_rounded;
    } else if (label == 'TRANSIENCE') {
      leftLabel = 'FLEETING';
      rightLabel = 'ETERNAL';
      icon = Icons.hourglass_empty_rounded;
    } else {
      icon = Icons.bar_chart_rounded;
    }

    final Color statColor;
    if (value > 0) {
      final intensity = (value / maxRange).clamp(0.0, 1.0);
      statColor = Color.lerp(
        const Color(0xFF5AE6A0),
        const Color(0xFF00B894),
        intensity,
      )!;
    } else if (value < 0) {
      final intensity = (value.abs() / maxRange).clamp(0.0, 1.0);
      statColor = Color.lerp(
        const Color(0xFFFF7675),
        const Color(0xFFD63031),
        intensity,
      )!;
    } else {
      statColor = colors.onSurface.withOpacity(0.15);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: colors.onSurface.withOpacity(0.5)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface.withOpacity(0.5),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statColor.withOpacity(0.2)),
              ),
              child: Text(
                value > 0 ? '+$value' : '$value',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: statColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _sideLabel(leftLabel, colors),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: colors.onSurface.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: colors.onSurface.withOpacity(0.06)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 2,
                      height: 14,
                      color: colors.onSurface.withOpacity(0.1),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final halfWidth = constraints.maxWidth / 2;
                        final fillWidth = halfWidth * normalized.abs();

                        return Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              left: normalized >= 0
                                  ? halfWidth
                                  : halfWidth - fillWidth,
                              width: fillWidth,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      statColor.withOpacity(0.6),
                                      statColor,
                                    ],
                                    begin: normalized >= 0
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    end: normalized >= 0
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statColor.withOpacity(0.3),
                                      blurRadius: 4,
                                      spreadRadius: -1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _sideLabel(rightLabel, colors),
          ],
        ),
      ],
    );
  }

  Widget _sideLabel(String text, ColorScheme colors) {
    return SizedBox(
      width: 50,
      child: Text(
        text,
        textAlign:
            text == 'CHAOTIC' ||
                text == 'ISOLATED' ||
                text == 'DRAINED' ||
                text == 'FLEETING'
            ? TextAlign.right
            : TextAlign.left,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 7,
          fontWeight: FontWeight.w800,
          color: colors.onSurface.withOpacity(0.35),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
