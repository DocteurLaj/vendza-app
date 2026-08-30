import 'package:flutter/material.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/features/store/data/models/store_customization_model.dart';
import 'package:vendza/features/store/data/models/store_model.dart';

const StoreCustomizationModel _emptyCustomization = StoreCustomizationModel(
  name: '',
  description: '',
  coverImageUrl: '',
  profileImageUrl: '',
);

final Map<String, StoreCustomizationModel> _customizationsByStore = {};
String? _activeCustomizationStoreId;

ValueNotifier<StoreCustomizationModel> storeCustomization =
    ValueNotifier<StoreCustomizationModel>(_emptyCustomization);

String? get activeCustomizationStoreId => _activeCustomizationStoreId;

bool isCustomizationForStore(String storeId) {
  return storeId.isNotEmpty && _activeCustomizationStoreId == storeId;
}

ListStoreModel? storeRecordById(String storeId) {
  final id = storeId.trim();
  if (id.isEmpty) return null;
  for (final store in ownedStores) {
    if (store.id == id) return store;
  }
  for (final store in stores) {
    if (store.id == id) return store;
  }
  return null;
}

StoreCustomizationModel customizationFromStore(ListStoreModel store) {
  return StoreCustomizationModel(
    name: store.name,
    description: store.description,
    coverImageUrl: store.imageUrl,
    profileImageUrl: store.imageUrl,
    whatsappUrl: store.whatsappUrl,
    instagramUrl: store.instagramUrl,
    facebookUrl: store.facebookUrl,
    featuredProducts: products
        .where((product) => product.storeId == store.id)
        .take(2)
        .toList(),
  );
}

StoreCustomizationModel customizationForStore(String storeId) {
  final cached = _customizationsByStore[storeId];
  if (cached != null) return cached;
  final store = storeRecordById(storeId);
  if (store == null) return _emptyCustomization;
  return customizationFromStore(store);
}

void activateStoreCustomization(String storeId) {
  _activeCustomizationStoreId = storeId;
  storeCustomization.value = customizationForStore(storeId);
}

void syncStoreCustomizationFromCatalog() {
  if (ownedStores.isEmpty) {
    _customizationsByStore.clear();
    _activeCustomizationStoreId = null;
    storeCustomization.value = _emptyCustomization;
    return;
  }

  for (final store in ownedStores) {
    _customizationsByStore[store.id] = customizationFromStore(store);
  }

  final activeId = _activeCustomizationStoreId;
  final stillOwned =
      activeId != null && ownedStores.any((store) => store.id == activeId);
  activateStoreCustomization(stillOwned ? activeId : ownedStores.first.id);
}

void updateStoreCustomization(StoreCustomizationModel customization) {
  final storeId = _activeCustomizationStoreId;
  if (storeId == null) {
    storeCustomization.value = customization;
    return;
  }
  updateStoreCustomizationForStore(storeId, customization);
}

void updateStoreCustomizationForStore(
  String storeId,
  StoreCustomizationModel customization,
) {
  if (storeId.isEmpty) return;

  _customizationsByStore[storeId] = customization;
  if (_activeCustomizationStoreId == storeId ||
      _activeCustomizationStoreId == null) {
    _activeCustomizationStoreId = storeId;
    storeCustomization.value = customization;
  }

  if (!isOwnedStoreId(storeId)) return;

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
