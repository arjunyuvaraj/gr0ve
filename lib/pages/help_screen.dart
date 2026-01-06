import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_contact_card.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CustomHeader(
                  title: "FEEDBACK",
                  subtitle: "Questions, ideas, or problems",
                ),

                const SizedBox(height: 24),

                CustomContactCard(
                  title: "Share Feedback",
                  subtitle: "Suggest features or report issues",
                  icon: Icons.feedback_rounded,
                  onTap: () {
                    _launchUrl("https://forms.gle/Zrp2h8c8Sud24xPo6");
                  },
                ),

                CustomContactCard(
                  title: "Ask a Question",
                  subtitle: "Email the developer directly",
                  icon: Icons.email_rounded,
                  onTap: () {
                    _launchUrl("mailto:arjyuv29@bergen.org");
                  },
                ),

                CustomContactCard(
                  title: "View the Source",
                  subtitle: "Explore gr0ve on GitHub",
                  icon: Icons.code_rounded,
                  onTap: () {
                    _launchUrl("https://github.com/arjunyuvaraj/gr0ve");
                  },
                ),

                const SizedBox(height: 12),

                CustomContactCard(
                  title: "Security Concern",
                  subtitle: "Urgent or sensitive issue",
                  icon: Icons.warning_rounded,
                  isDestructive: true,
                  onTap: () {
                    _launchUrl("mailto:arjyuv29@bergen.org");
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
