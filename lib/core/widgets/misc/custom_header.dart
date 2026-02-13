import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const CustomHeader({super.key, required this.title, required this.subtitle});

  String _getSarcasticSubtitle(String title) {
    if (subtitle.isNotEmpty && subtitle != "FOR BCA") return subtitle;

    final t = title.toUpperCase();
    if (t.contains('GR0VE')) return "LET'S TAKE A LOOK";
    if (t.contains('BUSES')) return "FINALLY LEAVING?";
    if (t.contains('TEACHERS')) return "HOPE I HAVE A FREE!";
    if (t.contains('LUNCH')) return "IS IT EDIABLE";
    if (t.contains('CALENDAR')) return "STUFF YOU'LL PROBABLY MISS";
    if (t.contains('CLUBS')) return "SADLY SOCIAL";

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
