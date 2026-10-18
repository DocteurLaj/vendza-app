import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/features/notification/data/services/realtime_notification_service.dart';
import 'package:vendza/features/notification/data/services/sse_parser.dart';

import 'fakes/memory_secure_storage.dart';

const _notificationFrame =
    'event: notification\n'
    'data: {"idnotification": 9, "type": "store_order", "content": "Nouvelle commande", '
    '"seen": false, "user_iduser": 2, "store_idstore": 7, "createdAt": "2026-09-30T10:00:00"}\n'
    '\n';

/// Scripted SSE server: each `send` consumes the next planned response.
class _ScriptedSseClient extends http.BaseClient {
  final List<int> statuses = [];
  final List<String?> authHeaders = [];
  final List<StreamController<List<int>>> streams = [];
  int defaultStatus = 200;

  int get requestCount => authHeaders.length;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    authHeaders.add(request.headers['Authorization']);
    final status = statuses.isEmpty ? defaultStatus : statuses.removeAt(0);
    final controller = StreamController<List<int>>();
    streams.add(controller);
    if (status != 200) unawaited(controller.close());
    return http.StreamedResponse(controller.stream, status);
  }
}

Future<void> _settle([int ms = 20]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

Future<void> _until(bool Function() condition, {int maxMs = 2000}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: maxMs));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not reached within ${maxMs}ms');
    }
    await _settle(5);
  }
}

