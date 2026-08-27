import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/shared/models/product_model.dart';

class HomeFeedModel {
  const HomeFeedModel({
    this.featuredStores = const [],
    this.trendingProducts = const [],
    this.popularProducts = const [],
    this.newestProducts = const [],
    this.discoverProducts = const [],
  });

  final List<StoreModel> featuredStores;
  final List<ProductModel> trendingProducts;
  final List<ProductModel> popularProducts;
  final List<ProductModel> newestProducts;
  final List<ProductModel> discoverProducts;

  static const empty = HomeFeedModel();

  bool get isEmpty =>
      featuredStores.isEmpty &&
      trendingProducts.isEmpty &&
      popularProducts.isEmpty &&
      newestProducts.isEmpty &&
      discoverProducts.isEmpty;

  factory HomeFeedModel.fromResponse(
    dynamic response, {
    Map<String, String> storeNames = const {},
  }) {
    final data = _unwrapData(response);
    return HomeFeedModel(
      featuredStores: _mapStores(data['featured_stores']),
      trendingProducts: _mapProducts(data['trending_products'], storeNames),
      popularProducts: _mapProducts(data['popular_products'], storeNames),
      newestProducts: _mapProducts(data['newest_products'], storeNames),
      discoverProducts: _mapProducts(data['discover_products'], storeNames),
    );
  }

  static Map<String, dynamic> _unwrapData(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return response;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return const {};
  }

  static List<StoreModel> _mapStores(dynamic raw) {
    return _mapMaps(raw).map(homeStoreFromApi).toList();
  }

  static List<ProductModel> _mapProducts(
    dynamic raw,
    Map<String, String> storeNames,
  ) {
    return _mapMaps(raw).map((item) {
      final storeId = item['store_idstore']?.toString() ?? '';
      return productFromApi(item, storeName: storeNames[storeId] ?? '');
    }).toList();
  }

  static List<Map<String, dynamic>> _mapMaps(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

class HomeSectionsView {
  const HomeSectionsView(this.feed);

  final HomeFeedModel feed;

  List<StoreModel> get stores => feed.featuredStores;
  List<ProductModel> get tendances => feed.trendingProducts;
  List<ProductModel> get newest => feed.newestProducts;
  List<ProductModel> get popular => feed.popularProducts;
  List<ProductModel> get discover => feed.discoverProducts;
  List<StoreModel> get discoverStores => const [];
}
