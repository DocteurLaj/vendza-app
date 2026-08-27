import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_token_store.dart';

import 'fakes/memory_secure_storage.dart';

void main() {
  test('refreshes an expired access token and retries once', () async {
    final storage = MemorySecureStorage();
    final tokens = ApiTokenStore(storage: storage);
    await tokens.saveTokens(
      accessToken: 'expired-access',
      refreshToken: 'valid-refresh',
    );
    var protectedCalls = 0;
    var refreshCalls = 0;

    final client = ApiClient(
      tokenStore: tokens,
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/refresh') {
          refreshCalls++;
          expect(jsonDecode(request.body), {'refresh_token': 'valid-refresh'});
          return http.Response(
            jsonEncode({
              'access_token': 'new-access',
              'refresh_token': 'new-refresh',
            }),
            200,
          );
        }

        protectedCalls++;
        if (protectedCalls == 1) {
          expect(request.headers['Authorization'], 'Bearer expired-access');
          return http.Response('{"detail":"Token expired"}', 401);
        }
        expect(request.headers['Authorization'], 'Bearer new-access');
        return http.Response('{"ok":true}', 200);
      }),
    );

    final response = await client.get('/protected', authenticated: true);

    expect(response, {'ok': true});
    expect(protectedCalls, 2);
    expect(refreshCalls, 1);
    expect(tokens.accessToken, 'new-access');
    expect(tokens.refreshToken, 'new-refresh');
  });

  test('clears the session when the refresh token is invalid', () async {
    final storage = MemorySecureStorage();
    final tokens = ApiTokenStore(storage: storage);
    await tokens.saveTokens(
      accessToken: 'expired-access',
      refreshToken: 'invalid-refresh',
    );

    final client = ApiClient(
      tokenStore: tokens,
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/refresh') {
          return http.Response('{"detail":"Invalid refresh token"}', 401);
        }
        return http.Response('{"detail":"Token expired"}', 401);
      }),
    );

    await expectLater(
      client.get('/protected', authenticated: true),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(tokens.hasAccessToken, isFalse);
    expect(tokens.refreshToken, isNull);

    final restored = ApiTokenStore(storage: storage);
    await restored.restore();
    expect(restored.hasAccessToken, isFalse);
    expect(restored.refreshToken, isNull);
  });
}
