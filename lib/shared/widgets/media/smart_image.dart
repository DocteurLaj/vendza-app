import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vendza/core/services/api_config.dart';

import 'smart_image_io.dart'
    if (dart.library.html) 'smart_image_web.dart'
    as local;

/// Shared image loader for assets, network, and local files.
///
/// Prefer constraining size with a parent [SizedBox] / [AspectRatio] and omit
/// [width]/[height] when possible. Never set both decode cache dims: that
/// stretches the bitmap before [fit] is applied.
class SmartImage extends StatelessWidget {
  const SmartImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.aspectRatio,
    this.errorWidget,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final double? borderRadius;
  final double? aspectRatio;
  final Widget? errorWidget;

  static bool isAssetPath(String value) => value.startsWith('assets/');

  static bool isNetworkPath(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('blob:');
  }

  static bool isHttpPath(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static Future<void> evict(String url) async {
    final rewritten = ApiConfig.rewriteMediaUrl(url);
    if (!isHttpPath(rewritten)) return;
    await CachedNetworkImage.evictFromCache(rewritten);
  }

  /// Pick a single mem-cache dimension so decode keeps aspect ratio.
  static ({int? width, int? height}) resolveMemCacheSize({
    required double? width,
    required double? height,
    required double devicePixelRatio,
  }) {
    final dpr = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;
    final w = width != null && width.isFinite ? (width * dpr).round() : null;
    final h = height != null && height.isFinite ? (height * dpr).round() : null;

    if (w == null && h == null) {
      return (width: null, height: null);
    }
    if (w != null && h != null) {
      return w >= h ? (width: w, height: null) : (width: null, height: h);
    }
    return (width: w, height: h);
  }

  @override
  Widget build(BuildContext context) {
    final trimmedPath = ApiConfig.rewriteMediaUrl(path.trim());
    final Widget fallback =
        errorWidget ??
        Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Theme.of(context).colorScheme.outline,
            size: 42,
          ),
        );

    if (trimmedPath.isEmpty) {
      return _wrap(fallback);
    }

    // Prefer parent constraints for decode sizing when width/height omitted.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cacheSourceW =
            width ??
            (constraints.hasBoundedWidth && constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : null);
        final cacheSourceH =
            height ??
            (constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null);

        final Widget image;
        if (isAssetPath(trimmedPath)) {
          image = Image.asset(
            trimmedPath,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            errorBuilder: (_, _, _) => fallback,
          );
        } else if (isHttpPath(trimmedPath) && !kIsWeb) {
          final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
          final cache = resolveMemCacheSize(
            width: cacheSourceW,
            height: cacheSourceH,
            devicePixelRatio: dpr,
          );

          image = CachedNetworkImage(
            imageUrl: trimmedPath,
            cacheKey: trimmedPath,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            memCacheWidth: cache.width,
            memCacheHeight: cache.height,
            fadeInDuration: const Duration(milliseconds: 120),
            fadeOutDuration: const Duration(milliseconds: 80),
            placeholder: (_, _) => Container(
              width: width,
              height: height,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            errorWidget: (_, _, _) => fallback,
          );
        } else if (isNetworkPath(trimmedPath) || kIsWeb) {
          image = Image.network(
            trimmedPath,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            errorBuilder: (_, _, _) => fallback,
          );
        } else {
          image = local.buildLocalImage(
            path: trimmedPath,
            width: width,
            height: height,
            fit: fit,
            fallback: fallback,
          );
        }

        return _wrap(image);
      },
    );
  }

  Widget _wrap(Widget child) {
    Widget result = child;

    if (aspectRatio != null && aspectRatio! > 0) {
      result = AspectRatio(
        aspectRatio: aspectRatio!,
        child: SizedBox.expand(child: result),
      );
    }

    if (borderRadius != null && borderRadius! > 0) {
      result = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: result,
      );
    }

    return result;
  }
}
