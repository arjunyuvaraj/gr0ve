import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/widgets/buttons/custom_primary_button.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingWebsiteScreen extends StatelessWidget {
  const LandingWebsiteScreen({super.key});

  static const _androidUrl =
      'https://play.google.com/apps/testing/com.arjunyuvaraj.gr0ve';
  static const _iosUrl = 'https://apps.apple.com/us/app/gr0ve/id6755570512';

  static Future<void> _launch(String url) async {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.platformDefault,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App icon
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/app_icons/png/grover_${isDark ? 'dark' : 'light'}.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title — matches login screen's "GR0VE"
                  Text(
                    'GR0VE',
                    style: text.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle — matches login screen's "WELCOME BACK"
                  Text(
                    'ALL IN ONE BCA APP',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Short paragraph
                  Text(
                    'Teacher absences, bus arrivals, calendars, and more — all in one place for BCA students.',
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 44),

                  // Primary action — Log in
                  CustomPrimaryButton(
                    label: 'LOG IN',
                    onTap: () => Navigator.of(context).pushNamed('/login'),
                  ),
                  const SizedBox(height: 14),

                  // Secondary action — Sign up (outlined, matches app)
                  _OutlineButton(
                    label: 'SIGN UP',
                    onTap: () => Navigator.of(context).pushNamed('/register'),
                  ),
                  const SizedBox(height: 40),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: colors.onSurface.withOpacity(0.1),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'DOWNLOAD THE APP',
                          style: text.labelMedium?.copyWith(
                            letterSpacing: 1.2,
                            color: colors.onSurface.withOpacity(0.35),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: colors.onSurface.withOpacity(0.1),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Store buttons
                  Row(
                    children: [
                      Expanded(
                        child: _StoreButton(
                          label: 'App Store',
                          icon: Icons.apple_rounded,
                          onTap: () => _launch(_iosUrl),
                          isDark: isDark,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StoreButton(
                          label: 'Google Play',
                          icon: Icons.android_rounded,
                          onTap: () => _launch(_androidUrl),
                          isDark: isDark,
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary button that matches the app's visual system.
class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.onSurface.withOpacity(isDark ? 0.2 : 0.15),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: text.labelLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Store download button pill.
class _StoreButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme colors;

  const _StoreButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: colors.onSurface.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              label,
              style: text.labelLarge?.copyWith(
                color: colors.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
