import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/components/landing_card.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:gr0ve/utilities/data/landing_content.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();

    return Scaffold(
      body: SingleChildScrollView(
        controller: controller,
        child: Column(
          children: [
            // BANNER: Main Title
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  Image.asset(
                    'assets/landing_background_light.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(64.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "gr0ve".capitalized,
                            style: context.text.displayLarge,
                          ),
                          Text(
                            "For BCA".capitalized,
                            style: context.text.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 600),
                            child: CustomPrimaryButton(
                              label: "Sign In".capitalized,
                              onTap: () =>
                                  Navigator.pushNamed(context, "/login"),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, "/navigation"),
                            child: Text(
                              "Or contuine without an account".capitalized,
                              textAlign: TextAlign.center,
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
                        color: context.colors.primary,
                        size: 52,
                      ),
                      onPressed: () {
                        controller.animateTo(
                          MediaQuery.of(context).size.height,
                          duration: Duration(milliseconds: 1000),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // MAIN: Content and Call to Action
            SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    ...landingContent.map(
                      (item) => LandingCard(title: item[0], body: item[1]),
                    ),
                    CustomPrimaryButton(
                      label: "Sign In".capitalized,
                      onTap: () => Navigator.pushNamed(context, "/login"),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      child: Text("Privacy Policy".capitalized),
                      onPressed: () =>
                          Navigator.pushNamed(context, "/privacy_policy"),
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
