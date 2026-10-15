import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/auth/presantation/pages/register_page.dart';

void main() {
  testWidgets('shows field errors before attempting registration', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

    final submitButton = find.text('S’inscrire');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('Le nom complet est requis'), findsOneWidget);
    expect(
      find.text('Veuillez entrer une adresse email valide'),
      findsOneWidget,
    );
    expect(find.text('Le numéro de téléphone est requis'), findsOneWidget);
    expect(
      find.text('Le mot de passe doit contenir au moins 8 caractères'),
      findsOneWidget,
    );
    expect(
      find.text('Veuillez accepter les conditions pour continuer'),
      findsOneWidget,
    );
  });
}
