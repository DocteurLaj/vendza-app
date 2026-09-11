import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';

class SubscriptionCatalog {
  const SubscriptionCatalog({
    required this.enabled,
    required this.disabledMessage,
    required this.plans,
    this.currentPlan,
  });

  final bool enabled;
  final String disabledMessage;
  final List<SubscriptionModel> plans;
  final SubscriptionModel? currentPlan;
}

class SubscriptionApiService {
  SubscriptionApiService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<SubscriptionCatalog> catalog() async {
    final response = await _client.get(
      ApiEndpoints.subscriptions,
      authenticated: true,
    );
    final envelope = Map<String, dynamic>.from(response as Map);
    final data = Map<String, dynamic>.from(
      envelope['data'] as Map? ?? envelope,
    );
    final plans = (data['plans'] as List? ?? const [])
        .map(
          (item) => SubscriptionModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final current = data['current_plan'];
    return SubscriptionCatalog(
      enabled: data['enabled'] as bool? ?? false,
      disabledMessage:
          '${data['disabled_message'] ?? "Les abonnements sont temporairement indisponibles."}',
      plans: plans,
      currentPlan: current is Map
          ? SubscriptionModel.fromJson(Map<String, dynamic>.from(current))
          : null,
    );
  }
}
