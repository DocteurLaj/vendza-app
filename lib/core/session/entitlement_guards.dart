/// Entitlement helpers — read from the in-memory subscription context.
///
/// These functions are cheap (no network) and are called before expensive
/// UI actions (e.g. tapping "Add variant") to give immediate feedback
/// instead of waiting for a 402 from the server.
///
/// Falls back to the most restrictive (free-tier) defaults when the
/// subscription context is not loaded yet.
library;

import 'package:vendza/core/session/subscription_store.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';

SubscriptionFeaturesModel _features() {
  return activeSubscriptionStore.value?.features ??
      const SubscriptionFeaturesModel(values: {});
}

// ── product ────────────────────────────────────────────────────────────────────

bool canAddVariant() => _features().boolValue('has_variants');

int maxImagesPerProduct() => _features().intValue('max_images_per_product', 1);

int maxProducts() => _features().intValue(
  'max_products',
  _features().intValue('max_active_products', 10),
);

// ── store ──────────────────────────────────────────────────────────────────────

bool canSetBanner() => _features().boolValue('has_banner');

int maxSocialLinks() => _features().intValue('max_social_links', 1);

List<String> allowedSocialNetworks() {
  final raw = _features().values['allowed_social_networks'];
  if (raw is List) {
    final configured = raw
        .map((value) => value.toString().trim().toLowerCase())
        .where((value) => {'whatsapp', 'instagram', 'facebook'}.contains(value))
        .toSet()
        .toList();
    if (configured.isNotEmpty) return configured;
  }
  return maxSocialLinks() <= 1
      ? const ['whatsapp']
      : const ['whatsapp', 'instagram', 'facebook'];
}

int maxStores() => _features().intValue('max_stores', 1);

// ── collections ────────────────────────────────────────────────────────────────

int maxCollections() => _features().intValue(
  'max_collections',
  _features().intValue('max_store_collections', 0),
);

bool canCreateCollection() => maxCollections() > 0;
