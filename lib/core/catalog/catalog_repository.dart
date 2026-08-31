import 'package:flutter/foundation.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/services/favorite_api_service.dart';
import 'package:vendza/core/services/upload_api_service.dart';
import 'package:vendza/core/sync/entity_sync_status.dart';
import 'package:vendza/core/sync/local_create_queue.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';
import 'package:vendza/core/session/liked_products_store.dart';
import 'package:vendza/features/cathegory/data/services/category_store.dart';
import 'package:vendza/features/home/data/models/home_feed_model.dart';
import 'package:vendza/features/home/data/models/store_model.dart' as home;
import 'package:vendza/features/home/data/services/home_feed_api_service.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_api_service.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/product_api_service.dart';
import 'package:vendza/features/store/data/services/store_api_service.dart';
import 'package:vendza/features/store/data/services/store_customization_state.dart';
import 'package:vendza/shared/models/product_model.dart';

/// Shared in-memory catalog populated from the Vendza API.
final List<ListStoreModel> stores = [];

/// Stores owned by the currently authenticated user only.
final List<ListStoreModel> ownedStores = [];
final List<ListStoreModel> favoriteStores = [];
final List<ProductModel> products = [];
final List<home.StoreModel> homeStores = [];
final List<ProductModel> homeProducts = [];
HomeFeedModel homeFeed = HomeFeedModel.empty;

final ValueNotifier<int> catalogRevision = ValueNotifier<int>(0);
final ValueNotifier<int> favoriteStoreChanges = ValueNotifier<int>(0);
final ValueNotifier<bool> catalogLoading = ValueNotifier<bool>(false);
final ValueNotifier<String?> catalogError = ValueNotifier<String?>(null);

bool isOwnedStoreId(String storeId) {
  final id = storeId.trim();
  if (id.isEmpty) return false;
  return ownedStores.any((store) => store.id == id || store.localId == id);
}

class CatalogRepository {
  CatalogRepository({
    StoreApiService? storeApiService,
    ProductApiService? productApiService,
    HomeFeedApiService? homeFeedApiService,
    FavoriteApiService? favoritesApi,
    NotificationApiService? notificationApiService,
    UploadApiService? uploadsApi,
    ApiTokenStore? tokenStore,
    AuthApiService? authApi,
  }) : _storeApi = storeApiService ?? StoreApiService(),
       _productApi = productApiService ?? ProductApiService(),
       _homeFeedApi = homeFeedApiService ?? HomeFeedApiService(),
       _favoriteApi = favoritesApi ?? favoriteApiService,
       _notificationApi = notificationApiService ?? NotificationApiService(),
       _uploadApi = uploadsApi ?? uploadApiService,
       _tokenStore = tokenStore ?? apiTokenStore {
    _localCreates = LocalCreateQueue(
      uploads: _uploadApi,
      stores: _storeApi,
      products: _productApi,
      auth: authApi ?? AuthApiService(),
      onChanged: _notifyChanged,
      storeFromApi: listStoreFromApi,
    );
    _localCreates.attachCatalog(
      ownedStores: ownedStores,
      products: products,
      publicStores: stores,
      homeProducts: homeProducts,
    );
  }

  final StoreApiService _storeApi;
  final ProductApiService _productApi;
  final HomeFeedApiService _homeFeedApi;
  final FavoriteApiService _favoriteApi;
  final NotificationApiService _notificationApi;
  final UploadApiService _uploadApi;
  final ApiTokenStore _tokenStore;
  late final LocalCreateQueue _localCreates;

  Future<void>? _inFlightRefresh;
  DateTime? _lastRefreshAt;
  static const Duration softRefreshDebounce = Duration(seconds: 5);

  /// Pull-to-refresh / resume / polling entry point.
  /// Shares one in-flight request and debounces rapid triggers.
  Future<void> softRefreshCatalog({bool force = false}) async {
    if (_inFlightRefresh != null) {
      await _inFlightRefresh;
      return;
    }

    final lastRefresh = _lastRefreshAt;
    if (!force &&
        lastRefresh != null &&
        DateTime.now().difference(lastRefresh) < softRefreshDebounce) {
      return;
    }

    final future = _runCatalogRefresh();
    _inFlightRefresh = future;
    try {
      await future;
    } finally {
      if (identical(_inFlightRefresh, future)) {
        _inFlightRefresh = null;
      }
    }
  }

