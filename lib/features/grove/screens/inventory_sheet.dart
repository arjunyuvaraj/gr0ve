import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TInventorySheet extends StatelessWidget {
  final List<String> items;

  const TInventorySheet({super.key, required this.items});

  static void show(BuildContext context, List<String> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TInventorySheet(items: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: colors.outline.withOpacity(0.1))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INVENTORY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: colors.onSurface,
                ),
              ),
              Text(
                '${items.length} / 16',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 4x4 Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 16,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final hasItem = index < items.length;
              final itemName = hasItem ? items[index] : '';
              final mode = isDark ? 'dark' : 'light';

              String? asset;
              if (hasItem) {
                switch (itemName.toLowerCase()) {
                  case 'standard apples' ||
                      'premium apples' ||
                      'golden apples' ||
                      'apple juice':
                    asset =
                        'assets/story/inventory/apple_juice_$mode.png';
                  case 'orange juice' || 'custom juice':
                    asset =
                        'assets/story/inventory/orange_juice_$mode.png';
                  case 'dawn\'s branch' || 'branch':
                    asset = 'assets/story/inventory/branch_$mode.png';
                  case 'dawn\'s seed' || 'seed':
                    asset = isDark
                        ? 'assets/story/characters/ep0/dawn_dark.png'
                        : 'assets/story/characters/ep0/dawn_light.png';
                  case 'flask of tears':
                    asset = 'assets/story/inventory/flask_of_tears_$mode.png';
                  case 'warm knapsack':
                    asset = 'assets/story/inventory/warm_knapsack_$mode.png';
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: hasItem
                      ? colors.primary.withOpacity(0.05)
                      : colors.surfaceContainerHighest.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasItem
                        ? colors.primary.withOpacity(0.3)
                        : colors.outline.withOpacity(0.05),
                    width: hasItem ? 1.5 : 1,
                  ),
                ),
                padding: EdgeInsets.all(hasItem && asset != null ? 10 : 4),
                alignment: Alignment.center,
                child: hasItem
                    ? (asset != null
                          ? Image.asset(asset, fit: BoxFit.contain)
                          : Text(
                              itemName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface.withOpacity(0.9),
                                height: 1.1,
                              ),
                            ))
                    : null,
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Dawn\'s light guides your path. These artifacts follow you through the threshold.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: colors.onSurface.withOpacity(0.4),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
