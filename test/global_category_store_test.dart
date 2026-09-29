import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/features/cathegory/data/services/category_store.dart'
    as category_store;

class _CategoryClient extends http.BaseClient {
  Uri? uri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            'success': true,
            'message': 'Operation reussie',
            'data': {
              'items': [
                {'id': 7, 'name': 'Electronique', 'is_active': true},
                {'id': 8, 'name': 'Cachee', 'is_active': false},
              ],
              'total': 2,
              'page': 1,
              'page_size': 100,
            },
          }),
        ),
      ),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  test(
    'refreshCategories loads active admin global catalog categories',
    () async {
      final httpClient = _CategoryClient();
      final client = ApiClient(
        httpClient: httpClient,
        baseUrl: 'https://api.example.com/api/v1',
      );

      await category_store.refreshCategories(client: client);

      expect(httpClient.uri?.path, '/api/v1/catalog/categories');
      expect(category_store.categories.map((item) => item.id), ['7']);
      expect(category_store.categories.single.name, 'Electronique');
    },
  );
}
