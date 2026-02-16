import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';
import 'package:gr0ve/core/helper/teacher_utils.dart';
import 'package:gr0ve/features/privacy/privacy_policy.dart';

class CustomHeader extends StatelessWidget {
  final String title;

  const CustomHeader({super.key, required this.title});

  String _getSarcasticSubtitle(String title) {
    final t = title.toUpperCase();
    final user = FirebaseAuth.instance.currentUser?.displayName ?? "";
    if (t.contains('GR0VE')) return "LET'S TAKE A LOOK";
    if (t.contains('BUSES')) return "FINALLY LEAVING";
    if (t.contains('TEACHERS')) return "HOPE YOU HAVE A FREE!";
    if (t.contains('LUNCH')) return "\"FOOD\" THEY SAY";
    if (t.contains('CALENDAR')) return "STUFF YOU'LL PROBABLY MISS";
    if (t.contains('CLUBS')) return "SADLY SOCIAL";
    if (t.contains('GROUPS')) return "SADLY SOCIAL";
    if (t.contains('ACCOUNT')) return "WHO YOU ARE";
    if (t.contains('HELP')) return "WE GOT YOU";
    if (t.contains('PRIVACY POLICY'))
      return privacyPolicySections[0]["content"].toString();
    if (t.contains('TEACHERS')) return absenceList['date'] ?? "NO DATE FOUND";
    if (t.contains('PENDING GROUPS')) return "SADLY SOCIAL";
    if (t.contains('PENDING EVENTS')) return "SADLY SOCIAL";
    if (t.contains('LINKS')) return "HANDY LITTLE SHORTCUTS";
    if (t.contains('PENDING EVENTS')) return "SADLY SOCIAL";
    if (t.contains(user.capitalized)) return "NICE TO SEE YOU";
    return "FOR BCA";
  }

  @override
  Widget build(BuildContext context) {
    final displaySubtitle = _getSarcasticSubtitle(title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          displaySubtitle.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 4.0,
            color: context.colors.onSurface.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          title.toUpperCase(),
          style: context.text.displayLarge?.copyWith(
            fontSize: 48,
            height: 1.0,
            fontWeight: FontWeight.w900,
            color: context.colors.onSurface,
            letterSpacing: 2.0,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
