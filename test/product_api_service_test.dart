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
  Map<String, dynamic>? body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    authorization = request.headers['Authorization'];
    uri = request.url;
    if (request is http.Request && request.body.isNotEmpty) {
      body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode({'products': []}))),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  ApiClient clientFor(_ProductListClient httpClient) {
    final tokenStore = ApiTokenStore(storage: MemorySecureStorage());
    tokenStore.saveTokens(accessToken: 'access-token', refreshToken: 'refresh');
    return ApiClient(
      httpClient: httpClient,
      tokenStore: tokenStore,
      baseUrl: 'https://api.example.com/api/v1',
    );
  }

  test(
    'includeInactive product listing sends authenticated owner request',
    () async {
      final httpClient = _ProductListClient();
      final service = ProductApiService(client: clientFor(httpClient));

      await service.productsForStore(42, includeInactive: true);

      expect(httpClient.uri?.queryParameters['include_inactive'], 'true');
      expect(httpClient.authorization, 'Bearer access-token');
    },
  );

  test('addProduct sends the selected global category id', () async {
    final httpClient = _ProductListClient();
    final service = ProductApiService(client: clientFor(httpClient));

    await service.addProduct(
      storeId: 42,
      title: 'Telephone',
      price: 120,
      stock: 3,
      catalogCategoryId: 7,
    );

    expect(httpClient.uri?.path, '/api/v1/product/add/42');
    expect(httpClient.body?['catalog_category_id'], 7);
    expect(httpClient.authorization, 'Bearer access-token');
  });

  test(
    'updateProduct sends category change and category clear explicitly',
    () async {
      final httpClient = _ProductListClient();
      final service = ProductApiService(client: clientFor(httpClient));

      await service.updateProduct(
        storeId: 42,
        productId: 11,
        catalogCategoryId: 8,
      );
      expect(httpClient.body?['catalog_category_id'], 8);

      await service.updateProduct(
        storeId: 42,
        productId: 11,
        catalogCategoryId: null,
        clearCatalogCategory: true,
      );
      expect(httpClient.body?.containsKey('catalog_category_id'), isTrue);
      expect(httpClient.body?['catalog_category_id'], isNull);
    },
  );
}
