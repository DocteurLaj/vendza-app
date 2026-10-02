class SubscriptionFeaturesModel {
  const SubscriptionFeaturesModel({required this.values});

  final Map<String, dynamic> values;

  factory SubscriptionFeaturesModel.fromJson(Map<String, dynamic>? json) {
    return SubscriptionFeaturesModel(
      values: Map<String, dynamic>.from(json ?? {}),
    );
  }

  int intValue(String key, [int fallback = 0]) {
    final value = values[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool boolValue(String key, [bool fallback = false]) {
    final value = values[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  String stringValue(String key, [String fallback = '']) {
    final value = values[key];
    if (value == null) return fallback;
    return value.toString();
  }

  List<String> toFeatureLines() {
    final lines = <String>[
      '${intValue('max_stores', 1)} boutique${intValue('max_stores', 1) > 1 ? 's' : ''}',
      '${intValue('max_active_products')} produits actifs',
      '${intValue('max_images_per_product')} image${intValue('max_images_per_product') > 1 ? 's' : ''} par produit',
    ];

    final collections = intValue('max_store_collections');
    if (collections > 0) lines.add('$collections collections boutique');

    final featuredProducts = intValue('max_featured_products');
    if (featuredProducts > 0) {
      lines.add('$featuredProducts produits mis en avant');
    }

    lines.add(
      '${intValue('max_social_links')} lien${intValue('max_social_links') > 1 ? 's' : ''} social(aux)',
    );

    if (boolValue('has_banner')) {
      lines.add('Bannière de boutique');
    }
    if (boolValue('has_variants')) {
      lines.add('Variantes produit');
    }
    if (boolValue('has_basic_stats')) {
      lines.add('Statistiques simples');
    }
    if (boolValue('has_advanced_stats')) {
      lines.add('Statistiques avancées');
    }
    if (boolValue('has_featured_store')) {
      lines.add('Boutique mise en avant');
    }
    if (boolValue('has_priority_support')) {
      lines.add('Support prioritaire');
    }
    if (boolValue('has_setup_assistance')) {
      lines.add('Assistance configuration');
    }

    final boost = stringValue('visibility_boost', 'none');
    if (boost == 'light') {
      lines.add('Boost visibilité léger');
    }
    if (boost == 'strong') {
      lines.add('Boost visibilité renforcé');
    }

    return lines;
  }
}

class SubscriptionModel {
  final String id;
  final String code;
  final String title;
  final double price;
  final String currency;
  final String duration;
  final String subtitle;
  final List<String> features;
  final SubscriptionFeaturesModel entitlements;
  final bool isActive;

  SubscriptionModel({
    required this.id,
    required this.title,
    required this.price,
    required this.duration,
    required this.subtitle,
    required this.features,
    this.code = '',
    this.currency = 'FCFA',
    this.entitlements = const SubscriptionFeaturesModel(values: {}),
    this.isActive = true,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price_monthly'] ?? json['price'] ?? 0;
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice.toString()) ?? 0;
    final entitlements = SubscriptionFeaturesModel.fromJson(
      (json['entitlements'] ?? json['features']) is Map
          ? Map<String, dynamic>.from(
              (json['entitlements'] ?? json['features']) as Map,
            )
          : null,
    );
    final description = (json['description'] as String?)?.trim() ?? '';
    return SubscriptionModel(
      id: (json['id'] ?? json['slug'] ?? json['code'] ?? '').toString(),
      code: (json['code'] ?? json['slug'] ?? '').toString(),
      title: (json['name'] ?? json['title'] ?? '').toString(),
      price: price,
      currency: (json['currency'] ?? 'FCFA').toString(),
      duration: _durationLabel(json['duration_days']),
      subtitle: description.isEmpty ? 'Offre Vendza' : description,
      features: entitlements.toFeatureLines(),
      entitlements: entitlements,
      isActive: json['is_active'] != false,
    );
  }

  bool get isFree => price <= 0;

  String get formattedPrice {
    final intPrice = price.roundToDouble() == price
        ? price.toInt().toString()
        : price.toStringAsFixed(2);
    return '$intPrice $currency';
  }

  static String _durationLabel(dynamic days) {
    final value = days is int
        ? days
        : int.tryParse(days?.toString() ?? '') ?? 30;
    if (value >= 360) return 'an';
    if (value >= 28 && value <= 31) return 'mois';
    return '$value jours';
  }
}

class SubscriptionUsageModel {
  const SubscriptionUsageModel({required this.values});

  final Map<String, int> values;

  factory SubscriptionUsageModel.fromJson(Map<String, dynamic>? json) {
    return SubscriptionUsageModel(
      values: (json ?? {}).map((key, value) {
        final number = value is int
            ? value
            : int.tryParse(value.toString()) ?? 0;
        return MapEntry(key, number);
      }),
    );
  }

  int value(String key) => values[key] ?? 0;
}

class SubscriptionContextModel {
  const SubscriptionContextModel({
    required this.plan,
    required this.features,
    required this.usage,
    this.status,
  });

  final SubscriptionModel plan;
  final SubscriptionFeaturesModel features;
  final SubscriptionUsageModel usage;
  final String? status;

  factory SubscriptionContextModel.fromJson(Map<String, dynamic> json) {
    final plan = SubscriptionModel.fromJson(
      Map<String, dynamic>.from(json['plan'] as Map),
    );
    return SubscriptionContextModel(
      plan: plan,
      features: SubscriptionFeaturesModel.fromJson(
        json['features'] is Map
            ? Map<String, dynamic>.from(json['features'] as Map)
            : plan.entitlements.values,
      ),
      usage: SubscriptionUsageModel.fromJson(
        json['usage'] is Map
            ? Map<String, dynamic>.from(json['usage'] as Map)
            : null,
      ),
      status: json['subscription'] is Map
          ? (json['subscription']['status'] as String?)
          : null,
    );
  }
}

class SubscriptionCheckoutModel {
  const SubscriptionCheckoutModel({
    required this.paymentId,
    required this.provider,
    required this.checkoutUrl,
    required this.providerReference,
    required this.status,
    required this.amount,
    required this.currency,
  });

  final int paymentId;
  final String provider;
  final String checkoutUrl;
  final String providerReference;
  final String status;
  final double amount;
  final String currency;

  factory SubscriptionCheckoutModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'] ?? 0;
    return SubscriptionCheckoutModel(
      paymentId:
          json['payment_id'] as int? ??
          int.tryParse('${json['payment_id']}') ??
          0,
      provider: (json['provider'] ?? '').toString(),
      checkoutUrl: (json['checkout_url'] ?? '').toString(),
      providerReference: (json['provider_reference'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      amount: rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount.toString()) ?? 0,
      currency: (json['currency'] ?? 'CDF').toString(),
    );
  }
}

class SubscriptionPaymentStatusModel {
  const SubscriptionPaymentStatusModel({
    required this.paymentId,
    required this.status,
    required this.provider,
    required this.providerReference,
    required this.subscriptionActive,
    this.transactionStatus,
    this.plan,
  });

  final int paymentId;
  final String status;
  final String provider;
  final String providerReference;
  final bool subscriptionActive;
  final String? transactionStatus;
  final SubscriptionModel? plan;

  factory SubscriptionPaymentStatusModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaymentStatusModel(
      paymentId:
          json['payment_id'] as int? ??
          int.tryParse('${json['payment_id']}') ??
          0,
      status: (json['status'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      providerReference: (json['provider_reference'] ?? '').toString(),
      subscriptionActive: json['subscription_active'] == true,
      transactionStatus: json['transaction_status']?.toString(),
      plan: json['plan'] is Map
          ? SubscriptionModel.fromJson(
              Map<String, dynamic>.from(json['plan'] as Map),
            )
          : null,
    );
  }
}
