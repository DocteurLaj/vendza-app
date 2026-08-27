import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/shared/models/product_model.dart';

class FavoriteApiService {
  FavoriteApiService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<void> addFavorite(int productId) async {
    await _client.post(
      ApiEndpoints.favoriteAdd(productId),
      authenticated: true,
    );
  }

  Future<void> removeFavorite(int productId) async {
    await _client.delete(
      ApiEndpoints.favoriteRemove(productId),
      authenticated: true,
    );
  }

  Future<List<ProductModel>> listFavorites({
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _client.get(
      ApiEndpoints.favorites,
      authenticated: true,
      queryParameters: {'page': '$page', 'page_size': '$pageSize'},
    );
    return unwrapApiList(response).map((item) => productFromApi(item)).toList();
  }

  Future<void> addStoreFavorite(int storeId) async {
    await _client.post(
      ApiEndpoints.favoriteStore(storeId),
      authenticated: true,
    );
  }

  Future<void> removeStoreFavorite(int storeId) async {
    await _client.delete(
      ApiEndpoints.favoriteStore(storeId),
      authenticated: true,
    );
  }

  Future<List<ListStoreModel>> listStoreFavorites({
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _client.get(
      ApiEndpoints.favoriteStores,
      authenticated: true,
      queryParameters: {'page': '$page', 'page_size': '$pageSize'},
    );
    return unwrapApiList(response).map(listStoreFromApi).toList();
  }
}

final favoriteApiService = FavoriteApiService();
