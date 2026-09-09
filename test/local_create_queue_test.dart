import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/core/services/upload_api_service.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/core/sync/entity_sync_status.dart';
import 'package:vendza/core/sync/local_create_queue.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';
import 'package:vendza/features/profil/data/model/user_model.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/product_api_service.dart';
import 'package:vendza/features/store/data/services/store_api_service.dart';
import 'package:vendza/shared/models/product_model.dart';

class _FakeUploadApi extends UploadApiService {
  Object? error;
  var calls = 0;

  @override
  Future<String> uploadLocalImage(
    String localPath, {
    String purpose = 'catalog',
    void Function(double progress)? onProgress,
  }) async {
    calls += 1;
    onProgress?.call(1);
    final thrown = error;
    if (thrown != null) throw thrown;
    return 'https://cdn.vendza.test/$localPath.png';
  }
}

class _FakeStoreApi extends StoreApiService {
  final List<Map<String, dynamic>> stores = [];
  var createCalls = 0;

  @override
  Future<Map<String, dynamic>> createStore({
    required String name,
    String? description,
    String? address,
    String? image,
    String? bannerUrl,
    String? whatsappUrl,
    String? instagramUrl,
    String? facebookUrl,
  }) async {
    createCalls += 1;
    final created = {
      'idstore': 99,
      'name': name,
      'description': description ?? '',
      'address': address ?? '',
      'image': image ?? '',
      'bannerUrl': bannerUrl,
      'whatsappUrl': whatsappUrl,
      'instagramUrl': instagramUrl,
      'facebookUrl': facebookUrl,
    };
    stores.add(created);
    return created;
  }

  @override
  Future<List<Map<String, dynamic>>> myStores() async => stores;
}

class _FakeProductApi extends ProductApiService {
  final List<Map<String, dynamic>> products = [];
  var addCalls = 0;

  @override
  Future<Map<String, dynamic>> addProduct({
    required int storeId,
    required String title,
    String? description,
    required double price,
    required int stock,
    bool isActive = true,
    List<String>? images,
    Map<String, dynamic>? variation,
  }) async {
    addCalls += 1;
    products.add({
      'idproduct': 55,
      'title': title,
      'description': description ?? '',
      'price': price,
      'stock': stock,
      'is_active': isActive,
      'images': images ?? const <String>[],
      'variation': variation,
      'store_idstore': storeId,
    });
    return products.last;
  }

  @override
  Future<Map<String, dynamic>> productsForStore(
    int storeId, {
    bool includeInactive = false,
  }) async {
    return {
      'products': products
          .where((item) => item['store_idstore'] == storeId)
          .toList(),
    };
  }
}

class _FakeAuthApi extends AuthApiService {
  var becomeSellerCalls = 0;

  @override
  Future<Map<String, dynamic>> becomeSeller() async {
    becomeSellerCalls += 1;
    return {'ok': true};
  }
}

UserModel _user({int id = 7}) {
  return UserModel(
    userId: id,
    name: 'Ada Lovelace',
    lastname: 'Lovelace',
    firstname: 'Ada',
    address: '',
    email: 'ada@example.com',
    phoneNumber: '',
    urlimage: '',
  );
}

