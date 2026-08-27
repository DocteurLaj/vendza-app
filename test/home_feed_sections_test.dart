import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/home/data/models/home_feed_model.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/home/data/services/data_exemple.dart';
import 'package:vendza/shared/models/product_model.dart';

ProductModel _product({
  required String id,
  required String name,
  int contactClicks = 0,
}) {
  return ProductModel(
    id: id,
    name: name,
    price: '10',
    imageurl: '',
    status: '',
    contactClicks: contactClicks,
  );
}

void main() {
  tearDown(() {
    homeFeed = HomeFeedModel.empty;
    homeProducts.clear();
    homeStores.clear();
  });

  test('each home section uses the matching feed list', () {
    final feed = HomeFeedModel(
      featuredStores: [StoreModel(id: '1', name: 'Featured', image: '')],
      trendingProducts: [_product(id: 't', name: 'Trend', contactClicks: 0)],
      popularProducts: [_product(id: 'p', name: 'Popular', contactClicks: 99)],
      newestProducts: [_product(id: 'n', name: 'Newest', contactClicks: 1)],
      discoverProducts: [
        _product(id: 'd', name: 'Discover', contactClicks: 50),
      ],
    );
    final sections = HomeSectionsView(feed);

    expect(sections.stores.map((store) => store.id), ['1']);
    expect(sections.tendances.map((product) => product.id), ['t']);
    expect(sections.popular.map((product) => product.id), ['p']);
    expect(sections.newest.map((product) => product.id), ['n']);
    expect(sections.discover.map((product) => product.id), ['d']);
    expect(sections.discoverStores, isEmpty);
  });

  test('empty feed does not crash section mapping', () {
    const sections = HomeSectionsView(HomeFeedModel.empty);
    expect(sections.stores, isEmpty);
    expect(sections.tendances, isEmpty);
    expect(sections.popular, isEmpty);
    expect(sections.newest, isEmpty);
    expect(sections.discover, isEmpty);
  });

  test('home sections keep backend order and ignore contactClicks', () {
    final feed = HomeFeedModel(
      trendingProducts: [
        _product(id: 'low', name: 'Low', contactClicks: 0),
        _product(id: 'high', name: 'High', contactClicks: 80),
      ],
    );
    expect(
      HomeSectionsView(feed).tendances.map((product) => product.id).toList(),
      ['low', 'high'],
    );
  });

  test('search still uses the full catalog instead of the home feed', () {
    homeFeed = HomeFeedModel(
      trendingProducts: [_product(id: 'feed-only', name: 'Feed')],
    );
    homeProducts.addAll([
      _product(id: 'catalog-1', name: 'Catalog One'),
      _product(id: 'catalog-2', name: 'Catalog Two'),
    ]);
    homeStores.add(StoreModel(id: 's1', name: 'Catalog Store', image: ''));

    expect(products.map((product) => product.id), ['catalog-1', 'catalog-2']);
    expect(stores.map((store) => store.id), ['s1']);
    expect(products.map((product) => product.id), isNot(contains('feed-only')));
    expect(homeFeed.trendingProducts, hasLength(1));
  });
}
