import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/store/presentation/widgets/custom_image_selector.dart';

void main() {
  testWidgets('image selector constrains text in a phone-sized slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 90,
              child: CustomImageSelector(
                title: 'Ajouter une image du produit',
                subtitle: 'Appuyez pour choisir une image',
                imageUrl: '',
                icon: Icons.add_a_photo_outlined,
                height: 90,
                onTap: null,
              ),
            ),
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(
      find.text('Ajouter une image du produit'),
    );

    expect(tester.takeException(), isNull);
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(find.text('Appuyez pour choisir une image'), findsNothing);
  });
}
