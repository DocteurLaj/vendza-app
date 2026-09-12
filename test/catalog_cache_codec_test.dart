import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/catalog/catalog_cache_codec.dart';
import 'package:vendza/features/home/data/models/home_feed_model.dart';
import 'package:vendza/features/home/data/models/store_model.dart' as home;
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/models/section_model.dart';

void main() {
  test('catalog cache round-trips public catalog data', () {
    final snapshot = CatalogCacheSnapshot(
      stores: [
        ListStoreModel(
          id: '10',
          name: 'Store',
          description: 'Description',
          imageUrl: 'https://example.com/store.png',
          rating: 4.5,
          city: 'Kinshasa',
          whatsappUrl: 'https://wa.me/243000',
        ),
      ],
      homeStores: [
        home.StoreModel(
          id: '10',
          name: 'Store',
          image: 'https://example.com/store.png',
          description: 'Description',
        ),
      ],
      products: [
        ProductModel(
          id: '20',
          name: 'Produit',
          price: '12.5',
          imageurl: 'https://example.com/product.png',
          status: '',
          storeId: '10',
          storeName: 'Store',
          variants: const [
            ProductVariantModel(name: 'XL', price: '14', quantity: '2'),
          ],
        ),
      ],
      homeProducts: [
        ProductModel(
          id: '20',
          name: 'Produit',
          price: '12.5',
          imageurl: 'https://example.com/product.png',
          status: '',
          storeId: '10',
          storeName: 'Store',
        ),
      ],
      homeFeed: HomeFeedModel(
        featuredStores: [
          home.StoreModel(
            id: '10',
            name: 'Store',
            image: 'https://example.com/store.png',
          ),
        ],
      ),
      categories: [
        SectionModel(id: '30', name: 'Categorie', imageUrl: 'asset.png'),
      ],
    );

    final restored = decodeCatalogCache(encodeCatalogCache(snapshot));

    expect(restored, isNotNull);
    expect(restored!.stores.single.name, 'Store');
    expect(restored.homeStores.single.id, '10');
    expect(restored.products.single.variants.single.name, 'XL');
    expect(restored.homeProducts.single.storeName, 'Store');
    expect(restored.homeFeed.featuredStores.single.name, 'Store');
    expect(restored.categories.single.name, 'Categorie');
  });
}
