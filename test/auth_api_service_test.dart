import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';

import 'fakes/memory_secure_storage.dart';

class _StatusApiClient extends ApiClient {
  _StatusApiClient(this.statusCode);

  final int statusCode;

  @override
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
    Duration? timeout,
  }) async {
    throw ApiException(
      message: 'Une erreur est survenue.',
      statusCode: statusCode,
    );
  }
}

class _FakeApiClient extends ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
    Duration? timeout,
  }) async {
    lastPath = path;
    lastBody = body;
    return {
      'access_token': 'access-token',
      'refresh_token': 'refresh-token',
      'token_type': 'bearer',
      'role': 'buyer',
    };
  }
}

void main() {
  test(
    'Google Sign-In sends only the ID token and stores Vendza tokens',
    () async {
      final apiClient = _FakeApiClient();
      final tokenStore = ApiTokenStore(storage: MemorySecureStorage());
      final service = AuthApiService(client: apiClient, tokenStore: tokenStore);

      final result = await service.googleSignIn('google-id-token');

      expect(apiClient.lastPath, ApiEndpoints.authGoogle);
      expect(apiClient.lastBody, {'id_token': 'google-id-token'});
      expect(result['role'], 'buyer');
      expect(tokenStore.accessToken, 'access-token');
      expect(tokenStore.refreshToken, 'refresh-token');
    },
  );

  test('refresh sends only the refresh token', () async {
    final apiClient = _FakeApiClient();
    final tokenStore = ApiTokenStore(storage: MemorySecureStorage());
    await tokenStore.saveTokens(refreshToken: 'stored-refresh-token');
    final service = AuthApiService(client: apiClient, tokenStore: tokenStore);

    await service.refresh(refreshToken: 'stored-refresh-token');

    expect(apiClient.lastPath, ApiEndpoints.authRefresh);
    expect(apiClient.lastBody, {'refresh_token': 'stored-refresh-token'});
  });

  test('logout revokes the refresh token and clears secure storage', () async {
    final storage = MemorySecureStorage();
    final apiClient = _FakeApiClient();
    final tokenStore = ApiTokenStore(storage: storage);
    await tokenStore.saveTokens(
      accessToken: 'stored-access-token',
      refreshToken: 'stored-refresh-token',
    );
    final service = AuthApiService(client: apiClient, tokenStore: tokenStore);

    await service.logout();

    expect(apiClient.lastPath, ApiEndpoints.authLogout);
    expect(apiClient.lastBody, {'refresh_token': 'stored-refresh-token'});
    expect(tokenStore.hasAccessToken, isFalse);
    expect(tokenStore.refreshToken, isNull);

    final restored = ApiTokenStore(storage: storage);
    await restored.restore();
    expect(restored.hasAccessToken, isFalse);
    expect(restored.refreshToken, isNull);
  });

  test('forgot password sends only the normalized request payload', () async {
    final apiClient = _FakeApiClient();
    final service = AuthApiService(client: apiClient);

    await service.requestPasswordReset('buyer@example.com');

    expect(apiClient.lastPath, ApiEndpoints.authForgotPassword);
    expect(apiClient.lastBody, {'email': 'buyer@example.com'});
  });

  test('forgot password treats a timeout as success', () async {
    final service = AuthApiService(client: _StatusApiClient(408));

    await service.requestPasswordReset('buyer@example.com');
  });

  test('forgot password treats a gateway error as success', () async {
    final service = AuthApiService(client: _StatusApiClient(502));

    await service.requestPasswordReset('buyer@example.com');
  });

  test('reset password sends token and new password', () async {
    final apiClient = _FakeApiClient();
    final service = AuthApiService(client: apiClient);

    await service.resetPassword(
      token: 'password-reset-token',
      newPassword: 'new-strong-password',
    );

    expect(apiClient.lastPath, ApiEndpoints.authResetPassword);
    expect(apiClient.lastBody, {
      'token': 'password-reset-token',
      'new_password': 'new-strong-password',
    });
  });
}
