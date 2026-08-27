import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/features/home/data/models/home_feed_model.dart';

class HomeFeedApiService {
  HomeFeedApiService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<HomeFeedModel> fetchFeed({
    String? city,
    int discoverLimit = 40,
    Map<String, String> storeNames = const {},
  }) async {
    final queryParameters = <String, String>{
      'discover_limit': '$discoverLimit',
    };
    if (city != null && city.trim().isNotEmpty) {
      queryParameters['city'] = city.trim();
    }

    final response = await _client.get(
      ApiEndpoints.homeFeed,
      queryParameters: queryParameters,
    );
    return HomeFeedModel.fromResponse(response, storeNames: storeNames);
  }
}
