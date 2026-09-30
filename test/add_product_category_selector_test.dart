import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/cathegory/data/services/category_store.dart'
    as category_store;
import 'package:vendza/features/product/presentation/pages/add_product.dart';
import 'package:vendza/shared/models/section_model.dart';

void main() {
  setUp(() {
    category_store.categories.clear();
    category_store.categoryRevision.value = 0;
  });

  testWidgets(
    'product form category selector rebuilds when admin categories load',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddProduct(storeId: '1', storeName: 'Boutique'),
        ),
      );

      category_store.categories.add(
        SectionModel(id: '7', name: 'Electronique', imageUrl: ''),
      );
      category_store.categoryRevision.value++;
      await tester.pump();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Electronique').last, findsOneWidget);
    },
  );
}
