import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/changelog/widgets/changelog_pager.dart';
import 'package:gr0ve/core/widgets/buttons/custom_primary_button.dart';
import 'package:gr0ve/core/widgets/buttons/download_button.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/features/changelog/data/changelog_entries.dart';
import 'package:gr0ve/core/helper/helper_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
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
                          constraints: BoxConstraints(
                            maxWidth: isMobile ? 360 : 480,
                          ),
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
                          width: isMobile ? double.infinity : 360,
                          child: Column(
                            children: [
                              Material(
                                elevation: 8,
                                shadowColor: colors.primary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                child: CustomPrimaryButton(
                                  label: "Get Started",
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/navigation',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              isMobile
                                  ? Column(
                                      children: [
                                        Material(
                                          elevation: 4,
                                          shadowColor: colors.surface
                                              .withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: DownloadButton(
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
                                        const SizedBox(height: 12),
                                        Material(
                                          elevation: 4,
                                          shadowColor: colors.surface
                                              .withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: DownloadButton(
                                            label: "iOS",
                                            icon: Icons.apple,
                                            onTap: () {
                                              launchUrl(
                                                Uri.parse(
                                                  'https://apps.apple.com/us/app/gr0ve/id6755570512',
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: Material(
                                            elevation: 4,
                                            shadowColor: colors.surface
                                                .withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: DownloadButton(
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
                                            shadowColor: colors.surface
                                                .withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: DownloadButton(
                                              label: "iOS",
                                              icon: Icons.apple,
                                              onTap: () {
                                                launchUrl(
                                                  Uri.parse(
                                                    'https://apps.apple.com/us/app/gr0ve/id6755570512',
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: 12),
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
      ),
    );
  }
}
