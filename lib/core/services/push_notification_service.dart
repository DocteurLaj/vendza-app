import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/session/current_user_store.dart';

class PushNotificationService {
  PushNotificationService({
    ApiClient? client,
    ApiTokenStore? tokenStore,
    FirebaseMessaging? messaging,
  }) : _client = client ?? apiClient,
       _tokenStore = tokenStore ?? apiTokenStore,
       _messaging = messaging;

  final ApiClient _client;
  final ApiTokenStore _tokenStore;
  final FirebaseMessaging? _messaging;

  bool _started = false;
  String? _lastSyncedToken;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initialized = await _initializeFirebase();
      if (!initialized) return;
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _firebaseMessaging.onTokenRefresh.listen((token) {
        unawaited(_syncToken(token));
      });
      await syncCurrentToken();
    } on Object {
      _started = false;
    }
  }

  Future<void> syncCurrentToken() async {
    if (!_tokenStore.hasAccessToken) return;

    try {
      final initialized = await _initializeFirebase();
      if (!initialized) return;
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await _firebaseMessaging.getToken(
        vapidKey: kIsWeb ? _webVapidKeyOrNull : null,
      );
      if (token == null || token.isEmpty) return;
      await _syncToken(token);
    } on Object {
      // Push is optional; the in-app notification inbox still works.
    }
  }

  Future<void> _syncToken(String token) async {
    if (!_tokenStore.hasAccessToken || token == _lastSyncedToken) return;

    try {
      await _client.post(
        ApiEndpoints.notificationPushToken,
        authenticated: true,
        body: {'token': token, 'platform': _platformName},
      );
      _lastSyncedToken = token;
    } on Object {
      // Token sync can be retried on next login/start/token refresh.
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final userId = currentUserStore.value.userId ?? 0;
    if (userId <= 0) return;
    unawaited(
      catalogRepository.refreshNotifications(userId).catchError((Object _) {}),
    );
  }

  Future<bool> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) return true;
    if (kIsWeb) {
      if (!_hasWebConfig) return false;
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment(
            'VENDZA_FIREBASE_API_KEY',
            defaultValue: _defaultWebFirebaseApiKey,
          ),
          appId: String.fromEnvironment(
            'VENDZA_FIREBASE_APP_ID',
            defaultValue: _defaultWebFirebaseAppId,
          ),
          messagingSenderId: String.fromEnvironment(
            'VENDZA_FIREBASE_MESSAGING_SENDER_ID',
            defaultValue: _defaultWebFirebaseMessagingSenderId,
          ),
          projectId: String.fromEnvironment(
            'VENDZA_FIREBASE_PROJECT_ID',
            defaultValue: _defaultWebFirebaseProjectId,
          ),
          authDomain: String.fromEnvironment(
            'VENDZA_FIREBASE_AUTH_DOMAIN',
            defaultValue: _defaultWebFirebaseAuthDomain,
          ),
          storageBucket: String.fromEnvironment(
            'VENDZA_FIREBASE_STORAGE_BUCKET',
            defaultValue: _defaultWebFirebaseStorageBucket,
          ),
        ),
      );
      return true;
    }
    await Firebase.initializeApp();
    return true;
  }

  FirebaseMessaging get _firebaseMessaging {
    return _messaging ?? FirebaseMessaging.instance;
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      _ => 'unknown',
    };
  }
}

final pushNotificationService = PushNotificationService();

const _webVapidKey = String.fromEnvironment('VENDZA_FIREBASE_VAPID_KEY');
const _defaultWebFirebaseApiKey = 'AIzaSyB-t_OHTs5C7ZHT1uu47_iWl7JHEtC42QY';
const _defaultWebFirebaseAppId = '1:992593495811:web:c97808a02ce8d595794b36';
const _defaultWebFirebaseAuthDomain = 'vendza-notification.firebaseapp.com';
const _defaultWebFirebaseMessagingSenderId = '992593495811';
const _defaultWebFirebaseProjectId = 'vendza-notification';
const _defaultWebFirebaseStorageBucket =
    'vendza-notification.firebasestorage.app';
String? get _webVapidKeyOrNull => _webVapidKey.isEmpty ? null : _webVapidKey;
final _hasWebConfig =
    const String.fromEnvironment(
      'VENDZA_FIREBASE_API_KEY',
      defaultValue: _defaultWebFirebaseApiKey,
    ).isNotEmpty &&
    const String.fromEnvironment(
      'VENDZA_FIREBASE_APP_ID',
      defaultValue: _defaultWebFirebaseAppId,
    ).isNotEmpty &&
    const String.fromEnvironment(
      'VENDZA_FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: _defaultWebFirebaseMessagingSenderId,
    ).isNotEmpty &&
    const String.fromEnvironment(
      'VENDZA_FIREBASE_PROJECT_ID',
      defaultValue: _defaultWebFirebaseProjectId,
    ).isNotEmpty;
