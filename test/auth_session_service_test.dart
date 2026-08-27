import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/auth/data/services/google_identity_service.dart';
import 'package:vendza/features/profil/data/model/user_model.dart';

import 'fakes/memory_secure_storage.dart';

class _TrackingAuthApi extends AuthApiService {
  _TrackingAuthApi(this.store) : super(tokenStore: store);

  final ApiTokenStore store;
  bool googleCalled = false;
  bool get meCalled => meCallCount > 0;
  bool get refreshCalled => refreshCallCount > 0;
  bool logoutCalled = false;
  int meCallCount = 0;
  int refreshCallCount = 0;
  int meFailuresBeforeSuccess = 0;
  bool refreshShouldFail = false;
  int meUserId = 42;
  String meEmail = 'ada@example.com';
  String meFullName = 'Ada Lovelace';
  String? meAvatarUrl =
      'http://127.0.0.1:9000/vendza-images/users/ada/avatar/one.jpg';

  @override
  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    googleCalled = true;
    await store.saveTokens(
      accessToken: 'google-access',
      refreshToken: 'google-refresh',
    );
    return {
      'access_token': 'google-access',
      'refresh_token': 'google-refresh',
      'token_type': 'bearer',
      'role': 'buyer',
    };
  }

  @override
  Future<Map<String, dynamic>> me() async {
    meCallCount += 1;
    if (meFailuresBeforeSuccess > 0) {
      meFailuresBeforeSuccess -= 1;
      throw const ApiException(message: 'Token expire', statusCode: 401);
    }
    return {
      'iduser': meUserId,
      'email': meEmail,
      'fullName': meFullName,
      'phone': '+243000000000',
      'avatarUrl': meAvatarUrl,
    };
  }

  @override
  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    refreshCallCount += 1;
    if (refreshShouldFail) {
      throw const ApiException(message: 'Refresh invalide', statusCode: 401);
    }
    await store.saveTokens(
      accessToken: 'new-access-token',
      refreshToken: refreshToken,
    );
    return {
      'access_token': 'new-access-token',
      'refresh_token': refreshToken,
      'token_type': 'bearer',
    };
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    await store.clear();
  }
}

class _FakeGoogleIdentityProvider implements GoogleIdentityProvider {
  _FakeGoogleIdentityProvider(this.idToken);

  final String? idToken;

  @override
  Future<String?> authenticate() async => idToken;

  @override
  Future<void> signOut() async {}
}

