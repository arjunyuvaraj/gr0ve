import 'package:flutter/material.dart';
import 'package:gr0ve/core/widgets/buttons/custom_secondary_button.dart';
import 'package:hugeicons/hugeicons.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0A0A0A), const Color(0xFF151515)]
                : [const Color(0xFFFAFAFA), const Color(0xFFF0F0F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          size: 20,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Credits',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCreditSection(
                        context,
                        title: 'DESIGN & ASSETS',
                        icon: HugeIcons.strokeRoundedPencilEdit02,
                        items: [
                          _CreditItem(
                            title: 'App Icons',
                            subtitle:
                                'Icons by Maks from Figma Community\nLicensed under CC BY 4.0',
                          ),
                          _CreditItem(
                            title: 'Icons',
                            subtitle:
                                'Icons by Hugeicons\nLicensed under CC BY 4.0',
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildCreditSection(
                        context,
                        title: 'COMMUNITY & TESTING',
                        icon: HugeIcons.strokeRoundedUserGroup,
                        items: [
                          _CreditItem(
                            title: 'Android Beta Testers',
                            subtitle:
                                'A special thanks to our 14 Android testers for their invaluable feedback and helping us squash bugs during early development.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildCreditSection(
                        context,
                        title: 'DEVELOPMENT',
                        icon: HugeIcons.strokeRoundedDeveloper,
                        items: [
                          _CreditItem(
                            title: 'The Grove Keeper',
                            subtitle:
                                'Built with passion for the BCA community.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: CustomSecondaryButton(
                  label: 'Back to Account',
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditSection(
    BuildContext context, {
    required String title,
    required List<List<dynamic>> icon,
    required List<_CreditItem> items,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 16,
              color: colors.primary.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: colors.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colors.onSurface.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.onSurface.withOpacity(0.06)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.value.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: colors.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.onSurface.withOpacity(0.05),
                      indent: 20,
                      endIndent: 20,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CreditItem {
  final String title;
  final String subtitle;
  const _CreditItem({required this.title, required this.subtitle});
}
