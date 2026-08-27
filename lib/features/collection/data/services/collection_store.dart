import 'package:flutter/foundation.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/models/section_model.dart';

final List<SectionModel> collections = [];
final Map<String, List<ProductModel>> collectionProducts = {};
final ValueNotifier<int> collectionRevision = ValueNotifier<int>(0);

class CollectionApiService {
  CollectionApiService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<List<SectionModel>> listCollections(int storeId) async {
    final response = await _client.get(ApiEndpoints.storeCollections(storeId));
    return unwrapApiList(response).map(_mapCollection).toList();
  }

  Future<SectionModel> createCollection({
    required int storeId,
    required String name,
    String? description,
  }) async {
    final response = await _client.post(
      ApiEndpoints.storeCollections(storeId),
      authenticated: true,
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return _mapCollection(Map<String, dynamic>.from(response as Map));
  }

  Future<List<ProductModel>> productsForCollection(int collectionId) async {
    final response = await _client.get(
      ApiEndpoints.storeCollectionProducts(collectionId),
    );
    return unwrapApiList(response).map((item) => productFromApi(item)).toList();
  }

  Future<void> assignProducts({
    required int collectionId,
    required List<int> productIds,
  }) async {
    await _client.put(
      ApiEndpoints.storeCollectionProducts(collectionId),
      authenticated: true,
      body: {'product_ids': productIds},
    );
  }

  Future<void> deleteCollection(int collectionId) async {
    await _client.delete(
      ApiEndpoints.storeCollectionDelete(collectionId),
      authenticated: true,
    );
  }

  SectionModel _mapCollection(Map<String, dynamic> json) {
    final id = json['idstore_collection'] ?? json['idcollections'];
    return SectionModel(
      id: id?.toString() ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: 'assets/images/product1.webp',
    );
  }
}

class CollectionRepository {
  CollectionRepository({CollectionApiService? apiService})
    : _api = apiService ?? CollectionApiService();

  final CollectionApiService _api;

  Future<void> refreshCollections(String storeId) async {
    final parsedStoreId = int.tryParse(storeId);
    if (parsedStoreId == null) {
      throw ArgumentError('Identifiant de boutique invalide.');
    }
    final items = await _api.listCollections(parsedStoreId);
    collections
      ..clear()
      ..addAll(items);
    collectionProducts.clear();
    for (final collection in items) {
      final collectionId = int.tryParse(collection.id);
      if (collectionId == null) continue;
      collectionProducts[collection.id] = await _api.productsForCollection(
        collectionId,
      );
    }
    collectionRevision.value++;
  }

  Future<SectionModel> createCollection({
    required String storeId,
    required String name,
  }) async {
    final parsedStoreId = int.tryParse(storeId);
    if (parsedStoreId == null) {
      throw ArgumentError('Identifiant de boutique invalide.');
    }
    final created = await _api.createCollection(
      storeId: parsedStoreId,
      name: name,
    );
    collections.insert(0, created);
    collectionProducts[created.id] = [];
    collectionRevision.value++;
    return created;
  }

  Future<void> assignProducts({
    required String collectionId,
    required List<ProductModel> products,
  }) async {
    final parsedId = int.tryParse(collectionId);
    if (parsedId == null) {
      throw ArgumentError('Identifiant de collection invalide.');
    }

    final productIds = products
        .map((product) => int.tryParse(product.id))
        .whereType<int>()
        .toList();

    await _api.assignProducts(collectionId: parsedId, productIds: productIds);
    collectionProducts[collectionId] = products;
    collectionRevision.value++;
  }

  Future<void> deleteCollections(Iterable<String> ids) async {
    for (final id in ids) {
      final parsedId = int.tryParse(id);
      if (parsedId == null) continue;
      await _api.deleteCollection(parsedId);
      collections.removeWhere((collection) => collection.id == id);
      collectionProducts.remove(id);
    }
    collectionRevision.value++;
  }
}

final collectionApiService = CollectionApiService();
final collectionRepository = CollectionRepository();
