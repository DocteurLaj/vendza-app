import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/services/api_config.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_token_store.dart';

typedef TokenRefresher = Future<bool> Function();

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    ApiTokenStore? tokenStore,
    TokenRefresher? tokenRefresher,
    String? baseUrl,
    Duration timeout = ApiConfig.defaultTimeout,
  }) : _httpClient = httpClient ?? http.Client(),
       _tokenStore = tokenStore ?? apiTokenStore,
       _tokenRefresher = tokenRefresher,
       _baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl,
       _timeout = timeout;

  final http.Client _httpClient;
  final ApiTokenStore _tokenStore;
  TokenRefresher? _tokenRefresher;
  final String _baseUrl;
  final Duration _timeout;
  Future<bool>? _refreshInFlight;

  void setTokenRefresher(TokenRefresher? refresher) {
    _tokenRefresher = refresher;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = false,
  }) {
    return _send(
      (authenticated) => _httpClient.get(
        _uri(path, queryParameters),
        headers: _headers(authenticated: authenticated),
      ),
      authenticated: authenticated,
      path: path,
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
    Duration? timeout,
  }) {
    return _send(
      (authenticated) => _httpClient.post(
        _uri(path),
        headers: _headers(authenticated: authenticated),
        body: body == null ? null : jsonEncode(body),
      ),
      authenticated: authenticated,
      path: path,
      timeout: timeout,
    );
  }

  Future<dynamic> postWithHeaders(
    String path, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send(
      (authenticated) => _httpClient.post(
        _uri(path),
        headers: _headers(
          authenticated: authenticated,
          additionalHeaders: headers,
        ),
        body: body == null ? null : jsonEncode(body),
      ),
      authenticated: authenticated,
      path: path,
    );
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send(
      (authenticated) => _httpClient.put(
        _uri(path),
        headers: _headers(authenticated: authenticated),
        body: body == null ? null : jsonEncode(body),
      ),
      authenticated: authenticated,
      path: path,
    );
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send(
      (authenticated) => _httpClient.patch(
        _uri(path),
        headers: _headers(authenticated: authenticated),
        body: body == null ? null : jsonEncode(body),
      ),
      authenticated: authenticated,
      path: path,
    );
  }

  Future<dynamic> delete(String path, {bool authenticated = false}) {
    return _send(
      (authenticated) => _httpClient.delete(
        _uri(path),
        headers: _headers(authenticated: authenticated),
      ),
      authenticated: authenticated,
      path: path,
    );
  }

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final normalizedBaseUrl = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '$normalizedBaseUrl$normalizedPath',
    ).replace(queryParameters: queryParameters);
  }

  Map<String, String> _headers({
    required bool authenticated,
    Map<String, String>? additionalHeaders,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    if (authenticated && _tokenStore.hasAccessToken) {
      headers['Authorization'] = 'Bearer ${_tokenStore.accessToken}';
    }

    return headers;
  }

  bool _isAuthPath(String path) {
    return path == ApiEndpoints.authRefresh ||
        path == ApiEndpoints.authLogin ||
        path == ApiEndpoints.authRegister ||
        path == ApiEndpoints.authGoogle ||
        path == ApiEndpoints.authLogout;
  }

  Future<bool> _defaultRefresh() async {
    final refreshToken = _tokenStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _httpClient
          .post(
            _uri(ApiEndpoints.authRefresh),
            headers: _headers(authenticated: false),
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(_timeout);

      final decodedBody = _decodeResponseBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await _tokenStore.clear();
        return false;
      }

      if (decodedBody is! Map) {
        await _tokenStore.clear();
        return false;
      }

      final data = Map<String, dynamic>.from(decodedBody);
      await _tokenStore.saveTokens(
        accessToken: data['access_token'] as String?,
        refreshToken: data['refresh_token'] as String?,
      );
      return _tokenStore.hasAccessToken;
    } on Object {
      await _tokenStore.clear();
      return false;
    }
  }

  Future<bool> _tryRefresh() async {
    _refreshInFlight ??=
        () async {
          final custom = _tokenRefresher;
          if (custom != null) {
            return custom();
          }
          return _defaultRefresh();
        }().whenComplete(() {
          _refreshInFlight = null;
        });
    return _refreshInFlight!;
  }

  Future<dynamic> _send(
    Future<http.Response> Function(bool authenticated) request, {
    required bool authenticated,
    required String path,
    bool retried = false,
    Duration? timeout,
  }) async {
    late http.Response response;
    try {
      response = await request(authenticated).timeout(timeout ?? _timeout);
    } on TimeoutException {
      throw const ApiException(message: 'La requete a expire.', statusCode: 408);
    } on http.ClientException catch (error) {
      throw ApiException(message: error.message);
    }

    NetworkStatus.reportOnline();
    final decodedBody = _decodeResponseBody(response.body);

    if (response.statusCode == 401 &&
        authenticated &&
        !retried &&
        !_isAuthPath(path)) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _send(
          request,
          authenticated: authenticated,
          path: path,
          retried: true,
          timeout: timeout,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: _extractErrorMessage(decodedBody),
        statusCode: response.statusCode,
        body: decodedBody,
      );
    }

    return decodedBody;
  }

  Object? _decodeResponseBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  String _extractErrorMessage(Object? decodedBody) {
    if (decodedBody is Map<String, dynamic>) {
      final detail = decodedBody['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      final message = decodedBody['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Une erreur est survenue.';
  }
}

final apiClient = ApiClient();
