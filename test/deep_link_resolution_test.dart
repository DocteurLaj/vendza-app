import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/deep_link/deep_link_service.dart';
import 'package:vendza/core/services/deep_link/deep_link_content_resolver.dart';
import 'package:vendza/features/store/data/services/product_api_service.dart';
import 'package:vendza/features/store/data/services/store_api_service.dart';

Map<String, dynamic> _productJson(int id, {int storeId = 7}) => {
  'idproduct': id,
  'uuidproduct': 'product-$id',
  'title': 'Produit $id',
  'description': 'Description',
  'price': 12.5,
  'stock': 4,
  'is_active': true,
  'images': <String>[],
  'store_idstore': storeId,
};

Map<String, dynamic> _storeJson(int id) => {
  'idstore': id,
  'name': 'Boutique $id',
  'description': 'Description boutique',
  'image': '',
  'is_active': true,
};

class _FakeProductApi extends ProductApiService {
  _FakeProductApi(this.handler);

  final Future<Map<String, dynamic>> Function(int id) handler;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> productDetail(int productId) {
    calls++;
    return handler(productId);
  }
}

class _FakeStoreApi extends StoreApiService {
  _FakeStoreApi(this.handler);

  final Future<List<Map<String, dynamic>>> Function(int page, int pageSize)
  handler;
  final List<int> requestedPages = [];

  @override
  Future<List<Map<String, dynamic>>> browseStores({
    int page = 1,
    int pageSize = 50,
  }) {
    requestedPages.add(page);
    return handler(page, pageSize);
  }
}

