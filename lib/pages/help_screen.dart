import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_contact_card.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // Helper function to open URL
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomHeader(
              title: "Gr0ve".capitalized,
              subtitle: "Send us some feedback!".capitalized,
            ),
            const SizedBox(height: 16),
            CustomContactCard(
              title: "Got Feedback?",
              subtitle: "Fill out our feedback form! Click here!",
              color: context.colors.tertiary,
              textColor: context.colors.onTertiary,
              onTap: () {
                _launchUrl("https://forms.gle/Zrp2h8c8Sud24xPo6");
              },
            ),
            CustomContactCard(
              title: "Have a Question?",
              subtitle: "Send us an email at arjyuv29@bergen.org",
              color: context.colors.tertiary,
              textColor: context.colors.onTertiary,
              onTap: () {
                _launchUrl("mailto:arjyuv29@bergen.org");
              },
            ),
            CustomContactCard(
              title: "Know How To Code?",
              subtitle: "Check out our Github here!",
              color: context.colors.tertiary,
              textColor: context.colors.onTertiary,
              onTap: () {
                _launchUrl("https://github.com/arjunyuvaraj/gr0ve");
              },
            ),
            CustomContactCard(
              title: "Critical Security Issue?",
              subtitle: "Contact arjyuv29@bergen.org now",
              color: context.colors.tertiary,
              textColor: context.colors.onTertiary,
              onTap: () {
                _launchUrl("mailto:arjyuv29@bergen.org");
              },
            ),
          ],
        ),
      ),
    );
  }
}