void main() {
  setUp(clearCurrentUser);
  test('local entity ids are namespaced', () {
    final id = newLocalEntityId('store');
    expect(isLocalEntityId(id), isTrue);
    expect(isLocalEntityId('42'), isFalse);
  });

  test('sync labels match the owner catalog copy', () {
    expect(EntitySyncStatus.queued.label, 'Envoi vers le serveur…');
    expect(EntitySyncStatus.syncing.label, 'Envoi vers le serveur…');
    expect(EntitySyncStatus.online.label, 'En ligne');
    expect(EntitySyncStatus.error.label, 'Échec de synchronisation');
  });

  test('local create operations survive json roundtrip', () {
    final op = LocalCreateOp(
      id: 'local-store-1',
      kind: LocalCreateKind.store,
      payload: {'name': 'Zira', 'imagePath': '/tmp/logo.jpg'},
      userId: 7,
      createRequestSent: true,
    );

    final restored = LocalCreateOp.fromJson(op.toJson());
    expect(restored.id, 'local-store-1');
    expect(restored.kind, LocalCreateKind.store);
    expect(restored.payload['name'], 'Zira');
    expect(restored.userId, 7);
    expect(restored.createRequestSent, isTrue);
    expect(restored.entityStatus, EntitySyncStatus.queued);
  });

  test('remote image urls skip a second upload', () async {
    final url = 'https://cdn.vendza.test/store.jpg';
    expect(isRemoteMediaUrl(url), isTrue);
    expect(isRemoteMediaUrl('/data/user/0/logo.jpg'), isFalse);
    expect(
      await UploadApiService().uploadLocalImage(url),
      url,
    );
  });

  test('missing local image is not treated as a network outage', () {
    expect(
      isNetworkFailure(
        const ApiException(message: 'Image locale introuvable.'),
      ),
      isFalse,
    );
    expect(
      isNetworkFailure(const ApiException(message: 'La requete a expire.', statusCode: 408)),
      isTrue,
    );
  });

  test('syncing bar uses real progress and shows a percent label', () {
    expect(EntitySyncStatus.syncing.barValue(0.42), closeTo(0.42, 0.001));
    expect(EntitySyncStatus.queued.barValue(0.08), isNull);
    expect(
      EntitySyncStatus.syncing.labelWithProgress(0.42),
      'Envoi vers le serveur… 42%',
    );
  });

  test('retryFailedCreates replays stale failed store creates once API recovers', () async {
    updateCurrentUser(_user());
    final uploads = _FakeUploadApi()
      ..error = const ApiException(
        message: 'Endpoint /uploads/images/complete introuvable.',
        statusCode: 404,
      );
    final storesApi = _FakeStoreApi();
    final queue = LocalCreateQueue(
      uploads: uploads,
      stores: storesApi,
      products: _FakeProductApi(),
      auth: _FakeAuthApi(),
      onChanged: () {},
      storeFromApi: listStoreFromApi,
    );
    final ownedStores = <ListStoreModel>[];
    final products = <ProductModel>[];
    queue.attachCatalog(
      ownedStores: ownedStores,
      products: products,
      publicStores: <ListStoreModel>[],
      homeProducts: <ProductModel>[],
    );

    final optimistic = await queue.enqueueStore(
      name: 'Boutique Web',
      description: 'Création web',
      address: 'Port-au-Prince',
      imagePath: 'logo-web',
    );
    await pumpEventQueue(times: 20);

    expect(queue.opFor(optimistic.localId), isNotNull);
    expect(queue.opFor(optimistic.localId)!.status, LocalCreatePhase.failed);
    expect(storesApi.createCalls, 0);

    uploads.error = null;
    await queue.retryFailedCreates();

    expect(queue.opFor(optimistic.localId), isNull);
    expect(storesApi.createCalls, 1);
    expect(ownedStores.single.id, '99');
    expect(ownedStores.single.syncStatus, EntitySyncStatus.online);
  });

  test('numeric store id product create is queued even when owned cache is stale', () async {
    updateCurrentUser(_user());
    final productsApi = _FakeProductApi();
    final queue = LocalCreateQueue(
      uploads: _FakeUploadApi(),
      stores: _FakeStoreApi(),
      products: productsApi,
      auth: _FakeAuthApi(),
      onChanged: () {},
      storeFromApi: listStoreFromApi,
    );
    final products = <ProductModel>[];
    queue.attachCatalog(
      ownedStores: <ListStoreModel>[],
      products: products,
      publicStores: <ListStoreModel>[],
      homeProducts: <ProductModel>[],
    );

    final optimistic = await queue.enqueueProduct(
      storeId: '99',
      storeName: 'Boutique Web',
      title: 'Produit Web',
      description: 'Création web',
      price: '10',
      numericPrice: 10,
      imagePath: 'produit-web',
    );
    await pumpEventQueue(times: 20);

    expect(optimistic.storeId, '99');
    expect(productsApi.addCalls, 1);
    expect(products.single.id, '55');
  });

  test('retryFailedCreates replays stale failed product creates once API recovers', () async {
    updateCurrentUser(_user());
    final uploads = _FakeUploadApi()
      ..error = const ApiException(
        message: 'Endpoint /uploads/images/complete introuvable.',
        statusCode: 404,
      );
    final productsApi = _FakeProductApi();
    final queue = LocalCreateQueue(
      uploads: uploads,
      stores: _FakeStoreApi(),
      products: productsApi,
      auth: _FakeAuthApi(),
      onChanged: () {},
      storeFromApi: listStoreFromApi,
    );
    final ownedStores = <ListStoreModel>[
      ListStoreModel(
        id: '99',
        name: 'Boutique Web',
        description: '',
        imageUrl: '',
        rating: 0,
        city: '',
      ),
    ];
    final products = <ProductModel>[];
    queue.attachCatalog(
      ownedStores: ownedStores,
      products: products,
      publicStores: <ListStoreModel>[],
      homeProducts: <ProductModel>[],
    );

    final optimistic = await queue.enqueueProduct(
      storeId: '99',
      storeName: 'Boutique Web',
      title: 'Produit Web',
      description: 'Création web',
      price: '10',
      numericPrice: 10,
      imagePath: 'produit-web',
    );
    await pumpEventQueue(times: 20);

    expect(queue.opFor(optimistic.localId), isNotNull);
    expect(queue.opFor(optimistic.localId)!.status, LocalCreatePhase.failed);
    expect(productsApi.addCalls, 0);

    uploads.error = null;
    await queue.retryFailedCreates();

    expect(queue.opFor(optimistic.localId), isNull);
    expect(productsApi.addCalls, 1);
    expect(products.single.id, '55');
    expect(products.single.syncStatus, EntitySyncStatus.online);
  });
}
