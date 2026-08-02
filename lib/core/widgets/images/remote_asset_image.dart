import 'package:flutter/material.dart';

class RemoteAssetCatalog {
  static const String baseUrl = String.fromEnvironment(
    'GR0VE_REMOTE_ASSET_BASE_URL',
    defaultValue: 'https://gr0ve-bca.web.app/remote_assets/v1',
  );

  static const List<String> _remotePrefixes = [
    'assets/profile/',
    'assets/story/',
    'assets/app_icons/png/',
    'assets/field_day/',
  ];

  static bool canLoadRemotely(String assetPath) {
    final normalized = _normalize(assetPath);
    if (!normalized.toLowerCase().endsWith('.png')) return false;
    return _remotePrefixes.any(normalized.startsWith);
  }

  static String urlFor(String assetPath) {
    final normalized = _normalize(assetPath);
    final hostedPath = normalized
        .replaceFirst(RegExp(r'^assets/'), '')
        .replaceFirst(RegExp(r'\.png$', caseSensitive: false), '.webp');
    final encodedPath = hostedPath
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    return '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/$encodedPath';
  }

  static String _normalize(String assetPath) {
    return assetPath.startsWith('/') ? assetPath.substring(1) : assetPath;
  }
}

class RemoteAssetImage extends StatelessWidget {
  static const String placeholderAsset = 'assets/remote_placeholder.png';

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final Color? color;
  final BlendMode? colorBlendMode;
  final FilterQuality filterQuality;
  final ImageErrorWidgetBuilder? errorBuilder;
  final String fallbackAsset;

  const RemoteAssetImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode,
    this.filterQuality = FilterQuality.medium,
    this.errorBuilder,
    this.fallbackAsset = placeholderAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (!RemoteAssetCatalog.canLoadRemotely(assetPath)) {
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        colorBlendMode: colorBlendMode,
        filterQuality: filterQuality,
        errorBuilder: errorBuilder,
      );
    }

    return Image.network(
      RemoteAssetCatalog.urlFor(assetPath),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      filterQuality: filterQuality,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _fallback(context);
      },
      errorBuilder: (context, error, stackTrace) {
        final builder = errorBuilder;
        if (builder != null) return builder(context, error, stackTrace);
        return _fallback(context);
      },
    );
  }

  Widget _fallback(BuildContext context) {
    return Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      filterQuality: filterQuality,
    );
  }
}
