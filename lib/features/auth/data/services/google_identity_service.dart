import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vendza/core/config/google_auth_config.dart';
import 'package:vendza/features/auth/data/services/google_sign_in_failure.dart';

export 'package:vendza/features/auth/data/services/google_sign_in_failure.dart'
    show GoogleIdentityException;

abstract interface class GoogleIdentityProvider {
  Future<String?> authenticate();
  Future<void> signOut();
}

class GoogleIdentityService implements GoogleIdentityProvider {
  GoogleIdentityService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    if (!GoogleAuthConfig.isConfigured) {
      throw const GoogleIdentityException(
        'GOOGLE_WEB_CLIENT_ID n’est pas configuré.',
      );
    }
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    if (isIos && GoogleAuthConfig.iosClientId.isEmpty) {
      throw const GoogleIdentityException(
        'GOOGLE_IOS_CLIENT_ID n’est pas configuré.',
      );
    }
    final clientId = kIsWeb
        ? GoogleAuthConfig.webClientId
        : isIos
        ? GoogleAuthConfig.iosClientId
        : null;
    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: GoogleAuthConfig.webClientId,
    );
  }

  @override
  Future<String?> authenticate() async {
    await initialize();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw const GoogleIdentityException(
        'Google Sign-In interactif n’est pas disponible sur cette plateforme.',
      );
    }
    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile', 'openid'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw GoogleIdentityException(
          'Google n’a pas retourné de jeton d’identité. '
          '${GoogleSignInFailureMapper.configHint}',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      final mapped = GoogleSignInFailureMapper.map(error);
      if (mapped == null) return null;
      throw mapped;
    }
  }

  @override
  Future<void> signOut() async {
    if (!GoogleAuthConfig.isConfigured) return;
    await initialize();
    await _googleSignIn.signOut();
  }
}

final googleIdentityService = GoogleIdentityService();
