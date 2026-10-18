import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/features/subscription/presentation/widgets/upgrade_required_popup.dart';

import 'fakes/memory_secure_storage.dart';

const _human =
    'Votre abonnement permet 1 boutique(s). Passez à une offre supérieure.';

void main() {
  group('ApiException plan-limit detection (#87)', () {
    test('new envelope: code + details map', () {
      const error = ApiException(
        message: _human,
        statusCode: 402,
        body: {
          'success': false,
          'message': _human,
          'code': 'plan_limit_reached',
          'details': {
            'error': 'plan_limit_reached',
            'message': _human,
            'current_plan': 'free',
          },
        },
      );
      expect(error.isPlanLimitReached, isTrue);
      expect(error.code, 'plan_limit_reached');
      expect(error.planLimitDetail?['current_plan'], 'free');
      expect(error.displayMessage, _human);
    });

    test('new envelope with code only falls back to envelope message', () {
      const error = ApiException(
        message: _human,
        statusCode: 402,
        body: {
          'success': false,
          'message': _human,
          'code': 'plan_limit_reached',
          'details': {'current_plan': 'free'},
        },
      );
      expect(error.isPlanLimitReached, isTrue);
      expect(error.planLimitDetail?['message'], _human);
      expect(error.planLimitDetail?['current_plan'], 'free');
    });

    test('backward compatible shapes still work', () {
      const fastApi = ApiException(
        message: 'x',
        statusCode: 402,
        body: {
          'detail': {'error': 'plan_limit_reached', 'message': _human},
        },
      );
      const flat = ApiException(
        message: 'x',
        statusCode: 402,
        body: {'error': 'plan_limit_reached', 'message': _human},
      );
      expect(fastApi.isPlanLimitReached, isTrue);
      expect(fastApi.displayMessage, _human);
      expect(flat.isPlanLimitReached, isTrue);
    });

    test('legacy flattened Python repr is recognised and humanised', () {
      const repr =
          "{'error': 'plan_limit_reached', 'message': 'Votre abonnement permet "
          "1 boutique(s)...', 'current_plan': 'free'}";
      const error = ApiException(
        message: repr,
        statusCode: 402,
        body: {
          'success': false,
          'message': repr,
          'code': 'http_error',
          'details': null,
        },
      );
      expect(error.isPlanLimitReached, isTrue);
      expect(error.planLimitDetail?['current_plan'], 'free');
      expect(error.displayMessage, 'Votre abonnement permet 1 boutique(s)...');
      expect(error.displayMessage, isNot(contains("{'")));
    });

    test('non plan-limit errors are not flagged', () {
      const error = ApiException(
        message: 'Store introuvable',
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Store introuvable',
          'code': 'http_error',
        },
      );
      expect(error.isPlanLimitReached, isFalse);
      expect(error.displayMessage, 'Store introuvable');
    });

    test('ApiClient surfaces the human message from the new envelope', () async {
      final client = ApiClient(
        tokenStore: ApiTokenStore(storage: MemorySecureStorage()),
        baseUrl: 'https://api.test/api/v1',
        httpClient: MockClient(
          (_) async => http.Response(
            '{"success":false,"message":"$_human","code":"plan_limit_reached",'
            '"details":{"error":"plan_limit_reached","message":"$_human","current_plan":"free"}}',
            402,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      try {
        await client.post('/store/add');
        fail('expected ApiException');
      } on ApiException catch (error) {
        expect(error.message, _human);
        expect(error.isPlanLimitReached, isTrue);
      }
    });

    test('ApiClient never returns a raw Python repr as the message', () async {
      final client = ApiClient(
        tokenStore: ApiTokenStore(storage: MemorySecureStorage()),
        baseUrl: 'https://api.test/api/v1',
        httpClient: MockClient(
          (_) async => http.Response(
            '{"success":false,"message":"{\'error\': \'other\', \'message\': \'Paiement indisponible\'}","code":"http_error","details":null}',
            502,
          ),
        ),
      );
      try {
        await client.post('/subscription/pay');
        fail('expected ApiException');
      } on ApiException catch (error) {
        expect(error.message, 'Paiement indisponible');
      }
    });

    testWidgets('server 402 with new envelope opens the upgrade popup', (
      tester,
    ) async {
      const error = ApiException(
        message: _human,
        statusCode: 402,
        body: {
          'success': false,
          'message': _human,
          'code': 'plan_limit_reached',
          'details': {
            'error': 'plan_limit_reached',
            'message': _human,
            'current_plan': 'free',
          },
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showUpgradeRequiredPopupFromError(
                  context: context,
                  error: error,
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 boutique(s)'), findsWidgets);
      expect(find.textContaining("{'error'"), findsNothing);
    });
  });
}
