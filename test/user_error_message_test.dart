import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/shared/utils/user_error_message.dart';

void main() {
  test('API errors show their message, never the exception dump', () {
    const error = ApiException(
      message: 'Limite de votre plan atteinte',
      statusCode: 402,
      body: {'error': 'plan_limit_reached'},
    );
    final text = userErrorMessage(error);
    expect(text, 'Limite de votre plan atteinte');
    expect(text, isNot(contains('ApiException')));
    expect(text, isNot(contains('402')));
  });

  test('network failures get a connection message', () {
    expect(
      userErrorMessage(http.ClientException('Failed host lookup')),
      contains('Connexion impossible'),
    );
    expect(
      userErrorMessage(TimeoutException('slow')),
      contains('Connexion impossible'),
    );
  });

  test('unexpected Dart errors never leak class names', () {
    final text = userErrorMessage(ArgumentError('Invalid argument(s): x'));
    expect(text, isNot(contains('ArgumentError')));
    expect(text, isNot(contains('Invalid argument')));
    expect(text, 'Une erreur est survenue. Réessayez.');
  });

  test('context prefix keeps the reason readable', () {
    expect(
      userErrorMessageWithContext(
        'Suppression impossible',
        const ApiException(message: 'Produit introuvable', statusCode: 404),
      ),
      'Suppression impossible : Produit introuvable',
    );
    expect(
      userErrorMessageWithContext('Suppression impossible', StateError('boom')),
      'Suppression impossible. Réessayez.',
    );
  });
}
