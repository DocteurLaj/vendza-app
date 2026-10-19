import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/services/api_exception.dart';

/// Text safe to show to a user for any caught error (#110).
///
/// Never exposes `ApiException [402]: {...}`, Dart exception class names or
/// stack details. API errors already carry a localized, user-facing message.
String userErrorMessage(
  Object error, {
  String fallback = 'Une erreur est survenue. Réessayez.',
}) {
  if (error is ApiException) {
    final message = error.message.trim();
    if (message.isNotEmpty) return message;
    return fallback;
  }
  if (isNetworkFailure(error)) {
    return 'Connexion impossible. Vérifiez votre réseau et réessayez.';
  }
  return fallback;
}

/// Same as [userErrorMessage] with a contextual prefix, e.g.
/// "Suppression impossible : `raison`".
String userErrorMessageWithContext(String context, Object error) {
  final reason = userErrorMessage(error, fallback: '');
  return reason.isEmpty ? '$context. Réessayez.' : '$context : $reason';
}
