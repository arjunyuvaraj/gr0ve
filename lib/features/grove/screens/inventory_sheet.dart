import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TInventorySheet extends StatefulWidget {
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
  State<TInventorySheet> createState() => _TInventorySheetState();
}

class _TInventorySheetState extends State<TInventorySheet> {
  String? _selectedItemName;

  static String _getItemDescription(String itemName) {
    switch (itemName.toLowerCase()) {
      case 'standard apples':
        return 'A simple, standard apple. It restores a small amount of vitality.';
      case 'premium apples':
        return 'A remarkably high-quality apple. It holds strong restorative properties.';
      case 'golden apples':
        return 'An impossibly rare golden apple. It pulses with a strange, ancient energy.';
      case 'apple juice':
        return 'A sweet, refreshing blend from Newton. It restores your vitality and spirit.';
      case 'orange juice':
        return 'A tart, energizing blend from Darwin. It sharpens your focus and resolve.';
      case 'custom juice':
        return 'A unique, mysterious blend. Its true effects remain entirely unknown.';
      case 'dawn\'s branch':
      case 'branch':
        return 'A pale, ancient branch gifted by Dawn. It pulls toward where you need to be.';
      case 'flask of tears':
        return 'A delicate glass flask. It is filled with shimmering, unspoken tears.';
      case 'mossy residue':
        return 'A small circular vial. It contains a strange, glowing mossy substance.';
      case 'warming pouch':
        return 'A thick, insulated pouch. It retains heat during the coldest nights.';
      default:
        return 'An unknown, undocumented artifact. Its origin is a complete mystery.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayItems = widget.items.where((i) {
      final lower = i.toLowerCase();
      return lower != 'seed' && lower != "dawn's seed";
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: colors.outline.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: colors.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVENTORY',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'THE THRESHOLD POUCH',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    '${displayItems.length} / 16',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 16,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final hasItem = index < displayItems.length;
                final itemName = hasItem ? displayItems[index] : '';
                final mode = isDark ? 'dark' : 'light';
                final isSelected = hasItem && itemName == _selectedItemName;

                String? asset;
                if (hasItem) {
                  switch (itemName.toLowerCase()) {
                    case 'standard apples':
                    case 'premium apples':
                    case 'golden apples':
                    case 'apple juice':
                      asset = 'assets/story/inventory/apple_juice_$mode.png';
                      break;
                    case 'orange juice':
                    case 'custom juice':
                      asset = 'assets/story/inventory/orange_juice_$mode.png';
                      break;
                    case 'dawn\'s branch':
                    case 'branch':
                      asset = 'assets/story/inventory/branch_$mode.png';
                      break;
                    case 'flask of tears':
                      asset = 'assets/story/inventory/flask_of_tears_$mode.png';
                      break;
                    case 'mossy residue':
                      asset = 'assets/story/inventory/mossy_residue_$mode.png';
                      break;
                    case 'warming pouch':
                      asset = 'assets/story/inventory/warming_pouch_$mode.png';
                      break;
                  }
                }

                return GestureDetector(
                  onTap: hasItem
                      ? () {
                          setState(() {
                            _selectedItemName = isSelected ? null : itemName;
                          });
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: hasItem
                          ? (isSelected
                                ? colors.primary.withOpacity(0.03)
                                : Colors.transparent)
                          : colors.surfaceContainerHighest.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasItem
                            ? (isSelected
                                  ? colors.primary
                                  : colors.outline.withOpacity(0.1))
                            : colors.outline.withOpacity(0.04),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: EdgeInsets.all(
                          hasItem && asset != null ? 2 : 4,
                        ),
                        child: hasItem
                            ? (asset != null
                                  ? Image.asset(asset, fit: BoxFit.contain)
                                  : Text(
                                      itemName.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: colors.onSurface.withOpacity(
                                          0.9,
                                        ),
                                        height: 1.1,
                                      ),
                                    ))
                            : Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colors.outline.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 112,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedItemName != null
                    ? Container(
                        key: ValueKey(_selectedItemName),
                        width: double.infinity,
                        height: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withOpacity(
                            0.3,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.outline.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedItemName!.toUpperCase(),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: colors.primary,
                                letterSpacing: 1.0,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              _getItemDescription(_selectedItemName!),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: colors.onSurface.withOpacity(0.8),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        key: const ValueKey('empty'),
                        width: double.infinity,
                        height: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 24,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Dawn\'s light guides your path.\nThese artifacts follow you through the threshold.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: colors.onSurface.withOpacity(0.4),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
