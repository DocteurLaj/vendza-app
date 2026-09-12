import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/product/presentation/widgets/product_detail_widgets.dart';
import 'package:vendza/shared/models/product_model.dart';

void main() {
  testWidgets(
    'empty product description does not render canned fallback text',
    (tester) async {
      final product = ProductModel(
        id: '1',
        name: 'Produit sans description',
        price: '12.5',
        imageurl: '',
        status: '',
        description: '',
        storeId: '7',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: ProductDetailContentPanel(
                product: product,
                displayedPrice: '12.5 CDF',
                selectedVariantIndex: null,
                socialItems: const [],
                isExpanded: true,
                onVariantSelected: (_) {},
                onContactSeller: () {},
                onBuy: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Montre connectee'), findsNothing);
      expect(find.textContaining('autonomie longue duree'), findsNothing);
    },
  );
}
