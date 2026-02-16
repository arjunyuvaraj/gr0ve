import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';

class ChangelogPager extends StatefulWidget {
  final Map<String, String> changelogEntries;

  const ChangelogPager({required this.changelogEntries});

  @override
  State<ChangelogPager> createState() => ChangelogPagerState();
}

class ChangelogPagerState extends State<ChangelogPager> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Get the latest version (first entry)
    final latestVersion = widget.changelogEntries.keys.first;
    final latestEntry = widget.changelogEntries[latestVersion]!;

    return InkWell(
      onTap: () => setState(() => isExpanded = !isExpanded),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What's New",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Version $latestVersion',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
              ],
            ),

            // Expandable content
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Divider
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.outline.withOpacity(0),
                                colors.outline.withOpacity(0.1),
                                colors.outline.withOpacity(0),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Changelog content
                        Text(
                          latestEntry,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurface.withOpacity(0.75),
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 4),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
