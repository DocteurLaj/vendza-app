import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/home/data/services/data_exemple.dart'
    as home_catalog;
import 'package:vendza/features/store/data/services/data_exemple.dart'
    as store_catalog;
import 'package:vendza/shared/models/product_model.dart';

ProductModel? findProductById(String id) {
  for (final product in store_catalog.products) {
    if (product.id == id) return product;
  }
  return null;
}

StoreModel? findStoreById(String id) {
  for (final store in home_catalog.stores) {
    if (store.id == id) return store;
  }

  for (final store in store_catalog.stores) {
    if (store.id == id) {
      return StoreModel(
        id: store.id,
        name: store.name,
        image: store.imageUrl,
        description: store.description,
      );
    }
  }

  return null;
}
