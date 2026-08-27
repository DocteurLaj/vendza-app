import 'package:flutter/foundation.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';

final activeSubscriptionStore = ValueNotifier<SubscriptionModel?>(null);

void setActiveSubscription(SubscriptionModel? subscription) {
  activeSubscriptionStore.value = subscription;
}

bool get hasActiveSubscription => activeSubscriptionStore.value != null;
