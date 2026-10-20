import 'dart:async';

import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/services/presence_service.dart';
import 'package:vendza/core/services/push_notification_service.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/core/session/subscription_store.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';
import 'package:vendza/features/auth/data/services/google_identity_service.dart';
import 'package:vendza/features/notification/data/services/realtime_notification_service.dart';
import 'package:vendza/features/profil/data/model/user_model.dart';
import 'package:vendza/features/store/data/services/store_customization_state.dart';

typedef CatalogSynchronizer = Future<void> Function(int userId);
typedef SessionCleaner = void Function();
typedef PushTokenDisabler = Future<void> Function();
typedef PresenceStopper = void Function();

class AuthSessionService {
  AuthSessionService({
    AuthApiService? authApiService,
    GoogleIdentityProvider? googleIdentityProvider,
    ApiTokenStore? tokenStore,
    ApiClient? client,
    CatalogSynchronizer? catalogSynchronizer,
    SessionCleaner? sessionCleaner,
    RealtimeNotificationService? realtimeService,
    PushTokenDisabler? pushTokenDisabler,
    PresenceStopper? presenceStopper,
  }) : _authApiService = authApiService ?? AuthApiService(),
       _googleIdentityProvider =
           googleIdentityProvider ?? googleIdentityService,
       _tokenStore = tokenStore ?? apiTokenStore,
       _client = client ?? apiClient,
       _catalogSynchronizer =
           catalogSynchronizer ??
           ((userId) => bootstrapSessionCatalog(userId: userId)),
       _sessionCleaner = sessionCleaner ?? catalogRepository.clearUserData,
       _realtime = realtimeService ?? realtimeNotificationService,
       _pushTokenDisabler =
           pushTokenDisabler ?? pushNotificationService.unregisterForLogout,
       _presenceStopper = presenceStopper ?? presenceService.stop {
    _client.setTokenRefresher(refreshAccessToken);
    _realtime.setTokenRefresher(refreshAccessToken);
  }

