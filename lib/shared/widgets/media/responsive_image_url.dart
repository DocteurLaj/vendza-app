String responsiveImageUrl(
  String url, {
  double? width,
  double? height,
  double devicePixelRatio = 1,
}) {
  final trimmed = url.trim();
  if (!_looksLikeVendzaVariant(trimmed)) return trimmed;

  final dpr = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;
  final logicalMax = [width, height]
      .whereType<double>()
      .where((value) => value.isFinite && value > 0)
      .fold<double>(0, (max, value) => value > max ? value : max);
  if (logicalMax <= 0) return trimmed;

  final physicalMax = logicalMax * dpr;
  final variant = physicalMax <= 192
      ? 'thumb'
      : physicalMax <= 640
      ? 'card'
      : 'detail';
  return _replaceVariant(trimmed, variant);
}

bool _looksLikeVendzaVariant(String url) {
  return url.endsWith('/thumb.webp') ||
      url.endsWith('/card.webp') ||
      url.endsWith('/detail.webp') ||
      url.endsWith('/medium.webp') ||
      url.endsWith('/wide.webp');
}

String _replaceVariant(String url, String variant) {
  return url.replaceFirst(
    RegExp(r'/(thumb|card|detail|medium|wide)\.webp$'),
    '/$variant.webp',
  );
}
