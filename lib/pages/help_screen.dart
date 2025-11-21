import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_contact_card.dart';
import 'package:gr0ve/utilities/context_extensions.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomContactCard(
          title: "Got Feedback?",
          subtitle: "Fill out our feedback form! Click here!",
          color: context.colors.primary,
          textColor: context.colors.onPrimary,
        ),
        CustomContactCard(
          title: " Have a Question?",
          subtitle: "Send us an email at arjyuv29@bergen.org",
          color: Color(0xFF386BD9),
          textColor: context.colors.onPrimary,
        ),
        CustomContactCard(
          title: "Know How To Code?s",
          subtitle: "Check at our Github here!",
          color: context.colors.onSurface,
          textColor: context.colors.surface,
        ),
        CustomContactCard(
          title: "Critical Security Issue?",
          subtitle: "Contact arjyuv29@bergen.org now",
          color: context.colors.error,
          textColor: context.colors.onError,
        ),
      ],
    );
  }
}
