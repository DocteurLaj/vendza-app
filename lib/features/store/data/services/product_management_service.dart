import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/features/collection/data/services/data_exemple.dart'
    as collection_data;
import 'package:vendza/features/home/data/models/store_model.dart' as detail;
import 'package:vendza/features/home/data/services/data_exemple.dart'
    as home_data;
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart'
    as store_data;
import 'package:vendza/shared/models/product_model.dart';

List<ProductModel> activeProducts(Iterable<ProductModel> source) {
  return source.where((product) => product.isActive).toList();
}

String get ownerPrimaryStoreId {
  return store_data.stores.isEmpty ? "" : store_data.stores.first.id;
}

List<ProductModel> productsForStoreId(String storeId) {
  final normalizedStoreId = storeId.trim();
  if (normalizedStoreId.isEmpty) return const [];

  return store_data.products
      .where((product) => product.storeId == normalizedStoreId)
      .toList();
}

List<ProductModel> activeProductsForStoreId(String storeId) {
  return activeProducts(productsForStoreId(storeId));
}

List<ProductModel> productsForStore(ListStoreModel store) {
  return productsForStoreId(store.id);
}

List<ProductModel> activeProductsForStore(ListStoreModel store) {
  return activeProductsForStoreId(store.id);
}

String resolveStoreId(detail.StoreModel store) {
  if (store.id.trim().isNotEmpty) return store.id.trim();

  for (final item in store_data.stores) {
    if (item.name.trim().toLowerCase() == store.name.trim().toLowerCase()) {
      return item.id;
    }
  }

  return "";
}

List<ProductModel> productsForDetailStore(detail.StoreModel store) {
  return productsForStoreId(resolveStoreId(store));
}

List<ProductModel> activeProductsForDetailStore(detail.StoreModel store) {
  return activeProducts(productsForDetailStore(store));
}

void updateManagedProduct(ProductModel updatedProduct) {
  _replaceProductInList(store_data.products, updatedProduct);
  if (updatedProduct.isActive) {
    _replaceProductInList(home_data.products, updatedProduct);
    if (!home_data.products.any(
      (item) => _isSameProduct(item, updatedProduct),
    )) {
      home_data.products.insert(0, updatedProduct);
    }
  } else {
    home_data.products.removeWhere(
      (item) => _isSameProduct(item, updatedProduct),
    );
  }

  for (final entry in collection_data.collectionProducts.entries) {
    if (updatedProduct.isActive) {
      entry.value.replaceWhere(
        (product) => product.id == updatedProduct.id,
        updatedProduct,
      );
    } else {
      entry.value.removeWhere((product) => product.id == updatedProduct.id);
    }
  }

  if (updatedProduct.storeId == ownerPrimaryStoreId ||
      isOwnedStoreId(updatedProduct.storeId)) {
    final customization = store_data.customizationForStore(
      updatedProduct.storeId,
    );
    final featuredProducts = updatedProduct.isActive
        ? customization.featuredProducts.map((product) {
            return product.id == updatedProduct.id ? updatedProduct : product;
          }).toList()
        : customization.featuredProducts
              .where((product) => product.id != updatedProduct.id)
              .toList();

    store_data.updateStoreCustomizationForStore(
      updatedProduct.storeId,
      customization.copyWith(featuredProducts: featuredProducts),
    );
  }

  catalogRevision.value++;
}

void setManagedProductActive(ProductModel product, bool isActive) {
  updateManagedProduct(product.copyWith(isActive: isActive));
}

void deleteManagedProduct(ProductModel product) {
  store_data.products.removeWhere((item) => item.id == product.id);
  home_data.products.removeWhere((item) => item.id == product.id);

  for (final entry in collection_data.collectionProducts.entries) {
    entry.value.removeWhere((item) => item.id == product.id);
  }

  if (product.storeId == ownerPrimaryStoreId ||
      isOwnedStoreId(product.storeId)) {
    final customization = store_data.customizationForStore(product.storeId);
    store_data.updateStoreCustomizationForStore(
      product.storeId,
      customization.copyWith(
        featuredProducts: customization.featuredProducts
            .where((item) => item.id != product.id)
            .toList(),
      ),
    );
  }

  catalogRevision.value++;
}

Future<ProductModel> persistManagedProductUpdate(
  ProductModel updatedProduct,
) async {
  await catalogRepository.persistProductUpdate(updatedProduct);
  updateManagedProduct(updatedProduct);
  return updatedProduct;
}

Future<void> persistManagedProductDelete(ProductModel product) async {
  await catalogRepository.persistProductDelete(product);
  deleteManagedProduct(product);
}

void _replaceProductInList(List<ProductModel> source, ProductModel product) {
  source.replaceWhere((item) => _isSameProduct(item, product), product);
}

bool _isSameProduct(ProductModel left, ProductModel right) {
  if (left.id == right.id) return true;

  return left.name == right.name &&
      left.storeId == right.storeId &&
      left.storeName == right.storeName;
}

extension _ReplaceProductList on List<ProductModel> {
  void replaceWhere(
    bool Function(ProductModel product) test,
    ProductModel item,
  ) {
    for (int index = 0; index < length; index++) {
      if (test(this[index])) {
        this[index] = item;
      }
    }
  }
}
