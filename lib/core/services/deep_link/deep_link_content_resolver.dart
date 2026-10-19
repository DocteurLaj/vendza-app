import 'package:vendza/core/catalog/catalog_repository.dart' as catalog;
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/core/services/deep_link/catalog_lookup.dart';
import 'package:vendza/features/home/data/models/store_model.dart' as home;
import 'package:vendza/features/store/data/services/product_api_service.dart';
import 'package:vendza/features/store/data/services/store_api_service.dart';
import 'package:vendza/shared/models/product_model.dart';

/// The link points to content that the API confirmed does not exist (404),
/// or that is not publicly listed. Unlike network errors, retrying is useless.
class DeepLinkNotFoundException implements Exception {
  const DeepLinkNotFoundException(this.message);

  final String message;

  @override
  String toString() => 'DeepLinkNotFoundException: $message';
}

class ResolvedProductLink {
  const ResolvedProductLink({required this.product, required this.store});

  final ProductModel product;
  final home.StoreModel? store;
}

/// Resolves deep-link ids to content (#106).
///
/// The in-memory catalog is only a cache: it holds the first page of the
/// catalog and is empty on cold start. On a cache miss we ask the API, so
/// links keep working beyond the first 100 products and before the catalog
/// has finished loading.
class DeepLinkContentResolver {
  DeepLinkContentResolver({
    ProductApiService? productApiService,
    StoreApiService? storeApiService,
  }) : _productApi = productApiService ?? ProductApiService(),
       _storeApi = storeApiService ?? StoreApiService();

  final ProductApiService _productApi;
  final StoreApiService _storeApi;

  static const int _storePageSize = 100;
  static const int _maxStorePages = 50;

  Future<ResolvedProductLink> resolveProduct(String id) async {
    final cached = findProductById(id);
    if (cached != null) {
      return ResolvedProductLink(
        product: cached,
        store: cached.storeId.isEmpty ? null : findStoreById(cached.storeId),
      );
    }

    final productId = int.tryParse(id);
    if (productId == null) {
      throw const DeepLinkNotFoundException('Identifiant produit invalide');
    }

    final Map<String, dynamic> json;
    try {
      json = await _productApi.productDetail(productId);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        throw const DeepLinkNotFoundException('Produit introuvable');
      }
      rethrow;
    }

    final storeId = '${json['store_idstore'] ?? ''}';
    home.StoreModel? store;
    if (storeId.isNotEmpty) {
      try {
        store = await resolveStore(storeId);
      } on DeepLinkNotFoundException {
        // The product itself is public; open it without store context.
        store = null;
      }
    }
    final product = productFromApi(json, storeName: store?.name ?? '');
    return ResolvedProductLink(product: product, store: store);
  }

  Future<home.StoreModel> resolveStore(String id) async {
    final cached = findStoreById(id);
    if (cached != null) return cached;
    if (int.tryParse(id) == null) {
      throw const DeepLinkNotFoundException('Identifiant boutique invalide');
    }

    // The API has no public store-detail route, so page through the public
    // listing until the store is found or the listing ends.
    for (var page = 1; page <= _maxStorePages; page++) {
      final rows = await _storeApi.browseStores(
        page: page,
        pageSize: _storePageSize,
      );
      for (final row in rows) {
        if ('${row['idstore']}' == id) {
          final store = homeStoreFromApi(row);
          if (!catalog.homeStores.any((s) => s.id == store.id)) {
            catalog.homeStores.add(store);
          }
          return store;
        }
      }
      if (rows.length < _storePageSize) break;
    }
    throw const DeepLinkNotFoundException('Boutique introuvable');
  }
}