  Future<void> refreshCatalog() => softRefreshCatalog(force: true);

  Future<void> _runCatalogRefresh() async {
    catalogLoading.value = true;
    catalogError.value = null;

    try {
      final browseStores = await _storeApi.browseStores(pageSize: 100);
      final mappedStores = browseStores.map(listStoreFromApi).toList();
      final mappedHomeStores = browseStores.map(homeStoreFromApi).toList();
      final storeNames = {
        for (final store in mappedStores) store.id: store.name,
      };

      final searchResults = await _productApi.searchProducts(pageSize: 100);
      final mappedProducts = searchResults
          .map(
            (item) => productFromApi(
              item,
              storeName: storeNames[item['store_idstore']?.toString()] ?? '',
            ),
          )
          .toList();

      stores
        ..clear()
        ..addAll(mappedStores);
      homeStores
        ..clear()
        ..addAll(mappedHomeStores);
      products
        ..clear()
        ..addAll(mappedProducts);
      homeProducts
        ..clear()
        ..addAll(mappedProducts);
      await _hydratePublicStoreProducts(mappedStores);

      try {
        homeFeed = await _homeFeedApi.fetchFeed(storeNames: storeNames);
      } on Object {
        homeFeed = HomeFeedModel.empty;
      }

      if (_tokenStore.hasAccessToken) {
        await refreshOwnedStores();
        await refreshFavorites();
      } else {
        ownedStores.clear();
      }

      await refreshCategories();
      syncStoreCustomizationFromCatalog();
      _hydratePendingCreates();
      _lastRefreshAt = DateTime.now();
      _notifyChanged();
      _localCreates.process();
    } on Object catch (error) {
      catalogError.value = error.toString();
    } finally {
      catalogLoading.value = false;
    }
  }

  Future<void> refreshOwnedStores() async {
    if (!_tokenStore.hasAccessToken) {
      ownedStores.clear();
      _notifyChanged();
      return;
    }

    final owned = await _storeApi.myStores();
    final mappedOwned = owned.map(listStoreFromApi).toList();

    ownedStores
      ..clear()
      ..addAll(mappedOwned);

    // Keep public catalog in sync for discovery, without treating it as ownership.
    for (int index = 0; index < mappedOwned.length; index++) {
      final ownedStore = mappedOwned[index];
      final rawStore = owned[index];
      final existingIndex = stores.indexWhere(
        (store) => store.id == ownedStore.id,
      );
      if (existingIndex >= 0) {
        stores[existingIndex] = ownedStore;
      } else {
        stores.insert(0, ownedStore);
      }

      final homeIndex = homeStores.indexWhere(
        (store) => store.id == ownedStore.id,
      );
      final homeStore = homeStoreFromApi(rawStore);
      if (homeIndex >= 0) {
        homeStores[homeIndex] = homeStore;
      } else {
        homeStores.insert(0, homeStore);
      }

      await _loadProductsForStore(ownedStore);
    }

    _hydratePendingCreates();
    _notifyChanged();
  }

  Future<void> refreshFavorites() async {
    if (!_tokenStore.hasAccessToken) return;

    final favorites = await _favoriteApi.listFavorites(pageSize: 100);
    likedProductIdsStore.value = favorites.map((product) => product.id).toSet();
    final storesResponse = await _favoriteApi.listStoreFavorites(pageSize: 100);
    favoriteStores
      ..clear()
      ..addAll(storesResponse);
    favoriteStoreChanges.value++;
  }

  Future<void> refreshNotifications(int userId) async {
    if (userId <= 0 || !_tokenStore.hasAccessToken) {
      notificationStore.value = <NotificationModel>[];
      return;
    }
    try {
      final items = await _notificationApi.notificationsForCurrentUser();
      notificationStore.value = items.map(notificationFromApi).toList();
    } on Object {
      // Inbox is optional: never block login/session restore on this call.
      notificationStore.value = <NotificationModel>[];
    }
  }

