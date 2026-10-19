import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/services/presence_service.dart';

import 'fakes/memory_secure_storage.dart';

void main() {
  test('sends an authenticated heartbeat to /presence', () async {
    final tokens = ApiTokenStore(storage: MemorySecureStorage());
    await tokens.saveTokens(accessToken: 'access', refreshToken: 'refresh');
    final requests = <http.Request>[];
    final client = ApiClient(
      tokenStore: tokens,
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      }),
    );
    final presence = PresenceService(
      client: client,
      tokenStore: tokens,
      platform: 'web',
    )..path = 'home';

    await presence.beat();

    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/presence');
    expect(requests.single.headers['Authorization'], 'Bearer access');
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['platform'], 'web');
    expect(body['path'], 'home');
    expect(body['session_id'], isNotEmpty);
  });

  test('does nothing when signed out', () async {
    final tokens = ApiTokenStore(storage: MemorySecureStorage());
    var calls = 0;
    final client = ApiClient(
      tokenStore: tokens,
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    await PresenceService(
      client: client,
      tokenStore: tokens,
      platform: 'web',
    ).beat();
    expect(calls, 0);
  });

  test('repeats while running and stops cleanly', () async {
    final tokens = ApiTokenStore(storage: MemorySecureStorage());
    await tokens.saveTokens(accessToken: 'access', refreshToken: 'refresh');
    var calls = 0;
    final client = ApiClient(
      tokenStore: tokens,
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        calls++;
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      }),
    );
    final presence = PresenceService(
      client: client,
      tokenStore: tokens,
      platform: 'web',
      interval: const Duration(milliseconds: 100),
    );
    presence.start();
    await Future<void>.delayed(const Duration(milliseconds: 260));
    presence.stop();
    final afterStop = calls;
    expect(afterStop, greaterThanOrEqualTo(3));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(calls, afterStop);
    expect(presence.isRunning, isFalse);
  });

  test('a heartbeat failure is swallowed', () async {
    final tokens = ApiTokenStore(storage: MemorySecureStorage());
    await tokens.saveTokens(accessToken: 'access', refreshToken: 'refresh');
    final client = ApiClient(
      tokenStore: tokens,
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async => http.Response('boom', 500)),
    );
    await PresenceService(
      client: client,
      tokenStore: tokens,
      platform: 'web',
    ).beat();
  });
}
