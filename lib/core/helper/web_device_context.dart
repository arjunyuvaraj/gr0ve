import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class WebDeviceContext {
  const WebDeviceContext._();

  static bool shouldUseDesktopDashboard(BuildContext context) {
    return kIsWeb && !isMobileWeb(context);
  }

  static bool isMobileWeb(BuildContext context) {
    if (!kIsWeb) return false;

    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return true;
    }

    final size = MediaQuery.maybeSizeOf(context);
    if (size == null) return false;

    final isDesktopPlatform =
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;
    return !isDesktopPlatform && size.shortestSide < 600;
  }
}
