import 'dart:convert';

import 'package:vendza/core/sync/entity_sync_status.dart';
import 'package:vendza/features/home/data/models/home_feed_model.dart';
import 'package:vendza/features/home/data/models/store_model.dart' as home;
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/shared/models/section_model.dart';
import 'package:vendza/shared/models/product_model.dart';

class CatalogCacheSnapshot {
  const CatalogCacheSnapshot({
    required this.stores,
    required this.homeStores,
    required this.products,
    required this.homeProducts,
    required this.homeFeed,
    required this.categories,
  });

  final List<ListStoreModel> stores;
  final List<home.StoreModel> homeStores;
  final List<ProductModel> products;
  final List<ProductModel> homeProducts;
  final HomeFeedModel homeFeed;
  final List<SectionModel> categories;

  bool get isEmpty =>
      stores.isEmpty &&
      homeStores.isEmpty &&
      products.isEmpty &&
      homeProducts.isEmpty &&
      homeFeed.isEmpty &&
      categories.isEmpty;
}

String encodeCatalogCache(CatalogCacheSnapshot snapshot) {
  return jsonEncode({
    'version': 1,
    'savedAt': DateTime.now().toIso8601String(),
    'stores': snapshot.stores.map(_storeToJson).toList(),
    'homeStores': snapshot.homeStores.map(_homeStoreToJson).toList(),
    'products': snapshot.products.map(_productToJson).toList(),
    'homeProducts': snapshot.homeProducts.map(_productToJson).toList(),
    'homeFeed': _homeFeedToJson(snapshot.homeFeed),
    'categories': snapshot.categories.map(_sectionToJson).toList(),
  });
}

CatalogCacheSnapshot? decodeCatalogCache(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is! Map) return null;
    final data = Map<String, dynamic>.from(decoded);
    return CatalogCacheSnapshot(
      stores: _mapList(data['stores'], _storeFromJson),
      homeStores: _mapList(data['homeStores'], _homeStoreFromJson),
      products: _mapList(data['products'], _productFromJson),
      homeProducts: _mapList(data['homeProducts'], _productFromJson),
      homeFeed: _homeFeedFromJson(data['homeFeed']),
      categories: _mapList(data['categories'], _sectionFromJson),
    );
  } on Object {
    return null;
  }
}

List<T> _mapList<T>(dynamic raw, T Function(Map<String, dynamic>) mapper) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList();
}

Map<String, dynamic> _storeToJson(ListStoreModel store) {
  return {
    'id': store.id,
    'localId': store.localId,
    'name': store.name,
    'description': store.description,
    'imageUrl': store.imageUrl,
    'rating': store.rating,
    'city': store.city,
    'whatsappUrl': store.whatsappUrl,
    'instagramUrl': store.instagramUrl,
    'facebookUrl': store.facebookUrl,
    'syncStatus': store.syncStatus.name,
    'syncProgress': store.syncProgress,
    'syncError': store.syncError,
  };
}

ListStoreModel _storeFromJson(Map<String, dynamic> json) {
  return ListStoreModel(
    id: json['id']?.toString() ?? '',
    localId: json['localId']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString() ?? 'assets/images/login_img.jpg',
    rating: _doubleFromJson(json['rating'], fallback: 0),
    city: json['city']?.toString() ?? '',
    whatsappUrl: json['whatsappUrl']?.toString() ?? '',
    instagramUrl: json['instagramUrl']?.toString() ?? '',
    facebookUrl: json['facebookUrl']?.toString() ?? '',
    syncStatus: _syncStatusFromJson(json['syncStatus']),
    syncProgress: _doubleFromJson(json['syncProgress'], fallback: 1),
    syncError: json['syncError']?.toString(),
  );
}

Map<String, dynamic> _homeStoreToJson(home.StoreModel store) {
  return {
    'id': store.id,
    'name': store.name,
    'image': store.image,
    'description': store.description,
  };
}

home.StoreModel _homeStoreFromJson(Map<String, dynamic> json) {
  return home.StoreModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    image: json['image']?.toString() ?? 'assets/images/login_img.jpg',
    description: json['description']?.toString(),
  );
}

Map<String, dynamic> _productToJson(ProductModel product) {
  return {
    'id': product.id,
    'name': product.name,
    'price': product.price,
    'imageurl': product.imageurl,
    'status': product.status,
    'description': product.description,
    'category': product.category,
    'storeId': product.storeId,
    'storeName': product.storeName,
    'contactClicks': product.contactClicks,
    'isActive': product.isActive,
    'variants': product.variants.map(_variantToJson).toList(),
    'localId': product.localId,
    'syncStatus': product.syncStatus.name,
    'syncProgress': product.syncProgress,
    'syncError': product.syncError,
  };
}

ProductModel _productFromJson(Map<String, dynamic> json) {
  return ProductModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    price: json['price']?.toString() ?? '0',
    imageurl: json['imageurl']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    storeId: json['storeId']?.toString() ?? '',
    storeName: json['storeName']?.toString() ?? '',
    contactClicks: _intFromJson(json['contactClicks']),
    isActive: json['isActive'] != false,
    variants: _mapList(json['variants'], _variantFromJson),
    localId: json['localId']?.toString() ?? '',
    syncStatus: _syncStatusFromJson(json['syncStatus']),
    syncProgress: _doubleFromJson(json['syncProgress'], fallback: 1),
    syncError: json['syncError']?.toString(),
  );
}

Map<String, dynamic> _variantToJson(ProductVariantModel variant) {
  return {
    'name': variant.name,
    'price': variant.price,
    'quantity': variant.quantity,
    'imageurl': variant.imageurl,
  };
}

ProductVariantModel _variantFromJson(Map<String, dynamic> json) {
  return ProductVariantModel(
    name: json['name']?.toString() ?? '',
    price: json['price']?.toString() ?? '',
    quantity: json['quantity']?.toString() ?? '',
    imageurl: json['imageurl']?.toString() ?? '',
  );
}

Map<String, dynamic> _homeFeedToJson(HomeFeedModel feed) {
  return {
    'featuredStores': feed.featuredStores.map(_homeStoreToJson).toList(),
    'trendingProducts': feed.trendingProducts.map(_productToJson).toList(),
    'popularProducts': feed.popularProducts.map(_productToJson).toList(),
    'newestProducts': feed.newestProducts.map(_productToJson).toList(),
    'discoverProducts': feed.discoverProducts.map(_productToJson).toList(),
  };
}

HomeFeedModel _homeFeedFromJson(dynamic raw) {
  if (raw is! Map) return HomeFeedModel.empty;
  final json = Map<String, dynamic>.from(raw);
  return HomeFeedModel(
    featuredStores: _mapList(json['featuredStores'], _homeStoreFromJson),
    trendingProducts: _mapList(json['trendingProducts'], _productFromJson),
    popularProducts: _mapList(json['popularProducts'], _productFromJson),
    newestProducts: _mapList(json['newestProducts'], _productFromJson),
    discoverProducts: _mapList(json['discoverProducts'], _productFromJson),
  );
}

Map<String, dynamic> _sectionToJson(SectionModel section) {
  return {
    'id': section.id,
    'name': section.name,
    'imageUrl': section.imageUrl,
  };
}

SectionModel _sectionFromJson(Map<String, dynamic> json) {
  return SectionModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString() ?? 'assets/images/product1.webp',
  );
}

EntitySyncStatus _syncStatusFromJson(dynamic value) {
  final name = value?.toString();
  return EntitySyncStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => EntitySyncStatus.online,
  );
}

int _intFromJson(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _doubleFromJson(dynamic value, {required double fallback}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
