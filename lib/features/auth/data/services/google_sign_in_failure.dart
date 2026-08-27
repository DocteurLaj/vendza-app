import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleIdentityException implements Exception {
  const GoogleIdentityException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Maps [GoogleSignInException] to either a silent dismiss or an actionable error.
///
/// On Android Credential Manager, OAuth misconfiguration is often reported as
/// [GoogleSignInExceptionCode.canceled] and cannot be distinguished from a real
/// user dismiss when [GoogleSignInException.description] is empty.
abstract final class GoogleSignInFailureMapper {
  static const configHint =
      'Config Google incomplète : client Android '
      '(package app.vendza.marketplace + SHA-1/SHA-256) ou client Web '
      '(GOOGLE_WEB_CLIENT_ID). Voir docs/GOOGLE_SIGN_IN.md.';

  /// Returns `null` when the flow should be treated as a user dismiss
  /// (caller returns `null` / no snackbar). Otherwise returns an exception
  /// the UI should show.
  static GoogleIdentityException? map(GoogleSignInException error) {
    debugLog(error);

    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        if (_looksLikeConfigurationCancel(error)) {
          return GoogleIdentityException(_composeConfigMessage(error));
        }
        return null;
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return GoogleIdentityException(_composeConfigMessage(error));
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
        return GoogleIdentityException(
          _trimOr(
            error.description,
            'Connexion Google interrompue. Réessaie dans un instant.',
          ),
        );
      case GoogleSignInExceptionCode.unknownError:
      case GoogleSignInExceptionCode.userMismatch:
        final details = error.description?.trim();
        return GoogleIdentityException(
          details == null || details.isEmpty
              ? 'Connexion Google impossible (${error.code.name}). $configHint'
              : '$details (${error.code.name})',
        );
    }
  }

  @visibleForTesting
  static bool looksLikeConfigurationCancel(GoogleSignInException error) {
    return _looksLikeConfigurationCancel(error);
  }

  static bool _looksLikeConfigurationCancel(GoogleSignInException error) {
    final blob = '${error.description ?? ''} ${error.details ?? ''}'
        .toLowerCase();
    if (blob.trim().isEmpty) return false;
    return blob.contains('config') ||
        blob.contains('sha') ||
        blob.contains('oauth') ||
        blob.contains('client') ||
        blob.contains('audience') ||
        blob.contains('package') ||
        blob.contains('credential') ||
        blob.contains('developer') ||
        blob.contains('10:') || // common Google error code prefix in messages
        blob.contains('error');
  }

  static String _composeConfigMessage(GoogleSignInException error) {
    final details = error.description?.trim();
    if (details == null || details.isEmpty) return configHint;
    return '$details — $configHint';
  }

  static String _trimOr(String? value, String fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
  }

  static void debugLog(GoogleSignInException error) {
    if (!kDebugMode) return;
    debugPrint(
      '[GoogleSignIn] code=${error.code.name} '
      'description=${error.description} details=${error.details}',
    );
    if (error.code == GoogleSignInExceptionCode.canceled &&
        !_looksLikeConfigurationCancel(error)) {
      debugPrint(
        '[GoogleSignIn] canceled with empty details — may be a real dismiss '
        'OR a masked Android OAuth config error (package/SHA/serverClientId). '
        'No POST /auth/google is sent in this path.',
      );
    }
  }
}
