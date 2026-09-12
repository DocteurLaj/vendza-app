import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/store/presentation/controllers/store_creation_session_guard.dart';

void main() {
  test('store creation guard rejects stale browser sessions before submit', () async {
    await expectLater(
      ensureStoreCreationSession(() async => false),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Session expiree. Reconnectez-vous avant de creer un store.',
        ),
      ),
    );
  });

  test('store creation guard allows valid sessions', () async {
    await expectLater(
      ensureStoreCreationSession(() async => true),
      completes,
    );
  });

  test('store creation guard does not block submit when restore stalls', () async {
    final stopwatch = Stopwatch()..start();

    await expectLater(
      ensureStoreCreationSession(
        () => Future<bool>.delayed(
          const Duration(seconds: 30),
          () => true,
        ),
        timeout: const Duration(milliseconds: 20),
      ),
      completes,
    );

    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
  });
}