void main() {
  setUp(() {
    products.clear();
    stores.clear();
    homeStores.clear();
  });

  tearDown(() {
    products.clear();
    stores.clear();
    homeStores.clear();
  });

  test('cache miss fetches product detail and owning store', () async {
    final productApi = _FakeProductApi((id) async => _productJson(id));
    final storeApi = _FakeStoreApi((page, pageSize) async => [_storeJson(7)]);
    final resolver = DeepLinkContentResolver(
      productApiService: productApi,
      storeApiService: storeApi,
    );

    final result = await resolver.resolveProduct('250');

    expect(result.product.id, '250');
    expect(result.product.storeId, '7');
    expect(result.product.storeName, 'Boutique 7');
    expect(result.store?.id, '7');
    expect(productApi.calls, 1);
  });

  test('product 404 is preserved as confirmed not found', () async {
    final resolver = DeepLinkContentResolver(
      productApiService: _FakeProductApi(
        (_) async => throw const ApiException(
          message: 'Produit introuvable',
          statusCode: 404,
        ),
      ),
      storeApiService: _FakeStoreApi((_, _) async => []),
    );

    await expectLater(
      resolver.resolveProduct('404'),
      throwsA(isA<DeepLinkNotFoundException>()),
    );
  });

  test(
    'network error remains retryable and is not converted to not found',
    () async {
      final resolver = DeepLinkContentResolver(
        productApiService: _FakeProductApi(
          (_) async => throw const ApiException(
            message: 'Service indisponible',
            statusCode: 503,
          ),
        ),
        storeApiService: _FakeStoreApi((_, _) async => []),
      );

      await expectLater(
        resolver.resolveProduct('8'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'status',
            503,
          ),
        ),
      );
    },
  );

  test(
    'store lookup follows public pagination beyond first 100 items',
    () async {
      final firstPage = List.generate(100, (index) => _storeJson(index + 1));
      final storeApi = _FakeStoreApi((page, pageSize) async {
        if (page == 1) return firstPage;
        if (page == 2) return [_storeJson(150)];
        return [];
      });
      final resolver = DeepLinkContentResolver(
        productApiService: _FakeProductApi((id) async => _productJson(id)),
        storeApiService: storeApi,
      );

      final store = await resolver.resolveStore('150');

      expect(store.id, '150');
      expect(store.name, 'Boutique 150');
      expect(storeApi.requestedPages, [1, 2]);
    },
  );

  testWidgets('cold-start link waits for navigation readiness', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final productCompleter = Completer<Map<String, dynamic>>();
    final productApi = _FakeProductApi((_) => productCompleter.future);
    final resolver = DeepLinkContentResolver(
      productApiService: productApi,
      storeApiService: _FakeStoreApi((_, _) async => [_storeJson(7)]),
    );
    final service = DeepLinkService.forTesting(
      navigatorKey: navigatorKey,
      resolver: resolver,
      productPageBuilder: (product) => Text('opened-${product.id}'),
      storePageBuilder: (store) => Text('store-${store.id}'),
    );
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('splash')),
      ),
    );
    service.handleUriForTesting(Uri.parse('vendza://p/250'));
    await tester.pump();

    expect(productApi.calls, 0);
    expect(find.text('splash'), findsOneWidget);

    service.markNavigationReady();
    await tester.pump();
    expect(productApi.calls, 1);

    productCompleter.complete(_productJson(250));
    await tester.pumpAndSettle();
    expect(find.text('opened-250'), findsOneWidget);
  });

  testWidgets('simultaneous duplicate links resolve and navigate once', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final productCompleter = Completer<Map<String, dynamic>>();
    final productApi = _FakeProductApi((_) => productCompleter.future);
    final resolver = DeepLinkContentResolver(
      productApiService: productApi,
      storeApiService: _FakeStoreApi((_, _) async => [_storeJson(7)]),
    );
    final service = DeepLinkService.forTesting(
      navigatorKey: navigatorKey,
      resolver: resolver,
      productPageBuilder: (product) => Text('opened-${product.id}'),
      storePageBuilder: (store) => Text('store-${store.id}'),
    );
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('home')),
      ),
    );
    service.markNavigationReady();
    service.handleUriForTesting(Uri.parse('vendza://p/9'));
    service.handleUriForTesting(Uri.parse('vendza://p/9'));
    await tester.pump();

    expect(productApi.calls, 1);
    productCompleter.complete(_productJson(9));
    await tester.pumpAndSettle();

    expect(find.text('opened-9'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isTrue);
  });

  testWidgets('outage shows retry and retry opens the product', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var attempt = 0;
    final productApi = _FakeProductApi((id) async {
      attempt++;
      if (attempt == 1) {
        throw const ApiException(message: 'offline', statusCode: 503);
      }
      return _productJson(id);
    });
    final service = DeepLinkService.forTesting(
      navigatorKey: navigatorKey,
      resolver: DeepLinkContentResolver(
        productApiService: productApi,
        storeApiService: _FakeStoreApi((_, _) async => [_storeJson(7)]),
      ),
      productPageBuilder: (product) => Text('opened-${product.id}'),
      storePageBuilder: (store) => Text('store-${store.id}'),
    );
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('home')),
      ),
    );
    service.markNavigationReady();
    service.handleUriForTesting(Uri.parse('vendza://p/8'));
    await tester.pumpAndSettle();

    expect(find.text('Impossible d’ouvrir ce contenu'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Contenu introuvable'), findsNothing);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(productApi.calls, 2);
    expect(find.text('opened-8'), findsOneWidget);
  });

  testWidgets('confirmed 404 shows not found without retry action', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final service = DeepLinkService.forTesting(
      navigatorKey: navigatorKey,
      resolver: DeepLinkContentResolver(
        productApiService: _FakeProductApi(
          (_) async =>
              throw const ApiException(message: 'missing', statusCode: 404),
        ),
        storeApiService: _FakeStoreApi((_, _) async => []),
      ),
      productPageBuilder: (product) => Text('opened-${product.id}'),
      storePageBuilder: (store) => Text('store-${store.id}'),
    );
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('home')),
      ),
    );
    service.markNavigationReady();
    service.handleUriForTesting(Uri.parse('vendza://p/404'));
    await tester.pumpAndSettle();

    expect(find.text('Contenu introuvable'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });
}
