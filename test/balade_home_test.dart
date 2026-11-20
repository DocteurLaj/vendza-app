import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vendza/core/catalog/catalog_cache_codec.dart';
import 'package:vendza/core/catalog/catalog_repository.dart' as catalog;
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/services/search_event_api_service.dart';
import 'package:vendza/features/home/data/models/home_feed_model.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/home/data/services/home_feed_api_service.dart';
import 'package:vendza/features/home/presantation/widgets/balade_home.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'fakes/memory_secure_storage.dart';

void main() {
  test('personalization is true only for explicit API data flag', () {
    expect(
      HomeFeedModel.fromResponse({
        'data': {'personalized': true},
      }).personalized,
      isTrue,
    );
    expect(
      HomeFeedModel.fromResponse({
        'data': {'personalized': false},
      }).personalized,
      isFalse,
    );
    expect(
      HomeFeedModel.fromResponse({'personalized': true}).personalized,
      isTrue,
    );
    expect(HomeFeedModel.fromResponse({'data': {}}).personalized, isFalse);
  });

  test('all discoveries preserve ranked sections and dedupe', () {
    ProductModel product(String id) =>
        ProductModel(id: id, name: id, price: '1', imageurl: '', status: '');
    final feed = HomeFeedModel(
      trendingProducts: [product('trend')],
      newestProducts: [product('new')],
      popularProducts: [product('trend'), product('popular')],
    );
    expect(feed.rankedProducts([product('catalog')]).map((p) => p.id), [
      'trend',
      'new',
      'popular',
    ]);
    expect(
      HomeFeedModel.empty.rankedProducts([product('catalog')]).map((p) => p.id),
      ['catalog'],
    );
  });

  test(
    'personalized discoveries never reintroduce excluded catalog products',
    () {
      ProductModel product(String id) =>
          ProductModel(id: id, name: id, price: '1', imageurl: '', status: '');
      final feed = HomeFeedModel(
        personalized: true,
        trendingProducts: [product('eligible')],
      );
      expect(feed.rankedProducts([product('purchased')]).map((p) => p.id), [
        'eligible',
      ]);
    },
  );

  test('feed sends bearer token only when present', () async {
    final requests = <http.Request>[];
    final tokens = ApiTokenStore(storage: MemorySecureStorage());
    final service = HomeFeedApiService(
      tokenStore: tokens,
      client: ApiClient(
        tokenStore: tokens,
        baseUrl: 'https://example.org/api/v1',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('{"data":{"personalized":true}}', 200);
        }),
      ),
    );
    await service.fetchFeed();
    expect(requests.last.headers['Authorization'], isNull);
    await tokens.saveTokens(accessToken: 'buyer-token');
    expect((await service.fetchFeed()).personalized, isTrue);
    expect(requests.last.headers['Authorization'], 'Bearer buyer-token');
    await tokens.clear();
  });

  test('public cache never persists personalized product order or flag', () {
    final snapshot = CatalogCacheSnapshot(
      stores: const [],
      homeStores: const [],
      products: const [],
      homeProducts: const [],
      categories: const [],
      homeFeed: HomeFeedModel(
        personalized: true,
        discoverProducts: [
          ProductModel(
            id: 'private',
            name: 'Buyer pick',
            price: '1',
            imageurl: '',
            status: '',
          ),
        ],
      ),
    );
    final encoded = encodeCatalogCache(snapshot);
    expect(encoded, isNot(contains('private')));
    expect(encoded, isNot(contains('Buyer pick')));
    expect(decodeCatalogCache(encoded)!.homeFeed.personalized, isFalse);
    // Previous cache versions could contain a user's recommendations.
    final legacy = jsonDecode(encoded) as Map<String, dynamic>;
    legacy['homeFeed'] = {
      'personalized': true,
      'discoverProducts': [
        {'id': 'private'},
      ],
    };
    expect(decodeCatalogCache(jsonEncode(legacy))!.homeFeed.isEmpty, isTrue);
    legacy.remove('version');
    expect(decodeCatalogCache(jsonEncode(legacy)), isNull);
  });

  test('logout clears a buyer-ranked in-memory feed', () {
    catalog.homeFeed = const HomeFeedModel(personalized: true);
    catalog.catalogRepository.clearUserData();
    expect(catalog.homeFeed.personalized, isFalse);
    expect(catalog.homeFeed.isEmpty, isTrue);
  });

  testWidgets('empty Balade reports loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BaladeHome(
            feed: HomeFeedModel.empty,
            catalogProducts: const [],
            catalogStores: const [],
            loading: true,
            onProductTap: (_) {},
            onStoreTap: (_) {},
            onAllProducts: () {},
            onAllStores: () {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    expect(find.text('Chargement des découvertes…'), findsOneWidget);
  });

  test(
    'search event is sent only for authenticated nonblank submission',
    () async {
      final requests = <http.Request>[];
      final tokens = ApiTokenStore(storage: MemorySecureStorage());
      final service = SearchEventApiService(
        tokenStore: tokens,
        client: ApiClient(
          tokenStore: tokens,
          baseUrl: 'https://example.org/api/v1',
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response('{}', 200);
          }),
        ),
      );
      await service.track(' chaussures ');
      expect(requests, isEmpty);
      await tokens.saveTokens(accessToken: 'buyer-token');
      await service.track('  ');
      await service.track('x');
      expect(requests, isEmpty);
      await service.track(' chaussures ', resultsCount: 3);
      expect(requests.single.url.path, '/api/v1/events/search');
      expect(requests.single.headers['Authorization'], 'Bearer buyer-token');
      expect(jsonDecode(requests.single.body)['query'], 'chaussures');
      expect(jsonDecode(requests.single.body)['results_count'], 3);
      await tokens.clear();
    },
  );

  testWidgets(
    'Balade uses feed products and stores, with honest discovery label',
    (tester) async {
      final product = ProductModel(
        id: '1',
        name: 'Sac réel',
        price: '900',
        imageurl: '',
        status: '',
      );
      final store = StoreModel(id: '2', name: 'Boutique réelle', image: '');
      Future<void> pump(bool personalized, {double width = 390}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                child: BaladeHome(
                  feed: HomeFeedModel(
                    personalized: personalized,
                    featuredStores: [store],
                    trendingProducts: [product],
                    discoverProducts: [product],
                  ),
                  catalogProducts: [product],
                  catalogStores: [store],
                  onProductTap: (_) {},
                  onStoreTap: (_) {},
                  onAllProducts: () {},
                  onAllStores: () {},
                  onRefresh: () async {},
                ),
              ),
            ),
          ),
        );
      }

      await pump(false);
      expect(find.text('À découvrir'), findsOneWidget);
      expect(find.text('Pour vous'), findsNothing);
      expect(find.text('Sac réel'), findsWidgets);
      expect(find.text('Boutique réelle'), findsWidgets);
      expect(find.text('La boutique à découvrir'), findsNothing);
      await pump(true);
      expect(find.text('Pour vous'), findsOneWidget);
      await pump(true, width: 320);
      expect(tester.takeException(), isNull);
    },
  );
}
