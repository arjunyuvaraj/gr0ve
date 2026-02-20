import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/changelog/widgets/changelog_pager.dart';
import 'package:gr0ve/core/widgets/buttons/custom_primary_button.dart';
import 'package:gr0ve/core/widgets/buttons/download_button.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/features/changelog/data/changelog_entries.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingWebsiteScreen extends StatelessWidget {
  const LandingWebsiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = context.text;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary.withOpacity(0.05),
                    colors.surface,
                    colors.surface,
                    colors.secondary.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),

          // Decorative Blobs
          Positioned(
            top: -100,
            right: -100,
            child: _GlowBlob(
              color: colors.primary.withOpacity(0.15),
              size: 400,
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _GlowBlob(
              color: colors.secondary.withOpacity(0.1),
              size: 300,
            ),
          ),

          // Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final isTablet =
                    constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 64,
                    vertical: 64,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        children: [
                          // Hero Section
                          _GlassContainer(
                            padding: EdgeInsets.all(isMobile ? 32 : 64),
                            child: Column(
                              children: [
                                Text(
                                  "gr0ve".toUpperCase(),
                                  style: text.displayLarge?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 8,
                                    fontSize: isMobile ? 48 : 72,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Navigate Your Day".toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: text.displaySmall?.copyWith(
                                    color: colors.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    letterSpacing: 4,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 600,
                                  ),
                                  child: Text(
                                    "Gr0ve simplifies your school day by showing teacher absences, class coverage, bus locations, and quick links in one clean, fast interface. Plan your day with ease and confidence.",
                                    textAlign: TextAlign.center,
                                    style: text.bodyLarge?.copyWith(
                                      color: colors.onSurface.withOpacity(0.8),
                                      height: 1.6,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 48),
                                _BuildButtons(isMobile: isMobile),
                              ],
                            ),
                          ),

                          const SizedBox(height: 64),

                          // Features Grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 24,
                            childAspectRatio: 1.4,
                            children: const [
                              _FeatureCard(
                                icon: Icons.person_off_rounded,
                                title: "Teacher Absences",
                                description:
                                    "Real-time updates on teacher absences and class coverage.",
                              ),
                              _FeatureCard(
                                icon: Icons.directions_bus_rounded,
                                title: "Bus Tracking",
                                description:
                                    "Live bus locations and ETA to keep you on schedule.",
                              ),
                              _FeatureCard(
                                icon: Icons.restaurant_menu_rounded,
                                title: "Lunch Menu",
                                description:
                                    "Check what's for lunch today with a single tap.",
                              ),
                              _FeatureCard(
                                icon: Icons.announcement_rounded,
                                title: "Club Updates",
                                description:
                                    "Stay connected with your clubs and school organizations.",
                              ),
                              _FeatureCard(
                                icon: Icons.star_rounded,
                                title: "Favorites",
                                description:
                                    "Star your teachers for personalized daily highlights.",
                              ),
                              _FeatureCard(
                                icon: Icons.bolt_rounded,
                                title: "Light Speed",
                                description:
                                    "Optimized for performance and zero-clutter navigation.",
                              ),
                            ],
                          ),

                          const SizedBox(height: 64),

                          // Changelog Section
                          _GlassContainer(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "What's New",
                                      style: text.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                ChangelogPager(
                                  changelogEntries: changelogEntries,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassContainer({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colors.onSurface.withOpacity(0.05)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.8,
            spreadRadius: size * 0.2,
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = context.text;

    return _GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 28),
          ),
          const Spacer(),
          Text(
            title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: text.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BuildButtons extends StatelessWidget {
  final bool isMobile;

  const _BuildButtons({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          CustomPrimaryButton(
            label: "Open Gr0ve Web",
            onTap: () => Navigator.pushNamed(context, '/navigation'),
          ),
          const SizedBox(height: 16),
          if (isMobile)
            Column(
              children: [
                DownloadButton(
                  label: "Google Play",
                  icon: Icons.android,
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://play.google.com/apps/testing/com.arjunyuvaraj.gr0ve',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DownloadButton(
                  label: "App Store",
                  icon: Icons.apple,
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://apps.apple.com/us/app/gr0ve/id6755570512',
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: DownloadButton(
                    label: "Android",
                    icon: Icons.android,
                    onTap: () => launchUrl(
                      Uri.parse(
                        'https://play.google.com/apps/testing/com.arjunyuvaraj.gr0ve',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DownloadButton(
                    label: "iOS",
                    icon: Icons.apple,
                    onTap: () => launchUrl(
                      Uri.parse(
                        'https://apps.apple.com/us/app/gr0ve/id6755570512',
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
