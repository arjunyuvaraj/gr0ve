import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    final basePersonas = [
      CounselorPersona.grover,
      CounselorPersona.aspen,
      CounselorPersona.rowan,
      CounselorPersona.sakura,
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          const CustomHeader(title: "CHANGELOG"),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                // Version header with overlapping avatars
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withOpacity(0.15),
                        colors.primary.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Version 2.0.0',
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Overlapping Avatars
                          SizedBox(
                            height: 36,
                            width: 36.0 + (3 * 24.0),
                            child: Stack(
                              children: List.generate(basePersonas.length, (
                                index,
                              ) {
                                return Positioned(
                                  right: index * 24.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.surface,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        basePersonas[basePersonas.length -
                                                1 -
                                                index]
                                            .avatarAsset(
                                              Theme.of(context).brightness,
                                            ),
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'A whole new look & feel.',
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ve completely redesigned the entire app to make it faster, smoother, and more beautiful than ever. Here is what\'s new.',
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurface.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Feature 1
                _buildFeatureCard(
                  context: context,
                  icon: HugeIcons.strokeRoundedTime03,
                  title: 'Time-Adaptive Home',
                  description:
                      'Your dashboard now automatically adapts its layout based on the time of day: morning, school hours, and evening.',
                  color: CounselorPersona.grover.primary(
                    Theme.of(context).brightness,
                  ),
                ),

                // Feature 2
                _buildFeatureCard(
                  context: context,
                  icon: HugeIcons.strokeRoundedGridView,
                  title: 'Customizable Navigation',
                  description:
                      'Reorder and hide navigation tabs to create a personalized experience that perfectly fits your daily needs.',
                  color: CounselorPersona.aspen.primary(
                    Theme.of(context).brightness,
                  ),
                ),

                // Feature 3
                _buildFeatureCard(
                  context: context,
                  icon: HugeIcons.strokeRoundedCalendar03,
                  title: 'All-New Calendar',
                  description:
                      'A completely rebuilt calendar page to track your schedule, events, and assignments effortlessly in one place.',
                  color: CounselorPersona.rowan.primary(
                    Theme.of(context).brightness,
                  ),
                ),

                // Feature 4
                _buildFeatureCard(
                  context: context,
                  icon: HugeIcons.strokeRoundedUserCircle,
                  title: 'Profile Pictures & More',
                  description:
                      'Personalize your account with expressive avatars. Who knows? You might even discover some hidden characters.',
                  color: CounselorPersona.sakura.primary(
                    Theme.of(context).brightness,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required dynamic icon,
    required String title,
    required String description,
    required Color color,
    Widget? bottomWidget,
  }) {
    final colors = context.colors;
    final text = context.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(icon: icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: text.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
              height: 1.4,
            ),
          ),
          if (bottomWidget != null) ...[
            const SizedBox(height: 16),
            bottomWidget,
          ],
        ],
      ),
    );
  }
}
