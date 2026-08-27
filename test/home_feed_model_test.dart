import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/home/data/models/home_feed_model.dart';

void main() {
  test('parses a complete home feed payload', () {
    final feed = HomeFeedModel.fromResponse(
      {
        'success': true,
        'data': {
          'featured_stores': [
            {
              'idstore': 1,
              'name': 'Alpha',
              'image': 'https://cdn.example/a.jpg',
              'description': 'Shop A',
            },
          ],
          'trending_products': [
            {
              'idproduct': 11,
              'title': 'Trend',
              'price': 12.5,
              'stock': 3,
              'is_active': true,
              'images': ['https://cdn.example/t.jpg'],
              'store_idstore': 1,
            },
          ],
          'popular_products': [
            {
              'idproduct': 12,
              'title': 'Popular',
              'price': 8,
              'stock': 2,
              'is_active': true,
              'store_idstore': 1,
            },
          ],
          'newest_products': [
            {
              'idproduct': 13,
              'title': 'New',
              'price': 9,
              'stock': 4,
              'is_active': true,
              'store_idstore': 1,
            },
          ],
          'discover_products': [
            {
              'idproduct': 14,
              'title': 'Discover',
              'price': 5,
              'stock': 1,
              'is_active': true,
              'store_idstore': 1,
            },
          ],
        },
      },
      storeNames: {'1': 'Alpha'},
    );

    expect(feed.featuredStores, hasLength(1));
    expect(feed.featuredStores.first.name, 'Alpha');
    expect(feed.trendingProducts.single.name, 'Trend');
    expect(feed.trendingProducts.single.storeName, 'Alpha');
    expect(feed.popularProducts.single.name, 'Popular');
    expect(feed.newestProducts.single.name, 'New');
    expect(feed.discoverProducts.single.name, 'Discover');
  });

  test('parses missing keys and empty lists as empty sections', () {
    final missing = HomeFeedModel.fromResponse({'success': true});
    expect(missing.featuredStores, isEmpty);
    expect(missing.trendingProducts, isEmpty);
    expect(missing.popularProducts, isEmpty);
    expect(missing.newestProducts, isEmpty);
    expect(missing.discoverProducts, isEmpty);
    expect(missing.isEmpty, isTrue);

    final emptyLists = HomeFeedModel.fromResponse({
      'data': {'featured_stores': <dynamic>[], 'trending_products': null},
    });
    expect(emptyLists.featuredStores, isEmpty);
    expect(emptyLists.trendingProducts, isEmpty);
  });
}
