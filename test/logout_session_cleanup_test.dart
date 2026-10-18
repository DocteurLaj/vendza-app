import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/auth/data/services/google_identity_service.dart';
import 'package:vendza/features/notification/data/services/realtime_notification_service.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_draft_store.dart';
import 'package:vendza/features/order/data/services/realtime_order_store.dart';
import 'package:vendza/shared/models/product_model.dart';

import 'fakes/memory_secure_storage.dart';

class _LogoutAuthApi extends AuthApiService {
  _LogoutAuthApi(this.store, this.events) : super(tokenStore: store);

  final ApiTokenStore store;
  final List<String> events;

  @override
  Future<void> logout() async {
    events.add('api.logout');
    await store.clear();
  }
}

class _FakeGoogle implements GoogleIdentityProvider {
  @override
  Future<String?> authenticate() async => null;

  @override
  Future<void> signOut() async {}
}

class _FakeRealtime extends RealtimeNotificationService {
  _FakeRealtime(this.events, ApiTokenStore store) : super(tokenStore: store);

  final List<String> events;

  @override
  Future<void> stop() async {
    events.add('realtime.stop');
    await super.stop();
  }
}

OrderModel _order(int id) => OrderModel.fromJson({
  'idorder': id,
  'uuidorder': 'uuid-$id',
  'total_amount': '10.00',
  'status': 'pending',
  'payment_method': 'cash_on_delivery',
  'createdAt': '2026-10-18T10:00:00',
  'store_idstore': 3,
  'items': const [],
});

void main() {
  tearDown(() {
    liveOrderStore.value = const [];
    orderDraftStore.clear();
    clearCurrentUser();
  });

  test('logout disables push (with a valid token), stops presence + realtime '
      'and clears the previous account orders (#108)', () async {
    final store = ApiTokenStore(storage: MemorySecureStorage());
    await store.saveTokens(accessToken: 'access-A', refreshToken: 'refresh-A');
    final events = <String>[];
    String? tokenWhenPushDisabled;

    final service = AuthSessionService(
      authApiService: _LogoutAuthApi(store, events),
      googleIdentityProvider: _FakeGoogle(),
      tokenStore: store,
      catalogSynchronizer: (_) async {},
      sessionCleaner: catalogRepository.clearUserData,
      realtimeService: _FakeRealtime(events, store),
      pushTokenDisabler: () async {
        tokenWhenPushDisabled = store.accessToken;
        events.add('push.disable');
      },
      presenceStopper: () => events.add('presence.stop'),
    );

    upsertLiveOrder(_order(1));
    orderDraftStore.addProduct(
      ProductModel(
        id: '4',
        name: 'Produit',
        price: '5',
        imageurl: '',
        status: '',
        description: '',
        category: '',
        storeId: '3',
        storeName: 'Boutique A',
      ),
    );
    expect(liveOrderStore.value, isNotEmpty);
    expect(orderDraftStore.value, isNotNull);

    await service.logout();

    expect(events, contains('push.disable'));
    expect(events, contains('presence.stop'));
    expect(events, contains('realtime.stop'));
    // Push must be disabled before the API logout revokes the session.
    expect(
      events.indexOf('push.disable'),
      lessThan(events.indexOf('api.logout')),
    );
    expect(tokenWhenPushDisabled, 'access-A');
    expect(liveOrderStore.value, isEmpty);
    expect(orderDraftStore.value, isNull);
    expect(store.hasAccessToken, isFalse);
  });

  test(
    'logout still completes when push unregistration fails (#108)',
    () async {
      final store = ApiTokenStore(storage: MemorySecureStorage());
      await store.saveTokens(accessToken: 'a', refreshToken: 'r');
      final events = <String>[];
      final service = AuthSessionService(
        authApiService: _LogoutAuthApi(store, events),
        googleIdentityProvider: _FakeGoogle(),
        tokenStore: store,
        catalogSynchronizer: (_) async {},
        sessionCleaner: () => events.add('clean'),
        realtimeService: _FakeRealtime(events, store),
        pushTokenDisabler: () async => throw StateError('offline'),
        presenceStopper: () {},
      );

      await service.logout();

      expect(events, containsAll(['api.logout', 'clean']));
    },
  );
}