  final AuthApiService _authApiService;
  final GoogleIdentityProvider _googleIdentityProvider;
  final ApiTokenStore _tokenStore;
  final ApiClient _client;
  final CatalogSynchronizer _catalogSynchronizer;
  final SessionCleaner _sessionCleaner;
  final RealtimeNotificationService _realtime;
  final PushTokenDisabler _pushTokenDisabler;
  final PresenceStopper _presenceStopper;
  Future<bool>? _restoreInFlight;

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _authApiService.login(
      email: email,
      password: password,
    );
    if (result['requires_email_verification'] == true ||
        result['email_verified'] == false) {
      return true;
    }
    await _synchronizeUser();
    return false;
  }

  Future<bool> loginWithGoogle() async {
    final idToken = await _googleIdentityProvider.authenticate();
    if (idToken == null) return false;
    await loginWithGoogleIdToken(idToken);
    return true;
  }

  Future<void> loginWithGoogleIdToken(String idToken) async {
    await _authApiService.googleSignIn(idToken);
    await _synchronizeUser();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final result = await _authApiService.register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    if (result['requires_email_verification'] == true ||
        result['email_verified'] == false) {
      return true;
    }
    await _synchronizeUser();
    return false;
  }

  /// Restores a previously persisted session.
  ///
  /// Concurrent callers share a single in-flight restore. Network validation
  /// happens only here (after secure-storage restore in `main`). On 401,
  /// [ApiClient] performs at most one refresh — this method does not refresh again.
  Future<bool> restoreSession({bool syncCatalog = true}) {
    final inFlight = _restoreInFlight;
    if (inFlight != null) return inFlight;

    final future = _restoreSessionOnce(syncCatalog: syncCatalog);
    _restoreInFlight = future;
    return future.whenComplete(() {
      if (identical(_restoreInFlight, future)) {
        _restoreInFlight = null;
      }
    });
  }

  Future<bool> _restoreSessionOnce({required bool syncCatalog}) async {
    final hasRefresh =
        _tokenStore.refreshToken != null &&
        _tokenStore.refreshToken!.isNotEmpty;
    if (!_tokenStore.hasAccessToken && !hasRefresh) {
      return false;
    }

    try {
      await _synchronizeUser(clearBeforeSync: false, syncCatalog: syncCatalog);
      return true;
    } on ApiException catch (error) {
      if (isConfirmedAuthFailure(error)) {
        await _invalidateLocalSession();
        return false;
      }
      NetworkStatus.reportError(error);
      return hasRefresh || _tokenStore.hasAccessToken;
    } on Object catch (error) {
      NetworkStatus.reportError(error);
      return hasRefresh || _tokenStore.hasAccessToken;
    }
  }

  Future<bool> refreshAccessToken() async {
    final refreshToken = _tokenStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      await _authApiService.refresh(refreshToken: refreshToken);
      return _tokenStore.hasAccessToken;
    } on ApiException catch (error) {
      if (isConfirmedAuthFailure(error)) {
        await _invalidateLocalSession();
        return false;
      }
      NetworkStatus.reportError(error);
      return false;
    } on Object catch (error) {
      NetworkStatus.reportError(error);
      return false;
    }
  }

  Future<void> becomeSeller() async {
    await _authApiService.becomeSeller();
  }

  Future<void> logout() async {
    // Stop every per-session background activity first so nothing keeps
    // talking to the API (or re-registers push) on behalf of this account.
    _presenceStopper();
    await _realtime.stop();
    try {
      // Must run while the access token is still valid (#108).
      await _pushTokenDisabler();
    } on Object {
      // Best effort: logout must complete even if the API is unreachable.
    }
    try {
      await _authApiService.logout();
    } finally {
      await _realtime.stop();
      _presenceStopper();
      _sessionCleaner();
      clearCurrentUser();
      clearSubscriptionSession();
      try {
        await _googleIdentityProvider.signOut();
      } on Object {
        // Google is optional; local Vendza logout must still complete.
      }
    }
  }

  /// Deletes the remote account then clears all local session material.
  Future<Map<String, dynamic>> deleteAccount({String? password}) async {
    final result = await _authApiService.deleteAccount(
      confirmation: 'SUPPRIMER',
      password: password,
    );
    _presenceStopper();
    await _realtime.stop();
    await _tokenStore.clear();
    _sessionCleaner();
    clearCurrentUser();
    try {
      await _googleIdentityProvider.signOut();
    } on Object {
      // Google optional.
    }
    return result;
  }

  Future<void> _invalidateLocalSession() async {
    _presenceStopper();
    await _realtime.stop();
    await _tokenStore.clear();
    _sessionCleaner();
    clearCurrentUser();
  }

  Future<void> _synchronizeUser({
    bool clearBeforeSync = true,
    bool syncCatalog = true,
  }) async {
    // A new login must never expose the previous account's private catalog.
    // During startup restore, keep the current in-memory state until the
    // server has actually confirmed the session; a network outage must not
    // erase an otherwise usable session.
    if (clearBeforeSync) {
      _sessionCleaner();
    }
    final profile = await _authApiService.me();
    if (!clearBeforeSync) {
      _sessionCleaner();
    }
    final email = (profile['email'] as String?)?.trim() ?? '';
    final fullName = (profile['fullName'] as String?)?.trim();
    final displayName = fullName == null || fullName.isEmpty
        ? (email.isEmpty ? 'Utilisateur' : email.split('@').first)
        : fullName;
    final nameParts = displayName.split(RegExp(r'\s+'));
    final avatarUrl = (profile['avatarUrl'] as String?)?.trim();
    final userId = profile['iduser'] as int?;

    updateCurrentUser(
      UserModel(
        userId: userId,
        name: displayName,
        firstname: nameParts.first,
        lastname: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        address: (profile['address'] as String?)?.trim() ?? '',
        city: (profile['city'] as String?)?.trim() ?? '',
        email: email,
        phoneNumber: profile['phone'] as String? ?? '',
        urlimage: sanitizeAvatarUrl(avatarUrl),
      ),
    );

    if (syncCatalog) {
      await _catalogSynchronizer(userId ?? 0);
      syncStoreCustomizationFromCatalog();
    }
    // Push notifications are optional and must never block login or session restore.
    unawaited(
      pushNotificationService.syncCurrentToken().catchError((Object _) {}),
    );
    // A fresh login (possibly another account) must not reuse a stream opened
    // with the previous account's token.
    unawaited(clearBeforeSync ? _realtime.restart() : _realtime.start());
    // Refresh subscription context silently — failure must never block login.
    refreshActiveSubscription().ignore();
  }
}

final authSessionService = AuthSessionService();
