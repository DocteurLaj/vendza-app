import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/home/data/services/data_exemple.dart'
    as home_catalog;
import 'package:vendza/features/store/data/models/store_model.dart'
    as list_store;
import 'package:vendza/features/store/data/services/data_exemple.dart'
    as store_catalog;
import 'package:vendza/shared/models/product_model.dart';

class CatalogSearchResults {
  const CatalogSearchResults({required this.stores, required this.products});

  final List<StoreModel> stores;
  final List<ProductModel> products;
}

String _normalize(String value) => value.toLowerCase().trim();

bool _containsQuery(String query, String value) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return true;
  return _normalize(value).contains(normalizedQuery);
}

bool matchesStoreListItem(String query, list_store.ListStoreModel store) {
  if (_normalize(query).isEmpty) return true;
  return _containsQuery(query, store.name) ||
      _containsQuery(query, store.description) ||
      _containsQuery(query, store.city);
}

List<ProductModel> searchProductsInList(
  String query,
  List<ProductModel> products,
) {
  final normalizedQuery = _normalize(query);
  final activeProducts = products.where((product) => product.isActive);
  if (normalizedQuery.isEmpty) {
    return activeProducts.toList();
  }

  return activeProducts.where((product) {
    return _containsQuery(query, product.name) ||
        _containsQuery(query, product.category) ||
        _containsQuery(query, product.storeName) ||
        _containsQuery(query, product.description);
  }).toList();
}

CatalogSearchResults searchCatalog(String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) {
    return const CatalogSearchResults(stores: [], products: []);
  }

  final matchedStores = <StoreModel>[];
  final seenStoreKeys = <String>{};

  for (final store in home_catalog.stores) {
    final matches =
        _containsQuery(query, store.name) ||
        _containsQuery(query, store.getDescription());
    if (!matches) continue;

    final key = store.id.isNotEmpty ? store.id : store.name;
    if (seenStoreKeys.add(key)) {
      matchedStores.add(store);
    }
  }

  final matchedProducts = <ProductModel>[];
  final seenProductIds = <String>{};

  void collectProducts(List<ProductModel> source) {
    for (final product in searchProductsInList(query, source)) {
      if (seenProductIds.add(product.id)) {
        matchedProducts.add(product);
      }
    }
  }

  collectProducts(home_catalog.products);
  collectProducts(store_catalog.products);

  return CatalogSearchResults(stores: matchedStores, products: matchedProducts);
}
