import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/collection/presentation/widgets/add_collection_dialog.dart';

void main() {
  testWidgets('collection dialog rejects one character names before API call', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AddCollectionDialog())),
    );

    await tester.enterText(find.byType(TextField), 'A');
    await tester.tap(find.text('Creer'));
    await tester.pumpAndSettle();

    expect(
      find.text('Le nom doit contenir au moins 2 caractères'),
      findsOneWidget,
    );
  });
}
