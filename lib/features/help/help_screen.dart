import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/features/changelog/data/changelog_entries.dart';
import 'package:gr0ve/features/changelog/widgets/changelog_pager.dart';
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

    final currentAnnouncement =
        "Welcome to gr0ve! Please update the app and login to make the most of the app!";

    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
      child: Column(
        children: [
          const CustomHeader(title: "HELP"),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Announcement card
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.campaign_rounded,
                            color: colors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Announcements",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: colors.primary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentAnnouncement,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.onSurface.withOpacity(0.75),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contact options
                  Text(
                    "GET IN TOUCH",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface.withOpacity(0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Feedback card
                  _buildActionCard(
                    context,
                    icon: Icons.feedback_rounded,
                    iconColor: colors.primary,
                    title: "Share Feedback",
                    subtitle: "Help us improve gr0ve with your suggestions",
                    onTap: () =>
                        _launchUrl("https://forms.gle/Zrp2h8c8Sud24xPo6"),
                  ),

                  const SizedBox(height: 10),

                  // Email card
                  _buildActionCard(
                    context,
                    icon: Icons.email_rounded,
                    iconColor: colors.primary,
                    title: "Email Support",
                    subtitle: "grove.bca@gmail.com",
                    onTap: () => _launchUrl("mailto:grove.bca@gmail.com"),
                  ),

                  const SizedBox(height: 10),

                  // Security card
                  _buildActionCard(
                    context,
                    icon: Icons.shield_rounded,
                    iconColor: colors.error,
                    title: "Report Security Issue",
                    subtitle: "Found a vulnerability? Let us know",
                    onTap: () => _launchUrl("mailto:grove.bca@gmail.com"),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withOpacity(0.6),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colors.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
