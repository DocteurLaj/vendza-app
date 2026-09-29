import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/cathegory/presentation/widgets/cathegory_product_preview.dart';
import 'package:vendza/features/collection/presentation/widgets/collection_product_stack_preview.dart';
import 'package:vendza/features/collection/presentation/widgets/assign_products_dialog.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

ProductModel product({required String id, required String imageUrl}) {
  return ProductModel(
    id: id,
    name: 'Produit $id',
    price: '10',
    imageurl: imageUrl,
    status: 'active',
    storeId: '1',
    isActive: true,
  );
}

Future<void> pumpPreview(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('category preview stacks product images for used categories', (
    tester,
  ) async {
    await pumpPreview(
      tester,
      CathegoryProductPreview(
        products: [
          product(id: '1', imageUrl: 'https://cdn.example.com/p1.webp'),
          product(id: '2', imageUrl: 'https://cdn.example.com/p2.webp'),
          product(id: '3', imageUrl: 'https://cdn.example.com/p3.webp'),
        ],
      ),
    );

    expect(find.byType(SmartImage), findsNWidgets(3));
    expect(find.byIcon(Icons.category_outlined), findsNothing);
  });

  testWidgets(
    'collection preview stacks product images for collection content',
    (tester) async {
      await pumpPreview(
        tester,
        CollectionProductStackPreview(
          products: [
            product(id: '1', imageUrl: 'https://cdn.example.com/p1.webp'),
            product(id: '2', imageUrl: 'https://cdn.example.com/p2.webp'),
          ],
        ),
      );

      expect(find.byType(SmartImage), findsNWidgets(2));
      expect(find.byIcon(Icons.collections_outlined), findsNothing);
    },
  );

  testWidgets('assign products dialog shows each product own image', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssignProductsDialog(
            title: 'Ajouter des produits',
            subtitle: 'Choisis les produits à assigner.',
            products: [
              product(id: '1', imageUrl: 'https://cdn.example.com/p1.webp'),
              product(id: '2', imageUrl: 'https://cdn.example.com/p2.webp'),
            ],
            selectedProducts: const [],
          ),
        ),
      ),
    );

    expect(find.byType(SmartImage), findsNWidgets(2));
  });
}
