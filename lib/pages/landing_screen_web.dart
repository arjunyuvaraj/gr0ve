import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/data/changelog_entries.dart';
import 'package:gr0ve/utilities/helper_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingWebsiteScreen extends StatelessWidget {
  const LandingWebsiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.primary, colors.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),

                    Text(
                      "gr0ve".capitalized,
                      style: text.displayLarge?.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Navigate Your Day".capitalized,
                      style: text.displaySmall?.copyWith(
                        color: colors.onPrimary.withAlpha(210),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: getLetterSpacing(14, 10),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Text(
                        "Gr0ve simplifies your school day by showing teacher absences, class coverage, bus locations, and quick links in one clean, fast interface. Star favorite teachers, get daily updates, and plan your day without digging through messy docs.",
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(
                          color: colors.onPrimary.withAlpha(230),
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: 360,
                      child: Column(
                        children: [
                          Material(
                            elevation: 8,
                            shadowColor: colors.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            child: CustomPrimaryButton(
                              label: "Get Started",
                              onTap: () =>
                                  Navigator.pushNamed(context, '/navigation'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Material(
                                  elevation: 4,
                                  shadowColor: colors.surface.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  child: _DownloadButton(
                                    label: "Android",
                                    icon: Icons.android,
                                    onTap: () {
                                      launchUrl(
                                        Uri.parse(
                                          'https://play.google.com/apps/testing/com.arjunyuvaraj.gr0ve',
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Material(
                                  elevation: 4,
                                  shadowColor: colors.surface.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  child: _DownloadButton(
                                    label: "iOS",
                                    icon: Icons.apple,
                                    onTap: () {},
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ChangelogPager(changelogEntries: changelogEntries),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangelogPager extends StatefulWidget {
  final Map<String, String> changelogEntries;

  const _ChangelogPager({required this.changelogEntries});

  @override
  State<_ChangelogPager> createState() => _ChangelogPagerState();
}

class _ChangelogPagerState extends State<_ChangelogPager> {
  late final List<String> versions;
  int currentIndex = 0;
  bool isExpanded = true;

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
        padding: EdgeInsets.only(top: 8, bottom: 8, left: 24, right: 8),
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        width: 360,
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

class _DownloadButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DownloadButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Material(
      color: colors.surface.withOpacity(0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                label.capitalized,
                style: text.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: getLetterSpacing(12, 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
