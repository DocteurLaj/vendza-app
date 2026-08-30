import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';
import 'package:vendza/features/auth/data/services/google_identity_service.dart';
import 'package:vendza/features/profil/data/model/user_model.dart';
import 'package:vendza/features/store/data/services/store_customization_state.dart';

typedef CatalogSynchronizer = Future<void> Function(int userId);
typedef SessionCleaner = void Function();

class AuthSessionService {
  AuthSessionService({
    AuthApiService? authApiService,
    GoogleIdentityProvider? googleIdentityProvider,
    ApiTokenStore? tokenStore,
    ApiClient? client,
    CatalogSynchronizer? catalogSynchronizer,
    SessionCleaner? sessionCleaner,
  }) : _authApiService = authApiService ?? AuthApiService(),
       _googleIdentityProvider =
           googleIdentityProvider ?? googleIdentityService,
       _tokenStore = tokenStore ?? apiTokenStore,
       _client = client ?? apiClient,
       _catalogSynchronizer =
           catalogSynchronizer ??
           ((userId) => bootstrapSessionCatalog(userId: userId)),
       _sessionCleaner = sessionCleaner ?? catalogRepository.clearUserData {
    _client.setTokenRefresher(refreshAccessToken);
  }

  final AuthApiService _authApiService;
  final GoogleIdentityProvider _googleIdentityProvider;
  final ApiTokenStore _tokenStore;
  final ApiClient _client;
  final CatalogSynchronizer _catalogSynchronizer;
  final SessionCleaner _sessionCleaner;
  Future<bool>? _restoreInFlight;

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await _authApiService.login(email: email, password: password);
    await _synchronizeUser();
  }

  Future<bool> loginWithGoogle() async {
    final idToken = await _googleIdentityProvider.authenticate();
    if (idToken == null) return false;
    await _authApiService.googleSignIn(idToken);
    await _synchronizeUser();
    return true;
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    await _authApiService.register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    await _synchronizeUser();
  }

  /// Restores a previously persisted session.
  ///
  /// Concurrent callers share a single in-flight restore. Network validation
  /// happens only here (after secure-storage restore in `main`). On 401,
  /// [ApiClient] performs at most one refresh — this method does not refresh again.
  Future<bool> restoreSession() {
    final inFlight = _restoreInFlight;
    if (inFlight != null) return inFlight;

    final future = _restoreSessionOnce();
    _restoreInFlight = future;
    return future.whenComplete(() {
      if (identical(_restoreInFlight, future)) {
        _restoreInFlight = null;
      }
    });
  }

  Future<bool> _restoreSessionOnce() async {
    final hasRefresh =
        _tokenStore.refreshToken != null &&
        _tokenStore.refreshToken!.isNotEmpty;
    if (!_tokenStore.hasAccessToken && !hasRefresh) {
      return false;
    }

    try {
      await _synchronizeUser(clearBeforeSync: false);
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
    try {
      await _authApiService.logout();
    } finally {
      _sessionCleaner();
      clearCurrentUser();
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
    await _tokenStore.clear();
    _sessionCleaner();
    clearCurrentUser();
  }

  Future<void> _synchronizeUser({bool clearBeforeSync = true}) async {
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
        address: '',
        email: email,
        phoneNumber: profile['phone'] as String? ?? '',
        urlimage: sanitizeAvatarUrl(avatarUrl),
      ),
    );

    await _catalogSynchronizer(userId ?? 0);
    syncStoreCustomizationFromCatalog();
  }
}

final authSessionService = AuthSessionService();
