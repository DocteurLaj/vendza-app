import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/catalog/catalog_repository.dart' as catalog;
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/store/data/models/store_customization_model.dart';
import 'package:vendza/features/store/data/services/store_customization_state.dart';
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/features/store/presentation/widgets/store_presentation_widget.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

void main() {
  tearDown(() {
    catalog.homeProducts.clear();
    catalog.ownedStores.clear();
    catalog.stores.clear();
    syncStoreCustomizationFromCatalog();
  });

  final store = StoreModel(
    id: 'store-test',
    name: 'chaussures',
    image: 'assets/images/login_img.jpg',
    description: 'Cher que la bonne qualité',
  );

  Future<void> showStore(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StorePresentationWidget(store: store),
          ),
        ),
      ),
    );
  }

  ProductModel product(int index) => ProductModel(
    id: '$index',
    storeId: store.id,
    name: 'Article $index',
    price: '30',
    imageurl: '',
    status: 'available',
  );

  testWidgets('header names the page once and labels its actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StoreDetailPage(
          store: StoreModel(
            id: 'store-test',
            name: 'chaussures',
            image: '',
            description: 'Cher que la bonne qualité',
          ),
        ),
      ),
    );
    expect(find.text('Boutique'), findsOneWidget);
    expect(find.text('chaussures'), findsOneWidget);
    expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
    expect(find.byTooltip('Partager la boutique'), findsOneWidget);
  });

  testWidgets(
    'without personalized banner the logo is not stretched into cover and missing avatar uses monogram',
    (tester) async {
      await showStore(tester);
      final header = tester.widget<StoreCoverHeader>(
        find.byType(StoreCoverHeader),
      );
      expect(header.coverImageUrl, isEmpty);
      expect(tester.getSize(find.byType(StoreCoverHeader)).height, 116);
      expect(find.text('C'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StoreCoverHeader),
          matching: find.byType(SmartImage),
        ),
        findsNothing,
      );
      expect(find.text('Cher que la bonne qualité'), findsOneWidget);
    },
  );

  testWidgets(
    'real store logo remains in avatar, while only configured banner fills cover',
    (tester) async {
      final logoStore = StoreModel(
        id: store.id,
        name: store.name,
        image: 'https://cdn.test/logo.jpg',
        description: store.description,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StorePresentationWidget(store: logoStore)),
        ),
      );
      var header = tester.widget<StoreCoverHeader>(
        find.byType(StoreCoverHeader),
      );
      expect(header.coverImageUrl, isEmpty);
      expect(header.profileImageUrl, logoStore.image);

      updateStoreCustomizationForStore(
        store.id,
        const StoreCustomizationModel(
          name: 'chaussures',
          description: '',
          coverImageUrl: 'https://cdn.test/banner.jpg',
          profileImageUrl: '',
        ),
      );
      await tester.pump();
      header = tester.widget<StoreCoverHeader>(find.byType(StoreCoverHeader));
      expect(header.coverImageUrl, 'https://cdn.test/banner.jpg');
      expect(header.profileImageUrl, logoStore.image);
    },
  );

  testWidgets('empty catalog has no redundant catalog button', (tester) async {
    await showStore(tester);
    expect(find.text('0 produits'), findsOneWidget);
    expect(find.text('Voir les produits'), findsNothing);
  });

  testWidgets(
    'one directly visible product has singular count and no redundant catalog button',
    (tester) async {
      catalog.homeProducts.add(product(1));
      await showStore(tester);
      expect(find.text('1 produit'), findsOneWidget);
      expect(find.text('Article 1'), findsOneWidget);
      expect(find.text('Voir les produits'), findsNothing);
    },
  );

  testWidgets(
    'catalog button stays available when more products exist than the preview',
    (tester) async {
      catalog.homeProducts.addAll(
        List.generate(5, (index) => product(index + 1)),
      );
      await showStore(tester);
      expect(find.text('5 produits'), findsOneWidget);
      expect(find.text('Voir les produits'), findsOneWidget);
      expect(find.byType(StoreFeaturedProductCard), findsNWidgets(4));
    },
  );
}
