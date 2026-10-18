import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_token_store.dart';

/// Signals to the backend that the signed-in user is currently using the app,
/// so the Control Center can show who is online. The server keeps a presence
/// for 90 s, so a 30 s heartbeat while in the foreground keeps it fresh.
class PresenceService {
  PresenceService({
    ApiClient? client,
    ApiTokenStore? tokenStore,
    this.interval = const Duration(seconds: 30),
    String? platform,
  }) : _client = client ?? apiClient,
       _tokenStore = tokenStore ?? apiTokenStore,
       _platform = platform ?? _detectPlatform(),
       _sessionId = _newSessionId();

  final ApiClient _client;
  final ApiTokenStore _tokenStore;
  final Duration interval;
  final String _platform;
  final String _sessionId;
  Timer? _timer;
  bool _inFlight = false;
  String? path;

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    unawaited(beat());
    _timer = Timer.periodic(interval, (_) => unawaited(beat()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> beat() async {
    if (_inFlight || !_tokenStore.hasAccessToken) return;
    _inFlight = true;
    try {
      await _client.post(
        ApiEndpoints.presence,
        authenticated: true,
        body: {
          'platform': _platform,
          'app_version': '1.0.0',
          'session_id': _sessionId,
          if (path != null) 'path': path,
        },
        timeout: const Duration(seconds: 10),
      );
    } on Object {
      // Presence is best effort: never disturb the user experience.
    } finally {
      _inFlight = false;
    }
  }

  static String _detectPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return defaultTargetPlatform.name;
    }
  }

  static String _newSessionId() {
    final random = Random();
    return List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
  }
}

final presenceService = PresenceService();
