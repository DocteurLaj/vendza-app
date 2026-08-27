import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_mappers.dart';

class StoreApiService {
  StoreApiService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<Map<String, dynamic>> createStore({
    required String name,
    String? description,
    String? address,
    String? image,
    String? bannerUrl,
    String? whatsappUrl,
    String? instagramUrl,
    String? facebookUrl,
  }) async {
    final response = await _client.post(
      ApiEndpoints.storeAdd,
      authenticated: true,
      body: {
        'name': name,
        'description': description,
        'address': address,
        'image': image,
        'bannerUrl': bannerUrl,
        'whatsappUrl': whatsappUrl,
        'instagramUrl': instagramUrl,
        'facebookUrl': facebookUrl,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> myStores() async {
    final response = await _client.get(
      ApiEndpoints.storeMy,
      authenticated: true,
    );
    return List<Map<String, dynamic>>.from(
      (response as List).map((item) => Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<Map<String, dynamic>> updateStore({
    required int storeId,
    String? name,
    String? description,
    String? address,
    String? image,
    String? bannerUrl,
    String? whatsappUrl,
    String? instagramUrl,
    String? facebookUrl,
  }) async {
    final response = await _client.put(
      ApiEndpoints.storeUpdate(storeId),
      authenticated: true,
      body: {
        'name': name,
        'description': description,
        'address': address,
        'image': image,
        'bannerUrl': bannerUrl,
        'whatsappUrl': whatsappUrl,
        'instagramUrl': instagramUrl,
        'facebookUrl': facebookUrl,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updateStoreName({
    required int storeId,
    required String name,
  }) async {
    final response = await _client.put(
      ApiEndpoints.storeName(storeId),
      authenticated: true,
      body: {'new_name': name},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updateStoreAddress({
    required int storeId,
    required String address,
  }) async {
    final response = await _client.put(
      ApiEndpoints.storeAddress(storeId),
      authenticated: true,
      body: {'new_address': address},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> deleteStore(int storeId) async {
    final response = await _client.delete(
      ApiEndpoints.storeDelete(storeId),
      authenticated: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> browseStores({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _client.get(
      ApiEndpoints.storeBrowse,
      queryParameters: {'page': '$page', 'page_size': '$pageSize'},
    );
    return unwrapApiList(response);
  }
}
