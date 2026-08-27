import 'package:flutter/material.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/features/store/data/models/store_customization_model.dart';
import 'package:vendza/features/store/data/models/store_model.dart';

ValueNotifier<StoreCustomizationModel> storeCustomization =
    ValueNotifier<StoreCustomizationModel>(
      const StoreCustomizationModel(
        name: '',
        description: '',
        coverImageUrl: '',
        profileImageUrl: '',
      ),
    );

void syncStoreCustomizationFromCatalog() {
  if (ownedStores.isEmpty) {
    storeCustomization.value = const StoreCustomizationModel(
      name: '',
      description: '',
      coverImageUrl: '',
      profileImageUrl: '',
    );
    return;
  }
  final primary = ownedStores.first;
  storeCustomization.value = StoreCustomizationModel(
    name: primary.name,
    description: primary.description,
    coverImageUrl: primary.imageUrl,
    profileImageUrl: primary.imageUrl,
    whatsappUrl: primary.whatsappUrl,
    instagramUrl: primary.instagramUrl,
    facebookUrl: primary.facebookUrl,
    featuredProducts: products
        .where((product) => product.storeId == primary.id)
        .take(2)
        .toList(),
  );
}

void updateStoreCustomization(StoreCustomizationModel customization) {
  storeCustomization.value = customization;

  if (ownedStores.isEmpty) return;
  final storeId = ownedStores.first.id;
  final previousStoreName = ownedStores.first.name;
  final updated = ListStoreModel(
    id: storeId,
    name: customization.name,
    description: customization.description,
    imageUrl: customization.profileImageUrl.isEmpty
        ? customization.coverImageUrl
        : customization.profileImageUrl,
    rating: ownedStores.first.rating,
    city: ownedStores.first.city,
    whatsappUrl: customization.whatsappUrl,
    instagramUrl: customization.instagramUrl,
    facebookUrl: customization.facebookUrl,
  );
  ownedStores[0] = updated;

  final publicIndex = stores.indexWhere((store) => store.id == storeId);
  if (publicIndex >= 0) {
    stores[publicIndex] = updated;
  }
  _syncProductStoreName(storeId, previousStoreName, customization.name);
  favoriteStoreChanges.value++;
  catalogRevision.value++;
}

void updateStoreCustomizationForStore(
  String storeId,
  StoreCustomizationModel customization,
) {
  if (ownedStores.isEmpty) return;
  if (!isOwnedStoreId(storeId)) return;

  if (storeId == ownedStores.first.id) {
    updateStoreCustomization(customization);
    return;
  }

  for (int index = 0; index < ownedStores.length; index++) {
    if (ownedStores[index].id != storeId) continue;

    final previousStore = ownedStores[index];
    final updated = ListStoreModel(
      id: previousStore.id,
      name: customization.name,
      description: customization.description,
      imageUrl: customization.profileImageUrl.isEmpty
          ? customization.coverImageUrl
          : customization.profileImageUrl,
      rating: previousStore.rating,
      city: previousStore.city,
      whatsappUrl: customization.whatsappUrl,
      instagramUrl: customization.instagramUrl,
      facebookUrl: customization.facebookUrl,
    );
    ownedStores[index] = updated;

    final publicIndex = stores.indexWhere((store) => store.id == storeId);
    if (publicIndex >= 0) {
      stores[publicIndex] = updated;
    }
    _syncProductStoreName(storeId, previousStore.name, customization.name);
    favoriteStoreChanges.value++;
    catalogRevision.value++;
    return;
  }
}

void _syncProductStoreName(
  String storeId,
  String previousStoreName,
  String nextStoreName,
) {
  for (int index = 0; index < products.length; index++) {
    final product = products[index];
    final belongsToStore =
        product.storeId == storeId ||
        (product.storeId.isEmpty && product.storeName == previousStoreName);
    if (!belongsToStore) continue;

    products[index] = product.copyWith(
      storeId: storeId,
      storeName: nextStoreName,
    );
  }
}
