import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/helper/web_device_context.dart';
import 'package:gr0ve/core/widgets/images/remote_asset_image.dart';
import 'package:gr0ve/core/widgets/buttons/custom_primary_button.dart';
import 'package:gr0ve/features/landing/screens/landing_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AdaptiveWebLandingScreen extends StatelessWidget {
  const AdaptiveWebLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (WebDeviceContext.shouldUseDesktopDashboard(context)) {
      return const LandingWebsiteScreen();
    }

    return const LandingScreen();
  }
}

class LandingWebsiteScreen extends StatelessWidget {
  const LandingWebsiteScreen({super.key});

  static const _apkUrl =
      'https://github.com/arjunyuvaraj/gr0ve/releases/download/v2.5.0/gr0ve-v2.5.0.apk';
  static const _aabUrl =
      'https://github.com/arjunyuvaraj/gr0ve/releases/download/v2.5.0/gr0ve-v2.5.0.aab';

  static Future<void> _launch(String url, {String windowName = '_self'}) async {
    await launchUrl(
      Uri.base.resolve(url),
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: windowName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final device = _WebDeviceContext.from(context);

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
                      child: RemoteAssetImage(
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
                    onTap: () => _launch('/dashboard'),
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

                  _InstallPanel(colors: colors, device: device),
                  const SizedBox(height: 16),

                  // Direct downloads
                  Row(
                    children: [
                      Expanded(
                        child: _StoreButton(
                          label: 'APK',
                          icon: Icons.android_rounded,
                          onTap: () => _launch(_apkUrl, windowName: '_blank'),
                          isDark: isDark,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StoreButton(
                          label: 'AAB',
                          icon: Icons.inventory_2_rounded,
                          onTap: () => _launch(_aabUrl, windowName: '_blank'),
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

class _InstallPanel extends StatelessWidget {
  final ColorScheme colors;
  final _WebDeviceContext device;

  const _InstallPanel({required this.colors, required this.device});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = device.isDesktop
        ? Icons.install_desktop_rounded
        : device.isAndroid
        ? Icons.add_to_home_screen_rounded
        : Icons.ios_share_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.onSurface.withOpacity(0.72)),
              const SizedBox(width: 10),
              Text(
                device.installTitle,
                style: text.labelLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            device.installBody,
            style: text.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebDeviceContext {
  final bool isAndroid;
  final bool isDesktop;
  final String installTitle;
  final String installBody;

  const _WebDeviceContext({
    required this.isAndroid,
    required this.isDesktop,
    required this.installTitle,
    required this.installBody,
  });

  factory _WebDeviceContext.from(BuildContext context) {
    final platform = defaultTargetPlatform;
    final size = MediaQuery.sizeOf(context);
    final isPhoneLayout = size.shortestSide < 600;
    final isAndroid = platform == TargetPlatform.android && isPhoneLayout;
    final isIos = platform == TargetPlatform.iOS && isPhoneLayout;

    if (isIos) {
      return const _WebDeviceContext(
        isAndroid: false,
        isDesktop: false,
        installTitle: 'iPhone and iPad',
        installBody:
            'Open this site in Safari, tap Share, then Add to Home Screen.',
      );
    }

    if (isAndroid) {
      return const _WebDeviceContext(
        isAndroid: true,
        isDesktop: false,
        installTitle: 'Android phone',
        installBody:
            'Open this site in Chrome, tap the menu, then choose Install App or Add to Home screen.',
      );
    }

    if (isPhoneLayout) {
      return const _WebDeviceContext(
        isAndroid: false,
        isDesktop: false,
        installTitle: 'Phone browser',
        installBody:
            'Use your browser menu to install gr0ve to your home screen.',
      );
    }

    return const _WebDeviceContext(
      isAndroid: false,
      isDesktop: true,
      installTitle: 'Computer browser',
      installBody:
          'Use the install icon in Chrome, Edge, or another PWA-ready desktop browser.',
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            Icon(icon, size: 18, color: colors.onSurface.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              label,
              style: text.labelMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.78),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
