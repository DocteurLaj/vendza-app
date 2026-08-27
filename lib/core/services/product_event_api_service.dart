import 'dart:async';
import 'dart:math';

import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_token_store.dart';

final String productEventSessionId =
    'sess-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

class ProductEventApiService {
  ProductEventApiService({ApiClient? client, ApiTokenStore? tokenStore})
    : _client = client ?? apiClient,
      _tokenStore = tokenStore ?? apiTokenStore;

  final ApiClient _client;
  final ApiTokenStore _tokenStore;

  Future<void> track({
    required String eventType,
    required String productId,
    String? section,
    int? position,
    String? sessionId,
  }) async {
    final parsedId = int.tryParse(productId);
    if (parsedId == null) return;

    final authenticated = _tokenStore.hasAccessToken;
    await _client.post(
      ApiEndpoints.eventsProduct,
      authenticated: authenticated,
      body: {
        'product_id': parsedId,
        'event_type': eventType,
        if (!authenticated) 'session_id': sessionId ?? productEventSessionId,
        'section': ?section,
        'position': ?position,
      },
    );
  }

  void trackSafely({
    required String eventType,
    required String productId,
    String? section,
    int? position,
  }) {
    unawaited(
      Future(() async {
        try {
          await track(
            eventType: eventType,
            productId: productId,
            section: section,
            position: position,
          );
        } catch (_) {}
      }),
    );
  }
}

final productEventApiService = ProductEventApiService();
