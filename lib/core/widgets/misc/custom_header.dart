import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';
import 'package:gr0ve/core/helper/teacher_utils.dart';
import 'package:gr0ve/features/privacy_policy/privacy_policy.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const CustomHeader({super.key, required this.title, this.action});

  String _getSarcasticSubtitle(String title) {
    final t = title.toUpperCase();
    var user = "";
    try {
      user = FirebaseAuth.instance.currentUser?.displayName ?? "";
    } catch (_) {
      user = "";
    }

    if (t.contains('THE GR0VE')) return "WELCOME TO";
    if (t.contains('GR0VE')) return "LET'S TAKE A LOOK";
    if (t.contains('BUSES')) return "FINALLY LEAVING";
    if (t.contains('TEACHERS')) return "HOPE YOU HAVE A FREE!";
    if (t.contains('LUNCH')) return "\"FOOD\" THEY SAY";
    if (t.contains('CALENDAR')) return "STUFF YOU'LL PROBABLY MISS";
    if (t.contains('CLUBS')) return "BETTER TOGETHER";
    if (t.contains('GROUPS')) return "BETTER TOGETHER";
    if (t.contains('ACCOUNT')) return "WHO YOU ARE";
    if (t.contains('HELP')) return "WE GOT YOU";
    if (t.contains('PRIVACY POLICY'))
      return privacyPolicySections[0]["content"].toString();
    if (t.contains('TEACHERS')) return absenceList['date'] ?? "NO DATE FOUND";
    if (t.contains('PENDING GROUPS')) return "BETTER TOGETHER";
    if (t.contains('PENDING EVENTS')) return "BETTER TOGETHER";
    if (t.contains('LINKS')) return "HANDY LITTLE SHORTCUTS";
    if (t.contains('PENDING EVENTS')) return "SADLY SOCIAL";
    if (t.contains('NEWS')) return "Academy Chronicle".capitalized;
    if (user.isNotEmpty && t.contains(user.capitalized)) {
      return "NICE TO SEE YOU";
    }
    if (t.contains("GROVER")) return "STRUCTURED GUIDENCE".capitalized;
    if (t.contains("ASPEN")) return "Explore Your Path".capitalized;
    if (t.contains("ROWAN")) return "Practical Direction".capitalized;
    if (t.contains("SAKURA")) return "Creative Insight".capitalized;
    if (t.contains("AIBES")) return "I remember".capitalized;
    return "THE ALL IN ONE BCA APP";
  }

  @override
  Widget build(BuildContext context) {
    final displaySubtitle = _getSarcasticSubtitle(title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
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
              ],
            ),
            if (action != null) Positioned(right: 0, child: action!),
          ],
        ),
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
