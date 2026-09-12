import 'package:vendza/core/services/api_exception.dart';

typedef StoreCreationSessionValidator = Future<bool> Function();

Future<void> ensureStoreCreationSession(
  StoreCreationSessionValidator validateSession, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final isValid = await validateSession().timeout(
    timeout,
    onTimeout: () => true,
  );
  if (!isValid) {
    throw const ApiException(
      message: 'Session expiree. Reconnectez-vous avant de creer un store.',
      statusCode: 401,
    );
  }
}