  void clearUserData() {
    ownedStores.clear();
    favoriteStores.clear();
    likedProductIdsStore.value = <String>{};
    notificationStore.value = <NotificationModel>[];
    syncStoreCustomizationFromCatalog();
    favoriteStoreChanges.value++;
    _notifyChanged();
  }

  Future<ListStoreModel> createStore({
    required String name,
    required String description,
    required String address,
    required String imagePath,
    String? bannerPath,
    String? whatsappUrl,
    String? instagramUrl,
    String? facebookUrl,
  }) {
    return _localCreates.enqueueStore(
      name: name,
      description: description,
      address: address,
      imagePath: imagePath,
      bannerPath: bannerPath,
      whatsappUrl: whatsappUrl,
      instagramUrl: instagramUrl,
      facebookUrl: facebookUrl,
    );
  }

  Future<ProductModel> createProduct({
    required int storeId,
    required String storeName,
    required String title,
    required String description,
    required double price,
    required int stock,
    required String imagePath,
    String category = '',
    Map<String, dynamic>? variation,
  }) {
    return enqueueCreateProduct(
      storeId: storeId.toString(),
      storeName: storeName,
      title: title,
      description: description,
      price: price.toString(),
      numericPrice: price,
      imagePath: imagePath,
      category: category,
      variation: variation,
    );
  }

  Future<ProductModel> enqueueCreateProduct({
    required String storeId,
    required String storeName,
    required String title,
    required String description,
    required String price,
    required double numericPrice,
    required String imagePath,
    String category = '',
    Map<String, dynamic>? variation,
  }) {
    if (!isOwnedStoreId(storeId)) {
      throw StateError(
        'Vous ne pouvez ajouter un produit que dans votre propre boutique.',
      );
    }
    return _localCreates.enqueueProduct(
      storeId: storeId,
      storeName: storeName,
      title: title,
      description: description,
      price: price,
      numericPrice: numericPrice,
      imagePath: imagePath,
      category: category,
      variation: variation,
    );
  }

  Future<void> startLocalSync() async {
    _localCreates.attachCatalog(
      ownedStores: ownedStores,
      products: products,
      publicStores: stores,
      homeProducts: homeProducts,
    );
    await _localCreates.start();
    _hydratePendingCreates();
    _notifyChanged();
  }

  Future<void> retryLocalCreate(String id) => _localCreates.retry(id);

  Future<void> discardLocalCreate(String id) async {
    await _localCreates.discard(id);
    ownedStores.removeWhere((store) => store.id == id || store.localId == id);
    products.removeWhere(
      (product) =>
          product.id == id ||
          product.localId == id ||
          product.storeId == id,
    );
    _notifyChanged();
  }

  void _hydratePendingCreates() {
    if (!_tokenStore.hasAccessToken) return;
    _localCreates.rehydrate(ownedStores: ownedStores, products: products);
  }

  Future<void> toggleProductFavorite(String productId) async {
    final parsedId = int.tryParse(productId);
    if (parsedId == null || !_tokenStore.hasAccessToken) {
      toggleLikedProduct(productId);
      return;
    }

    if (isProductLiked(productId)) {
      await _favoriteApi.removeFavorite(parsedId);
      final updated = Set<String>.from(likedProductIdsStore.value)
        ..remove(productId);
      likedProductIdsStore.value = updated;
      return;
    }

    await _favoriteApi.addFavorite(parsedId);
    final updated = Set<String>.from(likedProductIdsStore.value)
      ..add(productId);
    likedProductIdsStore.value = updated;
  }

