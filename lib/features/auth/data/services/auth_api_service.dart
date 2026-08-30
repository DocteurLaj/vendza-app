import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_token_store.dart';

class AuthApiService {
  AuthApiService({ApiClient? client, ApiTokenStore? tokenStore})
    : _client = client ?? apiClient,
      _tokenStore = tokenStore ?? apiTokenStore;

  final ApiClient _client;
  final ApiTokenStore _tokenStore;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final response = await _client.post(
      ApiEndpoints.authRegister,
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
      },
    );
    final data = Map<String, dynamic>.from(response as Map);
    await _saveTokens(data);
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.authLogin,
      body: {'email': email, 'password': password},
    );
    final data = Map<String, dynamic>.from(response as Map);
    await _saveTokens(data);
    return data;
  }

  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    final response = await _client.post(
      ApiEndpoints.authGoogle,
      body: {'id_token': idToken},
    );
    final data = Map<String, dynamic>.from(response as Map);
    await _saveTokens(data);
    return data;
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _client.post(
        ApiEndpoints.authForgotPassword,
        body: {'email': email},
        timeout: const Duration(seconds: 60),
      );
    } on ApiException catch (error) {
      if (_passwordResetLikelySent(error)) return;
      rethrow;
    }
  }

  bool _passwordResetLikelySent(ApiException error) {
    final status = error.statusCode;
    if (status == null) return false;
    return status == 408 || status == 429 || status >= 500;
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _client.post(
      ApiEndpoints.authResetPassword,
      body: {'token': token, 'new_password': newPassword},
    );
  }

  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    final response = await _client.post(
      ApiEndpoints.authRefresh,
      body: {'refresh_token': refreshToken},
    );
    final data = Map<String, dynamic>.from(response as Map);
    await _saveTokens(data);
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _client.get(
      ApiEndpoints.authMe,
      authenticated: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> becomeSeller() async {
    final response = await _client.post(
      ApiEndpoints.authBecomeSeller,
      authenticated: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> logout() async {
    final refreshToken = _tokenStore.refreshToken;
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _client.post(
          ApiEndpoints.authLogout,
          body: {'refresh_token': refreshToken},
        );
      }
    } finally {
      await _tokenStore.clear();
    }
  }

  Future<Map<String, dynamic>> deleteAccount({
    required String confirmation,
    String? password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.authDeleteAccount,
      authenticated: true,
      body: {'confirmation': confirmation, 'password': ?password},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _tokenStore.saveTokens(
      accessToken: data['access_token'] as String?,
      refreshToken: data['refresh_token'] as String?,
    );
  }
}
