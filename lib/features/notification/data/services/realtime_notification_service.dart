import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/services/api_config.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/features/notification/data/services/sse_parser.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/realtime_order_store.dart';

class RealtimeNotificationService {
  RealtimeNotificationService({
    http.Client? httpClient,
    ApiTokenStore? tokenStore,
    String? baseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _tokenStore = tokenStore ?? apiTokenStore,
       _baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl;

  final http.Client _httpClient;
  final ApiTokenStore _tokenStore;
  final String _baseUrl;

  StreamSubscription<String>? _subscription;
  bool _started = false;

  bool get isStarted => _started;

  Future<void> start() async {
    if (_started || !_tokenStore.hasAccessToken) return;
    _started = true;
    try {
      final request = http.Request(
        'GET',
        _uri(ApiEndpoints.notificationStream),
      );
      request.headers.addAll({
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Authorization': 'Bearer ${_tokenStore.accessToken}',
      });
      final response = await _httpClient.send(request);
      if (response.statusCode == 401 || response.statusCode == 403) {
        await stop();
        return;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await stop();
        return;
      }
      _subscription = response.stream
          .transform(utf8.decoder)
          .listen(_handleChunk, onError: (_) => stop(), onDone: () => stop());
    } on Object {
      await stop();
    }
  }

  Future<void> stop() async {
    _started = false;
    await _subscription?.cancel();
    _subscription = null;
  }

  void handleSseChunkForTest(String chunk) => _handleChunk(chunk);

  void _handleChunk(String chunk) {
    for (final message in parseSseMessages(chunk)) {
      if (message.event == 'notification') {
        _upsertNotification(message.data);
        continue;
      }
      if (_orderEvents.contains(message.event)) {
        upsertLiveOrder(OrderModel.fromJson(message.data));
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
}

final realtimeNotificationService = RealtimeNotificationService();
