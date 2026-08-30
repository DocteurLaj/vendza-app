import 'package:flutter/foundation.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/services/favorite_api_service.dart';
import 'package:vendza/core/services/upload_api_service.dart';
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
  return ownedStores.any((store) => store.id == id);
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
  }) : _storeApi = storeApiService ?? StoreApiService(),
       _productApi = productApiService ?? ProductApiService(),
       _homeFeedApi = homeFeedApiService ?? HomeFeedApiService(),
       _favoriteApi = favoritesApi ?? favoriteApiService,
       _notificationApi = notificationApiService ?? NotificationApiService(),
       _uploadApi = uploadsApi ?? uploadApiService,
       _tokenStore = tokenStore ?? apiTokenStore;

  final StoreApiService _storeApi;
  final ProductApiService _productApi;
  final HomeFeedApiService _homeFeedApi;
  final FavoriteApiService _favoriteApi;
  final NotificationApiService _notificationApi;
  final UploadApiService _uploadApi;
  final ApiTokenStore _tokenStore;

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
      _lastRefreshAt = DateTime.now();
      _notifyChanged();
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
  }) async {
    final imageUrl = await _uploadApi.resolveImageUrl(imagePath);
    final bannerUrl = bannerPath == null || bannerPath.trim().isEmpty
        ? null
        : await _uploadApi.resolveImageUrl(bannerPath);

    final created = await _storeApi.createStore(
      name: name,
      description: description,
      address: address,
      image: imageUrl,
      bannerUrl: bannerUrl,
      whatsappUrl: whatsappUrl,
      instagramUrl: instagramUrl,
      facebookUrl: facebookUrl,
    );

    final store = listStoreFromApi(created);
    ownedStores.insert(0, store);
    stores.insert(0, store);
    homeStores.insert(0, homeStoreFromApi(created));
    _notifyChanged();
    await softRefreshCatalog(force: true);
    return store;
  }

  Future<ProductModel> createProduct({
    required int storeId,
    required String storeName,
    required String title,
    required String description,
    required double price,
    required int stock,
    required String imagePath,
    Map<String, dynamic>? variation,
  }) async {
    if (!isOwnedStoreId(storeId.toString())) {
      throw StateError(
        'Vous ne pouvez ajouter un produit que dans votre propre boutique.',
      );
    }
    final imageUrl = await _uploadApi.resolveImageUrl(imagePath);
    await _productApi.addProduct(
      storeId: storeId,
      title: title,
      description: description,
      price: price,
      stock: stock,
      images: [imageUrl],
      variation: variation,
    );

    final response = await _productApi.productsForStore(storeId);
    final createdProducts = _productApi.parseProductsForStore(
      response,
      storeName: storeName,
    );
    if (createdProducts.isEmpty) {
      throw StateError('Produit créé mais introuvable dans le catalogue.');
    }

    final created = createdProducts.firstWhere(
      (product) => product.name == title,
      orElse: () => createdProducts.first,
    );

    products.insert(0, created);
    homeProducts.insert(0, created);
    _notifyChanged();
    await softRefreshCatalog(force: true);
    return created;
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
  }

  Future<void> persistProductUpdate(ProductModel product) async {
    final storeId = int.tryParse(product.storeId);
    final productId = int.tryParse(product.id);
    if (storeId == null || productId == null) {
      throw ArgumentError('Identifiant produit ou boutique invalide.');
    }

    final priceDigits = product.price.replaceAll(RegExp(r'[^\d.]'), '');
    final price = double.tryParse(priceDigits);
    final variation = product.variants.isEmpty
        ? null
        : {
            for (final variant in product.variants)
              variant.name: {
                'price': variant.price,
                'quantity': variant.quantity,
                'image': variant.imageurl,
              },
          };

    await _productApi.updateProduct(
      storeId: storeId,
      productId: productId,
      title: product.name,
      description: product.description,
      price: price,
      isActive: product.isActive,
      images: product.imageurl.trim().isEmpty ? null : [product.imageurl],
      variation: variation,
    );
    await softRefreshCatalog(force: true);
  }

  Future<void> persistProductDelete(ProductModel product) async {
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
}

Future<void> bootstrapSessionCatalog({required int userId}) async {
  await catalogRepository.refreshCatalog();
  if (userId > 0) {
    await catalogRepository.refreshNotifications(userId);
  }
}
