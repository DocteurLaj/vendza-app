import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/product_event_api_service.dart';
import 'package:vendza/core/services/api_token_store.dart';

import 'fakes/memory_secure_storage.dart';

class _ThrowingApiClient extends ApiClient {
  @override
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
    Duration? timeout,
  }) async {
    throw const ApiException(message: 'network down');
  }
}

class _RecordingApiClient extends ApiClient {
  Map<String, dynamic>? lastBody;
  String? lastPath;

  @override
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
    Duration? timeout,
  }) async {
    lastPath = path;
    lastBody = body;
    return {
      'success': true,
      'data': {'recorded': true},
    };
  }
}

void main() {
  test('trackSafely swallows API failures', () async {
    final service = ProductEventApiService(
      client: _ThrowingApiClient(),
      tokenStore: ApiTokenStore(storage: MemorySecureStorage()),
    );

    expect(
      () => service.trackSafely(
        eventType: 'product_open',
        productId: '12',
        section: 'trending',
        position: 1,
      ),
      returnsNormally,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });

  test('track sends product_id and anonymous session', () async {
    final apiClient = _RecordingApiClient();
    final service = ProductEventApiService(
      client: apiClient,
      tokenStore: ApiTokenStore(storage: MemorySecureStorage()),
    );

    await service.track(
      eventType: 'contact_click',
      productId: '44',
      section: 'popular',
      position: 2,
    );

    expect(apiClient.lastPath, '/events/product');
    expect(apiClient.lastBody?['product_id'], 44);
    expect(apiClient.lastBody?['event_type'], 'contact_click');
    expect(apiClient.lastBody?['session_id'], isNotNull);
    expect(apiClient.lastBody?['section'], 'popular');
    expect(apiClient.lastBody?['position'], 2);
  });
}
