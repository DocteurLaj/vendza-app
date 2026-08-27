import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiTokenStore {
  ApiTokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const _accessTokenKey = 'vendza_access_token';
  static const _refreshTokenKey = 'vendza_refresh_token';

  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get hasAccessToken {
    return _accessToken != null && _accessToken!.isNotEmpty;
  }

  Future<void> restore() async {
    _accessToken = await _storage.read(key: _accessTokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveTokens({String? accessToken, String? refreshToken}) async {
    if (accessToken != null) {
      _accessToken = accessToken;
      await _storage.write(key: _accessTokenKey, value: accessToken);
    }
    if (refreshToken != null) {
      _refreshToken = refreshToken;
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

final apiTokenStore = ApiTokenStore();
