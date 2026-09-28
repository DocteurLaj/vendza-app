import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/features/store/data/services/product_api_service.dart';

import 'fakes/memory_secure_storage.dart';

class _ProductListClient extends http.BaseClient {
  String? authorization;
  Uri? uri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    authorization = request.headers['Authorization'];
    uri = request.url;
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode({'products': []}))),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  test(
    'includeInactive product listing sends authenticated owner request',
    () async {
      final httpClient = _ProductListClient();
      final tokenStore = ApiTokenStore(storage: MemorySecureStorage());
      await tokenStore.saveTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh',
      );
      final service = ProductApiService(
        client: ApiClient(
          httpClient: httpClient,
          tokenStore: tokenStore,
          baseUrl: 'https://api.example.com/api/v1',
        ),
      );

      await service.productsForStore(42, includeInactive: true);

      expect(httpClient.uri?.queryParameters['include_inactive'], 'true');
      expect(httpClient.authorization, 'Bearer access-token');
    },
  );
}
