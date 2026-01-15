import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/components/changelog_pager.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/data/changelog_entries.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    final currentAnnouncement =
        "Welcome to gr0ve! Please update the app and login to make the most of the app! ";

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(16, 16, 16, 0),
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CustomHeader(
                        title: "HELP",
                        subtitle: "Questions, ideas, or problems",
                      ),

                      const SizedBox(height: 24),

                      Material(
                        elevation: 4,
                        shadowColor: colors.surface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            boxShadow: [
                              BoxShadow(
                                color: colors.onSurface.withAlpha(12),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.campaign_rounded,
                                color: colors.onSurface,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Announcements",
                                      style: text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentAnnouncement,
                                      style: text.bodyMedium?.copyWith(
                                        color: colors.onSurface.withAlpha(200),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: [
                          _buildGridCard(
                            context,
                            icon: Icons.feedback_rounded,
                            title: "Feedback",
                            subtitle: "Suggest features",
                            onTap: () => _launchUrl(
                              "https://forms.gle/Zrp2h8c8Sud24xPo6",
                            ),
                          ),
                          _buildGridCard(
                            context,
                            icon: Icons.email_rounded,
                            title: "Questions",
                            subtitle: "Email us",
                            onTap: () =>
                                _launchUrl("mailto:grove.bca@gmail.com"),
                          ),
                          _buildGridCard(
                            context,
                            icon: Icons.warning_rounded,
                            title: "Security",
                            subtitle: "Report issue",
                            isDestructive: true,
                            onTap: () =>
                                _launchUrl("mailto:grove.bca@gmail.com"),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const SizedBox(height: 16),

                      ChangelogPager(changelogEntries: changelogEntries),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colors = context.colors;
    final text = context.text;

    return Material(
      elevation: 2,
      shadowColor: colors.surface.withOpacity(0.2),
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.onSurface.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isDestructive ? colors.error : colors.primary,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? colors.error : colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
