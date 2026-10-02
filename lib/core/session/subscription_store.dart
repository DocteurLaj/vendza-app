import 'package:flutter/foundation.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';
import 'package:vendza/features/subscription/data/services/subscription_api_service.dart';

final activeSubscriptionStore = ValueNotifier<SubscriptionContextModel?>(null);
final subscriptionPlansStore = ValueNotifier<List<SubscriptionModel>>(
  <SubscriptionModel>[],
);

void setActiveSubscription(SubscriptionContextModel? subscription) {
  activeSubscriptionStore.value = subscription;
}

void setSubscriptionPlans(List<SubscriptionModel> plans) {
  subscriptionPlansStore.value = List<SubscriptionModel>.unmodifiable(plans);
}

SubscriptionModel? get activeSubscription =>
    activeSubscriptionStore.value?.plan;
bool get hasActiveSubscription => activeSubscriptionStore.value != null;

Future<List<SubscriptionModel>> refreshSubscriptionPlans({
  SubscriptionApiService? service,
}) async {
  final plans = await (service ?? subscriptionApiService).listPlans();
  setSubscriptionPlans(plans);
  return plans;
}

Future<SubscriptionContextModel> refreshActiveSubscription({
  SubscriptionApiService? service,
}) async {
  final context = await (service ?? subscriptionApiService)
      .currentSubscription();
  setActiveSubscription(context);
  return context;
}

void clearSubscriptionSession() {
  activeSubscriptionStore.value = null;
}
