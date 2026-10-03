import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';

class SubscriptionApiService {
  SubscriptionApiService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<List<SubscriptionModel>> listPlans() async {
    final response = await _client.get(ApiEndpoints.subscriptionPlans);
    return unwrapApiList(
      response,
    ).map(SubscriptionModel.fromJson).where((plan) => plan.isActive).toList();
  }

  Future<SubscriptionContextModel> currentSubscription() async {
    final response = await _client.get(
      ApiEndpoints.subscriptionMe,
      authenticated: true,
    );
    final data = response is Map<String, dynamic> && response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : Map<String, dynamic>.from(response as Map);
    return SubscriptionContextModel.fromJson(data);
  }

  Future<SubscriptionCheckoutModel> createCheckout(
    String planCode, {
    String platform = 'web',
  }) async {
    final response = await _client.post(
      ApiEndpoints.subscriptionCheckout,
      authenticated: true,
      body: {'plan_code': planCode, 'platform': platform},
    );
    final data = response is Map<String, dynamic> && response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : Map<String, dynamic>.from(response as Map);
    return SubscriptionCheckoutModel.fromJson(data);
  }

  Future<SubscriptionPaymentStatusModel> paymentStatus(int paymentId) async {
    final response = await _client.get(
      ApiEndpoints.subscriptionPaymentStatus(paymentId),
      authenticated: true,
    );
    final data = response is Map<String, dynamic> && response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : Map<String, dynamic>.from(response as Map);
    return SubscriptionPaymentStatusModel.fromJson(data);
  }
}

final subscriptionApiService = SubscriptionApiService();
