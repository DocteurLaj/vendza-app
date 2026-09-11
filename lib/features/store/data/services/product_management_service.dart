import 'package:vendza/core/services/product_event_api_service.dart';
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
  return source
      .where((product) => product.isActive && !product.adminDisabled)
      .toList();
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
  final storeId = resolveStoreId(store);
  if (storeId.isEmpty) return const [];
  return home_data.products
      .where((product) => product.storeId == storeId)
      .toList();
}

List<ProductModel> activeProductsForDetailStore(detail.StoreModel store) {
  return activeProducts(productsForDetailStore(store));
}

void updateManagedProduct(ProductModel updatedProduct) {
  for (int index = 0; index < store_data.products.length; index++) {
    if (store_data.products[index].id == updatedProduct.id) {
      store_data.products[index] = updatedProduct;
      break;
    }
  }

  for (final entry
      in collection_data
          .collectionProductsForStore(updatedProduct.storeId)
          .entries) {
    entry.value.replaceWhere(
      (product) => product.id == updatedProduct.id,
      updatedProduct,
    );
  }

  if (updatedProduct.storeId.isNotEmpty) {
    final customization = store_data.customizationForStore(
      updatedProduct.storeId,
    );
    final featuredProducts = customization.featuredProducts.map((product) {
      return product.id == updatedProduct.id ? updatedProduct : product;
    }).toList();

    store_data.updateStoreCustomizationForStore(
      updatedProduct.storeId,
      customization.copyWith(featuredProducts: featuredProducts),
    );
  }
}

void setManagedProductActive(ProductModel product, bool isActive) {
  if (product.adminDisabled && isActive) {
    return;
  }
  updateManagedProduct(product.copyWith(isActive: isActive));
}

ProductModel registerProductContactClick(ProductModel product) {
  productEventApiService.trackSafely(
    eventType: 'contact_click',
    productId: product.id,
  );
  final updatedProduct = product.copyWith(
    contactClicks: product.contactClicks + 1,
  );

  _replaceProductInList(store_data.products, updatedProduct);
  _replaceProductInList(home_data.products, updatedProduct);

  for (final entry
      in collection_data
          .collectionProductsForStore(updatedProduct.storeId)
          .entries) {
    entry.value.replaceWhere(
      (item) => _isSameProduct(item, updatedProduct),
      updatedProduct,
    );
  }

  if (updatedProduct.storeId.isNotEmpty) {
    final customization = store_data.customizationForStore(
      updatedProduct.storeId,
    );
    final featuredProducts = customization.featuredProducts.map((item) {
      return _isSameProduct(item, updatedProduct) ? updatedProduct : item;
    }).toList();

    store_data.updateStoreCustomizationForStore(
      updatedProduct.storeId,
      customization.copyWith(featuredProducts: featuredProducts),
    );
  }

  return updatedProduct;
}

void deleteManagedProduct(ProductModel product) {
  store_data.products.removeWhere((item) => item.id == product.id);

  for (final entry
      in collection_data.collectionProductsForStore(product.storeId).entries) {
    entry.value.removeWhere((item) => item.id == product.id);
  }

  if (product.storeId.isNotEmpty) {
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
