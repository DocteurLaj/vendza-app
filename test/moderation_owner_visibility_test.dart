import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/presentation/widgets/store_list_section.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/product/product_section.dart';
import 'package:vendza/shared/widgets/product/product_view_mode.dart';

void main() {
  group('owner moderation visibility', () {
    test('maps store admin lock fields from API owner response', () {
      final store = listStoreFromApi({
        'idstore': 9,
        'name': 'Boutique controlee',
        'description': 'Mode',
        'image': '',
        'admin_hidden': true,
        'moderation_reason': 'Documents incomplets',
        'moderated_at': '2026-10-01T12:00:00',
      });

      expect(store.adminHidden, isTrue);
      expect(store.moderationReason, 'Documents incomplets');
      expect(store.moderatedAt, DateTime.parse('2026-10-01T12:00:00'));
    });

    test('maps product admin lock fields from API owner response', () {
      final product = productFromApi({
        'idproduct': 14,
        'title': 'Produit bloque',
        'price': '12.00',
        'stock': 5,
        'images': [],
        'is_active': false,
        'admin_disabled': true,
        'moderation_reason': 'Article interdit',
        'moderated_at': '2026-10-01T13:00:00',
      });

      expect(product.adminDisabled, isTrue);
      expect(product.moderationReason, 'Article interdit');
      expect(product.moderatedAt, DateTime.parse('2026-10-01T13:00:00'));
    });

    testWidgets(
      'owner store list explains blocked stores with support action',
      (tester) async {
        final store = ListStoreModel(
          id: '9',
          name: 'Boutique controlee',
          description: 'Mode',
          imageUrl: '',
          rating: 0,
          adminHidden: true,
          moderationReason: 'Documents incomplets',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoreListSection(
                title: 'Mes stores',
                stores: [store],
                onStoreTap: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Boutique bloquee'), findsOneWidget);
        expect(find.textContaining('Documents incomplets'), findsOneWidget);
        expect(find.text('Contacter le support'), findsOneWidget);
      },
    );

    testWidgets('owner product cards explain admin-disabled products', (
      tester,
    ) async {
      productViewModeStore.value = ProductViewMode.list;
      final product = ProductModel(
        id: '14',
        name: 'Produit bloque',
        price: '12',
        imageurl: '',
        status: '',
        isActive: false,
        adminDisabled: true,
        moderationReason: 'Article interdit',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductSectionWidget(
              products: [product],
              ownerMode: true,
              showInactiveProducts: true,
              showViewToggle: false,
              onProductTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Produit bloque'), findsWidgets);
      expect(find.textContaining('Article interdit'), findsOneWidget);
      expect(find.text('Contacter le support'), findsOneWidget);
    });
  });
}
