import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/data/landing_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();
    final colors = context.colors;

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
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "gr0ve".capitalized,
                            style: context.text.displayLarge?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            "Navigate Your Day".capitalized,
                            style: context.text.displaySmall?.copyWith(
                              color: colors.onPrimary.withAlpha(200),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: CustomPrimaryButton(
                              label: "Get Started".capitalized,
                              onTap: () => _onGetStarted(context),
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

            SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    ...landingContent.map(
                      (item) => ShadowLandingCard(
                        title: item[0],
                        body: item[1],
                        shadowColor: colors.onSurface.withAlpha(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomPrimaryButton(
                      label: "Get Started".capitalized,
                      onTap: () => _onGetStarted(context),
                    ),
                  ],
                ),
              ),
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
            style: textStyles.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: textStyles.bodyMedium?.copyWith(height: 1.45),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
