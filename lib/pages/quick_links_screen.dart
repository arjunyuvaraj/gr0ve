import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gr0ve/components/custom_header.dart';

class QuickLinksScreen extends StatelessWidget {
  QuickLinksScreen({super.key});

  final List<_QuickLink> links = [
    _QuickLink(
      title: "SCHOOLOGY",
      url: "https://bca.schoology.com/home#/?_k=1fxvnz",
      icon: Icons.school,
      color: Color(0xFF3B5998),
    ),
    _QuickLink(
      title: "GRADEBOOK",
      url: "https://bcts.powerschool.com/public/",
      icon: Icons.book,
      color: Color(0xFF00AEEF),
    ),
    _QuickLink(
      title: "TEACHER ABSENCE",
      url:
          "https://docs.google.com/document/d/e/2PACX-1vRkhySmwAiTtY88tcshckpV4F0vRrULccaGrYl_Sf2ubWpyyXA4l8c-KAOuMzSwFe-qyAQhLqXzVsbA/pub",
      icon: Icons.description,
      color: Color(0xFF4285F4),
    ),
    _QuickLink(
      title: "BUS LOCATIONS",
      url:
          "https://docs.google.com/spreadsheets/d/1S5v7kTbSiqV8GottWVi5tzpqLdTrEgWEY4ND4zvyV3o/edit?gid=0#gid=0",
      icon: Icons.directions_bus,
      color: Color(0xFF0F9D58),
    ),
    _QuickLink(
      title: "COUNSELOR BOOKING",
      url:
          "https://outlook.office365.com/book/CounselorBookings@bergen.org/?ismsaljsauthenabled=true",
      icon: Icons.event_available,
      color: Color(0xFFFFB900),
    ),
    _QuickLink(
      title: "PRIVACY POLICY",
      url: "/privacy_policy",
      icon: Icons.privacy_tip,
      color: Color(0xFF6A1B9A),
    ),
  ];

  Future<void> _openLink(BuildContext context, _QuickLink link) async {
    if (link.url.startsWith("/")) {
      Navigator.pushNamed(context, link.url);
    } else {
      final uri = Uri.parse(link.url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          const CustomHeader(
            title: "LINKS",
            subtitle: "Your favorite school pages, all in one place",
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                int columns = 1;
                if (constraints.maxWidth > 900) {
                  columns = 3;
                } else if (constraints.maxWidth > 600) {
                  columns = 2;
                }

                final cardWidth =
                    (constraints.maxWidth - (16 * (columns - 1))) / columns;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: links.map((link) {
                      return SizedBox(
                        width: cardWidth,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _openLink(context, link),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.onSurface.withAlpha(12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: link.color.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    link.icon,
                                    color: link.color,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    link.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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

class _QuickLink {
  final String title;
  final String url;
  final IconData icon;
  final Color color;

  const _QuickLink({
    required this.title,
    required this.url,
    required this.icon,
    required this.color,
  });
}
