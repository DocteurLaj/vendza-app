import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/shared/models/product_model.dart';

class ProductApiService {
  ProductApiService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<Map<String, dynamic>> addProduct({
    required int storeId,
    required String title,
    String? description,
    required double price,
    required int stock,
    bool isActive = true,
    List<String>? images,
    Map<String, dynamic>? variation,
  }) async {
    final response = await _client.post(
      ApiEndpoints.productAdd(storeId),
      authenticated: true,
      body: {
        'title': title,
        'description': description,
        'price': price,
        'stock': stock,
        'is_active': isActive,
        'images': images,
        'variation': variation,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> productsForStore(
    int storeId, {
    bool includeInactive = false,
  }) async {
    final response = await _client.get(
      ApiEndpoints.productAllForStore(storeId),
      queryParameters: {'include_inactive': includeInactive ? 'true' : 'false'},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> productDetail(int productId) async {
    final response = await _client.get(ApiEndpoints.productDetail(productId));
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updateProduct({
    required int storeId,
    required int productId,
    String? title,
    String? description,
    double? price,
    int? stock,
    bool? isActive,
    List<String>? images,
    Map<String, dynamic>? variation,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price;
    if (stock != null) body['stock'] = stock;
    if (isActive != null) body['is_active'] = isActive;
    if (images != null) body['images'] = images;
    if (variation != null) body['variation'] = variation;

    final response = await _client.put(
      ApiEndpoints.productUpdate(storeId, productId),
      authenticated: true,
      body: body,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> deleteProduct({
    required int storeId,
    required int productId,
  }) async {
    final response = await _client.delete(
      ApiEndpoints.productDelete(storeId, productId),
      authenticated: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> searchProducts({
    String? query,
    int? storeId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParameters = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      'active_only': 'true',
    };
    if (query != null && query.trim().isNotEmpty) {
      queryParameters['q'] = query.trim();
    }
    if (storeId != null) {
      queryParameters['store_id'] = '$storeId';
    }

    final response = await _client.get(
      ApiEndpoints.productSearch,
      queryParameters: queryParameters,
    );
    return unwrapApiList(response);
  }

  List<ProductModel> parseProductsForStore(
    Map<String, dynamic> response, {
    String storeName = '',
  }) {
    final rawProducts = response['products'];
    if (rawProducts is! List) return const [];

    return rawProducts
        .map(
          (item) => productFromApi(
            Map<String, dynamic>.from(item as Map),
            storeName: storeName,
          ),
        )
        .toList();
  }
}
