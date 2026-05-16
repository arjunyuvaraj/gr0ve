import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/grove/grove_progress_service.dart';
import 'package:gr0ve/features/grove/widgets/stat_scale_widget.dart';

class EpisodeCompleteSheet extends StatelessWidget {
  final String title;
  final GroveGameState state;
  final String? unlockedPfpAsset;
  final String? unlockedPfpName;
  final VoidCallback onReturnToChapters;

  const EpisodeCompleteSheet({
    super.key,
    required this.title,
    required this.state,
    required this.onReturnToChapters,
    this.unlockedPfpAsset,
    this.unlockedPfpName,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required GroveGameState state,
    String? unlockedPfpAsset,
    String? unlockedPfpName,
    required VoidCallback onReturnToChapters,
  }) {
    HapticFeedback.heavyImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => EpisodeCompleteSheet(
        title: title,
        state: state,
        unlockedPfpAsset: unlockedPfpAsset,
        unlockedPfpName: unlockedPfpName,
        onReturnToChapters: onReturnToChapters,
      ),
    );
  }

  String _fmt(int v) => v > 0 ? '+$v' : '$v';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pc = colors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: pc.withOpacity(0.2), width: 2)),
          boxShadow: [
            BoxShadow(
              color: pc.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: pc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'EPISODE COMPLETE',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: pc,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (unlockedPfpAsset != null) ...[
                  Text(
                    'REWARD UNLOCKED',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface.withOpacity(0.5),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: pc.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: pc.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            unlockedPfpAsset!,
                            width: 48,
                            height: 48,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                unlockedPfpName ?? 'New Avatar',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: colors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Equip in Profile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Stats summary - Scale Style
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colors.outline.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'STATS',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Scales
                      StatScaleWidget(
                        label: 'STABILITY',
                        value: state.stability,
                        colors: colors,
                      ),
                      const SizedBox(height: 16),
                      StatScaleWidget(
                        label: 'CONNECTIVITY',
                        value: state.connectivity,
                        colors: colors,
                      ),
                      const SizedBox(height: 16),
                      StatScaleWidget(
                        label: 'VITALITY',
                        value: state.vitality,
                        colors: colors,
                      ),
                      const SizedBox(height: 16),
                      StatScaleWidget(
                        label: 'TRANSIENCE',
                        value: state.transience,
                        colors: colors,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onReturnToChapters();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: pc,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'RETURN TO CHAPTERS',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
