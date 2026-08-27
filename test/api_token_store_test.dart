import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'fakes/memory_secure_storage.dart';

void main() {
  test('ApiTokenStore persists and restores tokens', () async {
    final storage = MemorySecureStorage();
    final store = ApiTokenStore(storage: storage);

    await store.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1');

    final restored = ApiTokenStore(storage: storage);
    await restored.restore();

    expect(restored.accessToken, 'access-1');
    expect(restored.refreshToken, 'refresh-1');
    expect(restored.hasAccessToken, isTrue);

    await store.clear();
    await restored.restore();

    expect(restored.hasAccessToken, isFalse);
  });
}
