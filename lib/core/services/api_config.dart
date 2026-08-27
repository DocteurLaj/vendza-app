import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const String _fromEnvironment = String.fromEnvironment(
    'VENDZA_API_BASE_URL',
  );

  static const Duration defaultTimeout = Duration(seconds: 20);

  /// Resolved API base URL for the current build mode.
  ///
  /// Release builds require an HTTPS public URL via `VENDZA_API_BASE_URL`.
  /// Debug builds may fall back to the Android emulator loopback.
  static String get defaultBaseUrl {
    if (kReleaseMode) {
      return _requireReleaseBaseUrl();
    }
    if (_fromEnvironment.trim().isEmpty) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return _fromEnvironment.trim();
  }

  /// Rewrites local MinIO hosts so USB (`adb reverse`) and emulator builds
  /// can load images stored as `localhost` / `minio` URLs.
  static String rewriteMediaUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || kReleaseMode) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return trimmed;

    const localHosts = {'localhost', 'minio', 'host.docker.internal'};
    if (!localHosts.contains(uri.host.toLowerCase())) return trimmed;

    final apiUri = Uri.tryParse(defaultBaseUrl);
    final replacementHost = (apiUri != null && apiUri.host.isNotEmpty)
        ? apiUri.host
        : '127.0.0.1';
    return uri.replace(host: replacementHost).toString();
  }

  /// Fails fast in release when the API URL is missing or unsafe.
  static void validateForCurrentBuild() {
    if (kReleaseMode) {
      _requireReleaseBaseUrl();
    }
  }

  static String _requireReleaseBaseUrl() {
    final raw = _fromEnvironment.trim();
    if (raw.isEmpty) {
      throw StateError(
        'VENDZA_API_BASE_URL est obligatoire en release '
        '(HTTPS public, pas de localhost).',
      );
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('VENDZA_API_BASE_URL est invalide: $raw');
    }
    if (uri.scheme.toLowerCase() != 'https') {
      throw StateError(
        'VENDZA_API_BASE_URL doit utiliser HTTPS en release (reçu: ${uri.scheme}).',
      );
    }
    if (_isDisallowedReleaseHost(uri.host)) {
      throw StateError(
        'VENDZA_API_BASE_URL ne peut pas pointer vers un hôte local/privé '
        'en release (${uri.host}).',
      );
    }
    return raw;
  }

  static bool _isDisallowedReleaseHost(String host) {
    final normalized = host.toLowerCase();
    if (normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '0.0.0.0' ||
        normalized == '10.0.2.2' ||
        normalized == '::1') {
      return true;
    }

    final parts = normalized.split('.');
    if (parts.length == 4 &&
        parts.every((part) => int.tryParse(part) != null)) {
      final a = int.parse(parts[0]);
      final b = int.parse(parts[1]);
      if (a == 10) return true;
      if (a == 192 && b == 168) return true;
      if (a == 172 && b >= 16 && b <= 31) return true;
    }
    return false;
  }
}
