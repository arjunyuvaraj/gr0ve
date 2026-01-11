import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/data/changelog_entries.dart';
import 'package:gr0ve/utilities/data/landing_content.dart';
import 'package:gr0ve/utilities/helper_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();
    final colors = context.colors;
    final text = context.text;

    Future<void> _onGetStarted(BuildContext context) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('landing_seen', true);
      Navigator.of(context).pushReplacementNamed('/navigation');
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: SingleChildScrollView(
        controller: controller,
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colors.primary, colors.surface],
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "gr0ve".capitalized,
                            style: text.displayLarge?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Navigate Your Day".capitalized,
                            style: text.titleLarge?.copyWith(
                              color: colors.onPrimary.withAlpha(210),
                              fontWeight: FontWeight.w700,
                              letterSpacing: getLetterSpacing(20, 10),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Text(
                              "Gr0ve simplifies your school day by showing teacher absences, class coverage, bus locations, and quick links in one clean, fast interface.",
                              textAlign: TextAlign.center,
                              style: text.bodyMedium?.copyWith(
                                color: colors.onPrimary.withAlpha(230),
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Material(
                              elevation: 8,
                              shadowColor: colors.primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              child: CustomPrimaryButton(
                                label: "Get Started".capitalized,
                                onTap: () => _onGetStarted(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: (MediaQuery.of(context).size.width - 52) / 2,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_circle_down_rounded,
                        size: 52,
                        color: colors.primary,
                      ),
                      onPressed: () {
                        controller.animateTo(
                          MediaQuery.of(context).size.height,
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                children: [
                  SafeArea(
                    top: true,
                    child: Column(
                      children: [
                        ...landingContent.map(
                          (item) => ShadowLandingCard(
                            title: item[0],
                            body: item[1],
                            shadowColor: colors.onSurface.withAlpha(12),
                          ),
                        ),
                        _ChangelogPager(changelogEntries: changelogEntries),
                        const SizedBox(height: 24),
                        Material(
                          elevation: 8,
                          shadowColor: colors.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          child: CustomPrimaryButton(
                            label: "Get Started".capitalized,
                            onTap: () => _onGetStarted(context),
                          ),
                        ),
                      ],
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

class _ChangelogPager extends StatefulWidget {
  final Map<String, String> changelogEntries;

  const _ChangelogPager({required this.changelogEntries});

  @override
  State<_ChangelogPager> createState() => _ChangelogPagerState();
}

class _ChangelogPagerState extends State<_ChangelogPager> {
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

class ShadowLandingCard extends StatelessWidget {
  final String title;
  final String body;
  final Color shadowColor;

  const ShadowLandingCard({
    super.key,
    required this.title,
    required this.body,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.capitalized,
            style: textStyles.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              letterSpacing: getLetterSpacing(12, 10),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: textStyles.bodyMedium?.copyWith(
              color: colors.onSurface.withAlpha(200),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