void main() {
  setUp(clearCurrentUser);

  test('Google login synchronizes the shared Vendza session', () async {
    final store = ApiTokenStore(storage: MemorySecureStorage());
    final api = _TrackingAuthApi(store);
    final service = AuthSessionService(
      authApiService: api,
      googleIdentityProvider: _FakeGoogleIdentityProvider('google-token'),
      tokenStore: store,
      catalogSynchronizer: (_) async {},
      sessionCleaner: () {},
    );

    final signedIn = await service.loginWithGoogle();

    expect(signedIn, isTrue);
    expect(api.googleCalled, isTrue);
    expect(api.meCalled, isTrue);
    expect(currentUserStore.value.email, 'ada@example.com');
    expect(currentUserStore.value.firstname, 'Ada');
    expect(currentUserStore.value.lastname, 'Lovelace');
    expect(
      currentUserStore.value.urlimage,
      'http://127.0.0.1:9000/vendza-images/users/ada/avatar/one.jpg',
    );
  });

  test('Google cancellation does not call the Vendza API', () async {
    final store = ApiTokenStore(storage: MemorySecureStorage());
    final api = _TrackingAuthApi(store);
    final service = AuthSessionService(
      authApiService: api,
      googleIdentityProvider: _FakeGoogleIdentityProvider(null),
      tokenStore: store,
      catalogSynchronizer: (_) async {},
      sessionCleaner: () {},
    );

    final signedIn = await service.loginWithGoogle();

    expect(signedIn, isFalse);
    expect(api.googleCalled, isFalse);
    expect(api.meCalled, isFalse);
  });

  test('restores a persisted authenticated session', () async {
    final storage = MemorySecureStorage();
    final tokenStore = ApiTokenStore(storage: storage);
    await tokenStore.saveTokens(
      accessToken: 'persisted-access',
      refreshToken: 'persisted-refresh',
    );
    final restoredStore = ApiTokenStore(storage: storage);
    await restoredStore.restore();
    final api = _TrackingAuthApi(restoredStore);
    var synchronizedUserId = 0;
    final service = AuthSessionService(
      authApiService: api,
      googleIdentityProvider: _FakeGoogleIdentityProvider(null),
      tokenStore: restoredStore,
      catalogSynchronizer: (userId) async {
        synchronizedUserId = userId;
      },
      sessionCleaner: () {},
    );

    final restored = await service.restoreSession();

    expect(restored, isTrue);
    expect(api.meCallCount, 1);
    expect(api.refreshCallCount, 0);
    expect(synchronizedUserId, 42);
    expect(currentUserStore.value.email, 'ada@example.com');
  });

  test(
    'startup restore does not call /auth/me or /auth/refresh twice',
    () async {
      final store = ApiTokenStore(storage: MemorySecureStorage());
      await store.saveTokens(
        accessToken: 'persisted-access',
        refreshToken: 'persisted-refresh',
      );
      final api = _TrackingAuthApi(store);
      final service = AuthSessionService(
        authApiService: api,
        googleIdentityProvider: _FakeGoogleIdentityProvider(null),
        tokenStore: store,
        catalogSynchronizer: (_) async {},
        sessionCleaner: () {},
      );

      final results = await Future.wait([
        service.restoreSession(),
        service.restoreSession(),
      ]);

      expect(results, [true, true]);
      expect(api.meCallCount, 1);
      expect(api.refreshCallCount, 0);
    },
  );

  test(
    'expired access token triggers a single refresh then one successful /auth/me',
    () async {
      final store = ApiTokenStore(storage: MemorySecureStorage());
      await store.saveTokens(
        accessToken: 'expired-access',
        refreshToken: 'valid-refresh',
      );

      var meCalls = 0;
      var refreshCalls = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith(ApiEndpoints.authRefresh)) {
          refreshCalls += 1;
          return http.Response(
            '{"access_token":"fresh-access","refresh_token":"valid-refresh","token_type":"bearer"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith(ApiEndpoints.authMe)) {
          meCalls += 1;
          if (meCalls == 1) {
            return http.Response(
              '{"detail":"Unauthorized"}',
              401,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(request.headers['Authorization'], 'Bearer fresh-access');
          return http.Response(
            '{"iduser":42,"email":"ada@example.com","fullName":"Ada Lovelace","phone":"+243000000000"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });

      final client = ApiClient(httpClient: mockClient, tokenStore: store);
      final authApi = AuthApiService(client: client, tokenStore: store);
      final service = AuthSessionService(
        authApiService: authApi,
        googleIdentityProvider: _FakeGoogleIdentityProvider(null),
        tokenStore: store,
        client: client,
        catalogSynchronizer: (_) async {},
        sessionCleaner: () {},
      );

      final restored = await service.restoreSession();

      expect(restored, isTrue);
      expect(meCalls, 2); // initial 401 + single retry
      expect(refreshCalls, 1);
      expect(store.accessToken, 'fresh-access');
    },
  );

  test(
    'failed refresh clears session without a second restore refresh',
    () async {
      final store = ApiTokenStore(storage: MemorySecureStorage());
      await store.saveTokens(
        accessToken: 'expired-access',
        refreshToken: 'invalid-refresh',
      );

      var meCalls = 0;
      var refreshCalls = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith(ApiEndpoints.authRefresh)) {
          refreshCalls += 1;
          return http.Response(
            '{"detail":"Refresh invalide"}',
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith(ApiEndpoints.authMe)) {
          meCalls += 1;
          return http.Response(
            '{"detail":"Unauthorized"}',
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });

      final client = ApiClient(httpClient: mockClient, tokenStore: store);
      final authApi = AuthApiService(client: client, tokenStore: store);
      var cleaned = false;
      final service = AuthSessionService(
        authApiService: authApi,
        googleIdentityProvider: _FakeGoogleIdentityProvider(null),
        tokenStore: store,
        client: client,
        catalogSynchronizer: (_) async {},
        sessionCleaner: () => cleaned = true,
      );

      final restored = await service.restoreSession();

      expect(restored, isFalse);
      expect(meCalls, 1);
      expect(refreshCalls, 1);
      expect(store.hasAccessToken, isFalse);
      expect(cleaned, isTrue);
    },
  );

  test('logout clears secure tokens and session data', () async {
    final store = ApiTokenStore(storage: MemorySecureStorage());
    await store.saveTokens(accessToken: 'access', refreshToken: 'refresh');
    final api = _TrackingAuthApi(store);
    var cleaned = false;
    final service = AuthSessionService(
      authApiService: api,
      googleIdentityProvider: _FakeGoogleIdentityProvider(null),
      tokenStore: store,
      catalogSynchronizer: (_) async {},
      sessionCleaner: () => cleaned = true,
    );

    updateCurrentUser(
      UserModel(
        name: 'Ada Lovelace',
        lastname: 'Lovelace',
        firstname: 'Ada',
        address: '',
        email: 'ada@example.com',
        phoneNumber: '',
        urlimage:
            'http://127.0.0.1:9000/vendza-images/users/ada/avatar/one.jpg',
      ),
    );

    await service.logout();

    expect(api.logoutCalled, isTrue);
    expect(store.hasAccessToken, isFalse);
    expect(cleaned, isTrue);
    expect(currentUserStore.value.email, isEmpty);
    expect(currentUserStore.value.urlimage, isEmpty);
  });

  test('switching accounts replaces the previous avatar in memory', () async {
    final store = ApiTokenStore(storage: MemorySecureStorage());
    final api = _TrackingAuthApi(store);
    final service = AuthSessionService(
      authApiService: api,
      googleIdentityProvider: _FakeGoogleIdentityProvider('google-token'),
      tokenStore: store,
      catalogSynchronizer: (_) async {},
      sessionCleaner: () {},
    );

    await service.loginWithGoogle();
    expect(
      currentUserStore.value.urlimage,
      'http://127.0.0.1:9000/vendza-images/users/ada/avatar/one.jpg',
    );

    await service.logout();
    expect(currentUserStore.value.urlimage, isEmpty);

    api.meUserId = 99;
    api.meEmail = 'grace@example.com';
    api.meFullName = 'Grace Hopper';
    api.meAvatarUrl =
        'http://127.0.0.1:9000/vendza-images/users/grace/avatar/two.jpg';

    await service.loginWithGoogle();
    expect(currentUserStore.value.email, 'grace@example.com');
    expect(
      currentUserStore.value.urlimage,
      'http://127.0.0.1:9000/vendza-images/users/grace/avatar/two.jpg',
    );
    expect(
      currentUserStore.value.urlimage,
      isNot(contains('users/ada/avatar')),
    );
  });

  test('ApiClient retries authenticated requests after a 401 refresh', () async {
    final store = ApiTokenStore(storage: MemorySecureStorage());
    await store.saveTokens(
      accessToken: 'old-access',
      refreshToken: 'refresh-token',
    );

    var authMeCalls = 0;
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith(ApiEndpoints.authRefresh)) {
        return http.Response(
          '{"access_token":"fresh-access","refresh_token":"refresh-token","token_type":"bearer"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith(ApiEndpoints.authMe)) {
        authMeCalls += 1;
        if (authMeCalls == 1) {
          return http.Response(
            '{"detail":"Unauthorized"}',
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        expect(request.headers['Authorization'], 'Bearer fresh-access');
        return http.Response(
          '{"iduser":1,"email":"ada@example.com","role":"buyer"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });

    final client = ApiClient(httpClient: mockClient, tokenStore: store);
    final authApi = AuthApiService(client: client, tokenStore: store);
    client.setTokenRefresher(() async {
      await authApi.refresh(refreshToken: store.refreshToken!);
      return store.hasAccessToken;
    });

    final profile = await authApi.me();

    expect(profile['email'], 'ada@example.com');
    expect(store.accessToken, 'fresh-access');
    expect(authMeCalls, 2);
  });
}
