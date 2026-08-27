import 'package:flutter/foundation.dart';

/// Optional Flutter error reporting hook.
///
/// No third-party DSN is bundled. When `VENDZA_SENTRY_DSN` is absent, errors
/// are logged locally only. Configure the provider in release ops before
/// claiming production monitoring readiness — see `docs/MONITORING.md`.
class ErrorReporter {
  const ErrorReporter._();

  static const String sentryDsn = String.fromEnvironment('VENDZA_SENTRY_DSN');

  static bool get isConfigured => sentryDsn.trim().isNotEmpty;

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      captureException(details.exception, stackTrace: details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      captureException(error, stackTrace: stack);
      return true;
    };

    if (!isConfigured && kReleaseMode) {
      debugPrint(
        'Vendza monitoring: VENDZA_SENTRY_DSN absent — Flutter errors are '
        'local-only until a provider is configured.',
      );
    }
  }

  static void captureException(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    final sanitized = _sanitize(context);
    if (kDebugMode) {
      debugPrint('Vendza error: $error');
      if (stackTrace != null) debugPrint('$stackTrace');
      if (sanitized.isNotEmpty) debugPrint('context=$sanitized');
    }
    // Provider SDK wiring (Sentry/etc.) is intentionally not hard-coded here
    // until a real DSN is supplied by ops.
  }

  static Map<String, Object?> _sanitize(Map<String, Object?> input) {
    const blocked = {
      'password',
      'token',
      'access_token',
      'refresh_token',
      'authorization',
      'id_token',
      'secret',
      'api_key',
    };
    return {
      for (final entry in input.entries)
        if (!blocked.contains(entry.key.toLowerCase())) entry.key: entry.value,
    };
  }
}
