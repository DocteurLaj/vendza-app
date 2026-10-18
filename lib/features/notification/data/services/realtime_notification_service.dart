import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/services/api_config.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/features/notification/data/services/sse_parser.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/realtime_order_store.dart';

typedef RealtimeTokenRefresher = Future<bool> Function();
typedef RealtimeReconnectCallback = Future<void> Function();

/// Live notification/order stream over Server-Sent Events.
///
/// While a session exists (an access token is stored) the service keeps the
/// stream alive: a dropped connection, a non-2xx answer, a network error or a
/// silent connection (no heartbeat within [idleTimeout]) schedules a reconnect
/// with exponential backoff. A 401/403 first refreshes the access token through
/// [setTokenRefresher] and retries. After every *re*connection the inbox is
/// re-fetched (GET /notification/me) so events missed while offline appear.
class RealtimeNotificationService {
  RealtimeNotificationService({
    http.Client? httpClient,
    ApiTokenStore? tokenStore,
    String? baseUrl,
    RealtimeTokenRefresher? tokenRefresher,
    RealtimeReconnectCallback? onReconnected,
    this.initialBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
    this.idleTimeout = const Duration(seconds: 45),
  }) : _httpClient = httpClient ?? http.Client(),
       _tokenStore = tokenStore ?? apiTokenStore,
       _baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl,
       _tokenRefresher = tokenRefresher,
       _onReconnected = onReconnected ?? _refreshInboxAfterReconnect;

  final http.Client _httpClient;
  final ApiTokenStore _tokenStore;
  final String _baseUrl;
  RealtimeTokenRefresher? _tokenRefresher;
  final RealtimeReconnectCallback _onReconnected;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final Duration idleTimeout;

  final SseStreamParser _parser = SseStreamParser();
  StreamSubscription<String>? _subscription;
  Timer? _reconnectTimer;
  Timer? _idleTimer;
  bool _started = false;
  bool _connecting = false;
  bool _connected = false;
  bool _hasConnectedOnce = false;
  int _failures = 0;
  // Incremented on stop() and on each new connection so callbacks from an
  // abandoned connection can never act on the current one.
  int _generation = 0;

  /// True while the service is supposed to keep a stream open.
  bool get isStarted => _started;

  /// True while an HTTP stream is currently open.
  bool get isConnected => _connected;

  /// True when a reconnect attempt is scheduled.
  bool get hasPendingReconnect => _reconnectTimer?.isActive ?? false;

  /// Number of consecutive failed attempts (drives the backoff).
  int get consecutiveFailures => _failures;

  void setTokenRefresher(RealtimeTokenRefresher? refresher) {
    _tokenRefresher = refresher;
  }

  /// Delay before the reconnect attempt following [failures] failures.
  Duration backoffFor(int failures) {
    final exponent = math.max(0, failures - 1).clamp(0, 20);
    final millis = initialBackoff.inMilliseconds * math.pow(2, exponent);
    return Duration(
      milliseconds: math.min(millis.toInt(), maxBackoff.inMilliseconds),
    );
  }

  Future<void> start() async {
    if (!_tokenStore.hasAccessToken) return;
    if (_started) {
      // Already running: make sure a dead/backing-off stream is retried now.
      if (!_connected && !_connecting) {
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        await _connect(allowRefresh: true);
      }
      return;
    }
    _started = true;
    _failures = 0;
    await _connect(allowRefresh: true);
  }

  /// Called when the app returns to the foreground: sockets are often killed
  /// silently in the background, so force a fresh connection.
  Future<void> restart() async {
    if (!_tokenStore.hasAccessToken) {
      await stop();
      return;
    }
    if (_started && _connecting) return;
    final wasStarted = _started;
    await _closeConnection();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _started = true;
    _failures = 0;
    if (wasStarted) _hasConnectedOnce = true;
    await _connect(allowRefresh: true);
  }

  Future<void> stop() async {
    _started = false;
    _hasConnectedOnce = false;
    _failures = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _closeConnection();
  }

  void handleSseChunkForTest(String chunk) => _handleChunk(chunk);

  Future<void> _closeConnection() async {
    _generation++;
    _connected = false;
    _connecting = false;
    _idleTimer?.cancel();
    _idleTimer = null;
    final subscription = _subscription;
    _subscription = null;
    _parser.reset();
    await subscription?.cancel();
  }

