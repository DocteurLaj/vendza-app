import 'package:vendza/core/services/api_exception.dart';

typedef StoreCreationSessionValidator = Future<bool> Function();

Future<void> ensureStoreCreationSession(
  StoreCreationSessionValidator validateSession,
) async {
  final isValid = await validateSession();
  if (!isValid) {
    throw const ApiException(
      message: 'Session expiree. Reconnectez-vous avant de creer un store.',
      statusCode: 401,
    );
  }
}
