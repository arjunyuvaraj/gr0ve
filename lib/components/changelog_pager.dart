import 'package:flutter/material.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/helper_functions.dart';

class ChangelogPager extends StatefulWidget {
  final Map<String, String> changelogEntries;

  const ChangelogPager({required this.changelogEntries});

  @override
  State<ChangelogPager> createState() => ChangelogPagerState();
}

class ChangelogPagerState extends State<ChangelogPager> {
  late final List<String> versions;
  int currentIndex = 0;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    versions = widget.changelogEntries.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    final currentVersion = versions[currentIndex];
    final entry = widget.changelogEntries[currentVersion]!;

    return Material(
      elevation: 6,
      shadowColor: colors.surface.withOpacity(0.4),
      borderRadius: BorderRadius.circular(20),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 24, right: 8),
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Dev Notes".capitalized,
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                        letterSpacing: getLetterSpacing(12, 10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        currentVersion,
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 28,
                  ),
                  onPressed: () => setState(() => isExpanded = !isExpanded),
                  color: colors.primary,
                ),
              ],
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text(
                            entry,
                            style: text.bodyMedium?.copyWith(
                              color: colors.onSurface.withAlpha(200),
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, size: 20),
                              onPressed: currentIndex > 0
                                  ? () => setState(() => currentIndex--)
                                  : null,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward, size: 20),
                              onPressed: currentIndex < versions.length - 1
                                  ? () => setState(() => currentIndex++)
                                  : null,
                              color: colors.primary,
                            ),
                          ],
                        ),
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
