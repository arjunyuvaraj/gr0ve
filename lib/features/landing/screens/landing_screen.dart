import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/features/changelog/widgets/changelog_pager.dart';
import 'package:gr0ve/core/widgets/buttons/custom_primary_button.dart';
import 'package:gr0ve/features/landing/widgets/landing_card.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/features/changelog/data/changelog_entries.dart';
import 'package:gr0ve/core/constants/landing_content.dart';
import 'package:gr0ve/core/helper/helper_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();
    final colors = context.colors;
    final text = context.text;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    Future<void> _onGetStarted(BuildContext context) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('landing_seen', true);
      Navigator.of(context).pushReplacementNamed('/navigation');
    }

    void _onLogin(BuildContext context) {
      Navigator.of(context).pushNamed('/login');
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
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
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
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
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      SafeArea(
                        top: true,
                        child: Column(
                          children: [
                            ...landingContent.map(
                              (item) => LandingCard(
                                title: item[0],
                                body: item[1],
                                shadowColor: colors.onSurface.withAlpha(12),
                              ),
                            ),
                            ChangelogPager(changelogEntries: changelogEntries),
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

          if (!isLoggedIn)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Material(
                elevation: 4,
                shadowColor: colors.onSurface.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _onLogin(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.primary, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.login_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Login",
                          style: text.titleSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
