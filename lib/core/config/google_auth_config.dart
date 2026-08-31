import 'package:flutter/foundation.dart';

class GoogleAuthConfig {
  const GoogleAuthConfig._();

  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Test-only override. Production code must leave this null.
  @visibleForTesting
  static bool? debugIsConfiguredOverride;

  static bool get isConfigured {
    final override = debugIsConfiguredOverride;
    if (override != null) return override;
    if (!_looksConfigured(webClientId)) {
      return false;
    }
    // On web, defaultTargetPlatform follows the browser OS (iPhone → iOS).
    // The web OAuth client is enough; do not also require the iOS client.
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return _looksConfigured(iosClientId);
    }
    return true;
  }

  static bool _looksConfigured(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    if (lower.contains('replace-with') ||
        lower.contains('example') ||
        lower.contains('your_')) {
      return false;
    }
    return trimmed.contains('.apps.googleusercontent.com');
  }
}
