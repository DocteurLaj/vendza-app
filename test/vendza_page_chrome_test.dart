import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/shared/widgets/layout/vendza_page_header.dart';
import 'package:vendza/shared/widgets/loading/vendza_loading_state.dart';

void main() {
  group('Vendza page chrome', () {
    testWidgets(
      'root header uses a meaningful leading icon instead of an empty gap',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              appBar: VendzaPageHeader.root(
                title: 'Mes Stores',
                icon: Icons.storefront_outlined,
              ),
            ),
          ),
        );

        expect(find.text('Mes Stores'), findsOneWidget);
        expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
        expect(find.byType(BackButton), findsNothing);
      },
    );

    testWidgets('secondary header keeps a clear back action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: VendzaPageHeader.back(
              title: 'Ajouter Produit',
              icon: Icons.inventory_2_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Ajouter Produit'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets(
      'header gives back icon, context icon and title room to breathe',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              appBar: VendzaPageHeader.back(
                title: 'Ajouter Produit',
                subtitle: 'Completez les details de vente',
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ),
        );

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.toolbarHeight, greaterThanOrEqualTo(88));
        expect(appBar.leadingWidth, inInclusiveRange(60, 68));
        expect(appBar.titleSpacing, greaterThanOrEqualTo(8));

        final backSurface = tester.getSize(
          find.byKey(const Key('vendza_header_leading_button_surface')).first,
        );
        expect(backSurface.width, lessThanOrEqualTo(40));
        expect(backSurface.height, lessThanOrEqualTo(40));

        final titleTopLeft = tester.getTopLeft(find.text('Ajouter Produit'));
        final backTopRight = tester.getTopRight(
          find.byIcon(Icons.arrow_back_ios_new_rounded),
        );
        final contextTopRight = tester.getTopRight(
          find.byIcon(Icons.inventory_2_outlined),
        );
        expect(titleTopLeft.dx - contextTopRight.dx, greaterThanOrEqualTo(18));
        expect(contextTopRight.dx - backTopRight.dx, greaterThanOrEqualTo(44));

        final subtitle = tester.widget<Text>(
          find.text('Completez les details de vente'),
        );
        expect(subtitle.style?.color, isNot(equals(Colors.black)));
      },
    );

    testWidgets('loading state gives context instead of a bare spinner', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VendzaLoadingState(
              title: 'Chargement des commandes',
              message: 'Nous préparons les éléments.',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement des commandes'), findsOneWidget);
      expect(find.text('Nous préparons les éléments.'), findsOneWidget);
    });
  });
}