  Future<void> _connect({required bool allowRefresh}) async {
    if (!_started || _connecting || _connected) return;
    if (!_tokenStore.hasAccessToken) {
      await stop();
      return;
    }
    _connecting = true;
    final generation = ++_generation;
    try {
      final request = http.Request(
        'GET',
        _uri(ApiEndpoints.notificationStream),
      );
      request.headers.addAll({
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Authorization': 'Bearer ${_tokenStore.accessToken}',
        if (_parser.lastEventId != null) 'Last-Event-ID': _parser.lastEventId!,
      });
      final response = await _httpClient.send(request);
      if (generation != _generation || !_started) {
        unawaited(_drain(response));
        return;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        unawaited(_drain(response));
        _connecting = false;
        final refresher = _tokenRefresher;
        if (allowRefresh && refresher != null) {
          bool refreshed;
          try {
            refreshed = await refresher();
          } on Object {
            refreshed = false;
          }
          if (generation != _generation || !_started) return;
          if (refreshed && _tokenStore.hasAccessToken) {
            await _connect(allowRefresh: false);
            return;
          }
        }
        if (!_tokenStore.hasAccessToken) {
          // The session is gone (refresh token rejected): stop for good.
          await stop();
          return;
        }
        _scheduleReconnect();
        return;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        unawaited(_drain(response));
        _connecting = false;
        _scheduleReconnect();
        return;
      }

      _connecting = false;
      _connected = true;
      _failures = 0;
      _parser.reset();
      _armIdleTimer(generation);
      _subscription = response.stream
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(
            (chunk) {
              if (generation != _generation) return;
              _armIdleTimer(generation);
              try {
                _handleChunk(chunk);
              } on Object {
                // A bad event must never tear the stream down.
              }
            },
            onError: (Object _) => _onConnectionLost(generation),
            onDone: () => _onConnectionLost(generation),
            cancelOnError: true,
          );
      final isReconnect = _hasConnectedOnce;
      _hasConnectedOnce = true;
      if (isReconnect) {
        unawaited(_onReconnected().catchError((Object _) {}));
      }
    } on Object {
      if (generation != _generation) return;
      _connecting = false;
      _connected = false;
      _scheduleReconnect();
    }
  }

  void _onConnectionLost(int generation) {
    if (generation != _generation) return;
    _connected = false;
    _idleTimer?.cancel();
    _idleTimer = null;
    _subscription = null;
    _generation++;
    _scheduleReconnect();
  }

  void _armIdleTimer(int generation) {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, () {
      if (generation != _generation) return;
      final subscription = _subscription;
      _onConnectionLost(generation);
      unawaited(subscription?.cancel());
    });
  }

  void _scheduleReconnect() {
    if (!_started) return;
    if (!_tokenStore.hasAccessToken) {
      unawaited(stop());
      return;
    }
    _failures++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(backoffFor(_failures), () {
      _reconnectTimer = null;
      unawaited(_connect(allowRefresh: true));
    });
  }

  Future<void> _drain(http.StreamedResponse response) async {
    try {
      await response.stream.drain<void>();
    } on Object {
      // Ignore.
    }
  }

  void _handleChunk(String chunk) {
    for (final message in _parser.add(chunk)) {
      try {
        if (message.event == 'notification') {
          _upsertNotification(message.data);
          continue;
        }
        if (_orderEvents.contains(message.event)) {
          upsertLiveOrder(OrderModel.fromJson(message.data));
        }
      } on Object {
        // Skip events whose payload does not match the expected model.
      }
    }
  }

  static const _orderEvents = {
    'order_created',
    'order_status_updated',
    'order_cancelled',
  };

  void _upsertNotification(Map<String, dynamic> data) {
    final notification = notificationFromApi(data);
    final existing = notificationStore.value;
    if (existing.any((item) => item.id == notification.id)) {
      notificationStore.value = existing
          .map((item) => item.id == notification.id ? notification : item)
          .toList(growable: false);
    } else {
      notificationStore.value = [notification, ...existing];
    }
  }

  Uri _uri(String path) {
    final normalizedBaseUrl = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBaseUrl$normalizedPath');
  }

  static Future<void> _refreshInboxAfterReconnect() async {
    final userId = currentUserStore.value.userId ?? 0;
    if (userId <= 0) return;
    await catalogRepository.refreshNotifications(userId, keepOnError: true);
  }
}

final realtimeNotificationService = RealtimeNotificationService();
