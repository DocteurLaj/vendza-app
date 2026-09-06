import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/services/upload_api_service.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';

import 'fakes/memory_secure_storage.dart';

class _UploadFlowClient extends http.BaseClient {
  final requests = <String>[];
  String? completeBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add('${request.method} ${request.url}');

    if (request.url.host == 'storage.example.com') {
      await request.finalize().drain<void>();
      return _response('', 204);
    }

    if (request.url.path.endsWith(ApiEndpoints.authBecomeSeller)) {
      return _jsonResponse({'ok': true});
    }

    if (request.url.path.endsWith(ApiEndpoints.uploadImagePresign)) {
      return _jsonResponse({
        'upload': {
          'url': 'https://storage.example.com/vendza-images',
          'fields': {
            'key': 'uploads/user-1/image.png',
            'Content-Type': 'image/png',
            'policy': 'test-policy',
          },
        },
        'object_key': 'uploads/user-1/image.png',
      });
    }

    if (request.url.path.endsWith(ApiEndpoints.uploadImageComplete)) {
      if (request is http.Request) {
        completeBody = request.body;
      }
      return _jsonResponse({
        'public_url':
            'https://cdn.example.com/images/user-1/image/product/s320.webp',
      });
    }

    return _jsonResponse({'detail': 'unexpected request'}, statusCode: 404);
  }

  http.StreamedResponse _jsonResponse(
    Map<String, dynamic> body, {
    int statusCode = 200,
  }) {
    return _response(
      jsonEncode(body),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }

  http.StreamedResponse _response(
    String body,
    int statusCode, {
    Map<String, String>? headers,
  }) {
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
      headers: headers ?? const {},
    );
  }
}

void main() {
  test('uploaded catalog images are completed before returning public URL', () async {
    final httpClient = _UploadFlowClient();
    final tokenStore = ApiTokenStore(storage: MemorySecureStorage());
    await tokenStore.saveTokens(accessToken: 'access', refreshToken: 'refresh');

    final apiClient = ApiClient(
      httpClient: httpClient,
      tokenStore: tokenStore,
      baseUrl: 'https://api.example.com/api/v1',
    );
    final uploads = UploadApiService(
      client: apiClient,
      httpClient: httpClient,
      auth: AuthApiService(client: apiClient, tokenStore: tokenStore),
    );

    final url = await uploads.uploadLocalImage(
      'data:image/png;base64,${base64Encode([1, 2, 3, 4])}',
      purpose: 'product',
    );

    expect(url, 'https://cdn.example.com/images/user-1/image/product/s320.webp');
    expect(
      httpClient.requests.any(
        (request) => request.contains(ApiEndpoints.uploadImageComplete),
      ),
      isTrue,
    );
    expect(httpClient.completeBody, contains('"profile":"product"'));
  });
}