void main() {
  tearDown(() {
    notificationStore.value = const [];
  });

  group('SseStreamParser (#86)', () {
    test('a frame split at every possible byte yields exactly one event', () {
      for (var cut = 1; cut < _notificationFrame.length; cut++) {
        final parser = SseStreamParser();
        final first = parser.add(_notificationFrame.substring(0, cut));
        final second = parser.add(_notificationFrame.substring(cut));
        expect(first, isEmpty, reason: 'cut=$cut dispatched too early');
        expect(second, hasLength(1), reason: 'cut=$cut');
        expect(second.single.event, 'notification');
        expect(second.single.data['idnotification'], 9);
      }
    });

    test('CRLF line endings, including a CR/LF pair split across chunks', () {
      final crlf = _notificationFrame.replaceAll('\n', '\r\n');
      final cut = crlf.indexOf('\r\n') + 1; // between \r and \n
      final parser = SseStreamParser();
      expect(parser.add(crlf.substring(0, cut)), isEmpty);
      final messages = parser.add(crlf.substring(cut));
      expect(messages, hasLength(1));
      expect(messages.single.event, 'notification');
    });

    test('byte-by-byte feeding of several frames and heartbeats', () {
      final payload =
          ': keep-alive\n\n$_notificationFrame'
          'event: ready\ndata: {"user_iduser": 2}\n\n';
      final parser = SseStreamParser();
      final events = <SseMessage>[];
      for (final char in payload.split('')) {
        events.addAll(parser.add(char));
      }
      expect(events.map((e) => e.event), ['notification', 'ready']);
    });

    test('malformed JSON is dropped without throwing and parsing goes on', () {
      final parser = SseStreamParser();
      final messages = parser.add(
        'event: notification\ndata: {"broken": \n\n$_notificationFrame',
      );
      expect(messages, hasLength(1));
      expect(messages.single.data['idnotification'], 9);
    });

    test('multi-line data and id are handled', () {
      final parser = SseStreamParser();
      final messages = parser.add(
        'id: 42\nevent: notification\ndata: {"idnotification":\ndata: 3}\n\n',
      );
      expect(messages.single.data['idnotification'], 3);
      expect(parser.lastEventId, '42');
    });

    test('service handles a notification split across two chunks', () {
      final service = RealtimeNotificationService(
        baseUrl: 'https://api.test/api/v1',
      );
      service.handleSseChunkForTest(_notificationFrame.substring(0, 30));
      expect(notificationStore.value, isEmpty);
      service.handleSseChunkForTest(_notificationFrame.substring(30));
      expect(notificationStore.value, hasLength(1));
      expect(notificationStore.value.single.id, '9');
    });
  });

  group('RealtimeNotificationService reconnect (#86)', () {
    late ApiTokenStore tokenStore;
    late _ScriptedSseClient client;
    late int reconnectCallbacks;

    RealtimeNotificationService build({Future<bool> Function()? refresher}) {
      return RealtimeNotificationService(
        httpClient: client,
        tokenStore: tokenStore,
        baseUrl: 'https://api.test/api/v1',
        tokenRefresher: refresher,
        onReconnected: () async => reconnectCallbacks++,
        initialBackoff: const Duration(milliseconds: 10),
        maxBackoff: const Duration(milliseconds: 40),
      );
    }

    setUp(() async {
      tokenStore = ApiTokenStore(storage: MemorySecureStorage());
      await tokenStore.saveTokens(accessToken: 'access-1', refreshToken: 'r');
      client = _ScriptedSseClient();
      reconnectCallbacks = 0;
    });

    test('backoff grows exponentially and is capped', () {
      final service = RealtimeNotificationService(
        httpClient: client,
        tokenStore: tokenStore,
        initialBackoff: const Duration(seconds: 1),
        maxBackoff: const Duration(seconds: 30),
      );
      expect(
        [1, 2, 3, 4, 5, 6, 7, 20].map((n) => service.backoffFor(n).inSeconds),
        [1, 2, 4, 8, 16, 30, 30, 30],
      );
    });

    test(
      'reconnects after the stream closes and refetches the inbox',
      () async {
        final service = build();
        await service.start();
        expect(service.isConnected, isTrue);
        expect(client.requestCount, 1);

        client.streams.first.add(
          utf8.encode(_notificationFrame.substring(0, 25)),
        );
        client.streams.first.add(utf8.encode(_notificationFrame.substring(25)));
        await _settle();
        expect(notificationStore.value, hasLength(1));

        await client.streams.first.close();
        await _settle(1);
        expect(service.isConnected, isFalse);
        expect(service.hasPendingReconnect, isTrue);

        await _until(() => client.requestCount == 2 && service.isConnected);
        await _settle();
        expect(reconnectCallbacks, 1);
        await service.stop();
      },
    );

    test(
      'server errors back off with growing delays while session exists',
      () async {
        client.statuses.addAll([500, 502, 503]);
        final service = build();
        await service.start();
        expect(service.consecutiveFailures, 1);
        expect(service.hasPendingReconnect, isTrue);

        await _until(() => client.requestCount == 4 && service.isConnected);
        expect(service.consecutiveFailures, 0);
        // First successful connection after start() is not a "reconnect".
        expect(reconnectCallbacks, 0);
        await service.stop();
      },
    );

    test(
      '401 refreshes the token then reconnects with the new token',
      () async {
        client.statuses.add(401);
        var refreshCalls = 0;
        final service = build(
          refresher: () async {
            refreshCalls++;
            await tokenStore.saveTokens(
              accessToken: 'access-2',
              refreshToken: 'r',
            );
            return true;
          },
        );
        await service.start();
        expect(refreshCalls, 1);
        expect(client.authHeaders, ['Bearer access-1', 'Bearer access-2']);
        expect(service.isConnected, isTrue);
        await service.stop();
      },
    );

    test(
      '401 with a rejected refresh token stops the stream for good',
      () async {
        client.statuses.add(401);
        final service = build(
          refresher: () async {
            await tokenStore.clear();
            return false;
          },
        );
        await service.start();
        expect(service.isStarted, isFalse);
        expect(service.hasPendingReconnect, isFalse);
        await _settle(60);
        expect(client.requestCount, 1);
      },
    );

    test('stop() cancels a pending reconnect', () async {
      client.statuses.add(500);
      final service = build();
      await service.start();
      expect(service.hasPendingReconnect, isTrue);
      await service.stop();
      await _settle(80);
      expect(client.requestCount, 1);
      expect(service.isStarted, isFalse);
    });

    test('restart() (app resumed) opens a fresh stream and resyncs', () async {
      final service = build();
      await service.start();
      expect(client.requestCount, 1);
      await service.restart();
      expect(client.requestCount, 2);
      expect(service.isConnected, isTrue);
      await _settle();
      expect(reconnectCallbacks, 1);
      await service.stop();
    });

    test('a silent connection is recycled after the idle timeout', () async {
      final service = RealtimeNotificationService(
        httpClient: client,
        tokenStore: tokenStore,
        baseUrl: 'https://api.test/api/v1',
        onReconnected: () async => reconnectCallbacks++,
        initialBackoff: const Duration(milliseconds: 10),
        idleTimeout: const Duration(milliseconds: 30),
      );
      await service.start();
      await _until(() => client.requestCount >= 2);
      await service.stop();
    });
  });
}