  Future<bool> toggleStoreFavorite(String storeId) async {
    if (!_tokenStore.hasAccessToken) {
      throw StateError('Connectez-vous pour gérer vos boutiques favorites.');
    }
    final parsedId = int.tryParse(storeId);
    if (parsedId == null) {
      throw ArgumentError('Identifiant de boutique invalide.');
    }

    final existingIndex = favoriteStores.indexWhere(
      (store) => store.id == storeId,
    );
    if (existingIndex >= 0) {
      await _favoriteApi.removeStoreFavorite(parsedId);
      favoriteStores.removeAt(existingIndex);
      favoriteStoreChanges.value++;
      return false;
    }

    await _favoriteApi.addStoreFavorite(parsedId);
    final store = stores.where((item) => item.id == storeId).firstOrNull;
    if (store != null) {
      favoriteStores.insert(0, store);
    } else {
      await refreshFavorites();
    }
    favoriteStoreChanges.value++;
    return true;
  }

  Future<void> _hydratePublicStoreProducts(List<ListStoreModel> stores) async {
    const chunkSize = 6;
    final targets = stores.take(24).toList();
    for (var index = 0; index < targets.length; index += chunkSize) {
      final chunk = targets.skip(index).take(chunkSize);
      await Future.wait(chunk.map(_mergePublicStoreProducts));
    }
  }

  Future<void> _mergePublicStoreProducts(ListStoreModel store) async {
    final storeId = int.tryParse(store.id);
    if (storeId == null) return;

    try {
      final response = await _productApi.productsForStore(storeId);
      final storeProducts = _productApi
          .parseProductsForStore(response, storeName: store.name)
          .where((product) => product.isActive)
          .toList();
      if (storeProducts.isEmpty) return;

      final existingIds = {
        ...homeProducts.map((product) => product.id),
        ...products.map((product) => product.id),
      };
      final fresh = storeProducts
          .where((product) => !existingIds.contains(product.id))
          .toList();
      if (fresh.isEmpty) return;

      homeProducts.addAll(fresh);
      products.addAll(fresh);
    } on Object {
      // Best-effort: a single store must not block the home catalog.
    }
  }

  Future<void> _loadProductsForStore(ListStoreModel store) async {
    final storeId = int.tryParse(store.id);
    if (storeId == null) return;

    final response = await _productApi.productsForStore(
      storeId,
      includeInactive: true,
    );
    final storeProducts = _productApi.parseProductsForStore(
      response,
      storeName: store.name,
    );
    final publicProducts = storeProducts
        .where((product) => product.isActive)
        .toList();

    products.removeWhere((product) => product.storeId == store.id);
    homeProducts.removeWhere((product) => product.storeId == store.id);
    // Owner inventory keeps inactive items; public catalog only active ones.
    products.insertAll(0, storeProducts);
    homeProducts.insertAll(0, publicProducts);
    _hydratePendingCreates();
  }

  Future<void> persistProductUpdate(ProductModel product) async {
    if (isLocalEntityId(product.id)) {
      await _localCreates.updateProductPayload(product);
      final index = products.indexWhere(
        (item) => item.id == product.id || item.localId == product.localId,
      );
      if (index >= 0) products[index] = product;
      _notifyChanged();
      return;
    }
    await _localCreates.enqueueProductUpdate(product);
  }

  Future<void> persistProductDelete(ProductModel product) async {
    if (product.syncStatus.isPending || isLocalEntityId(product.id)) {
      await discardLocalCreate(
        product.localId.isNotEmpty ? product.localId : product.id,
      );
      return;
    }
    final storeId = int.tryParse(product.storeId);
    final productId = int.tryParse(product.id);
    if (storeId == null || productId == null) {
      throw ArgumentError('Identifiant produit ou boutique invalide.');
    }

    await _productApi.deleteProduct(storeId: storeId, productId: productId);
    await softRefreshCatalog(force: true);
  }

  void _notifyChanged() {
    catalogRevision.value++;
    favoriteStoreChanges.value++;
  }
}

final catalogRepository = CatalogRepository();

/// Notifications loaded from API (replaces seeded mock list).
final ValueNotifier<List<NotificationModel>> notificationStore =
    ValueNotifier<List<NotificationModel>>([]);

Future<void> bootstrapCatalog() async {
  await catalogRepository.refreshCatalog();
  await catalogRepository.startLocalSync();
}

Future<void> bootstrapSessionCatalog({required int userId}) async {
  await catalogRepository.refreshCatalog();
  if (userId > 0) {
    await catalogRepository.refreshNotifications(userId);
  }
}
