import 'package:vendza/core/sync/entity_sync_status.dart';

class ProductVariantModel {
  final String name;
  final String price;
  final String quantity;
  final String imageurl;

  const ProductVariantModel({
    required this.name,
    required this.price,
    required this.quantity,
    this.imageurl = "",
  });
}

class ProductModel {
  final String id;
  final String name;
  final String price;
  final String imageurl;
  final List<String> images;
  final String status;
  final String description;
  final String category;
  final String storeId;
  final String storeName;
  final int contactClicks;
  final bool isActive;
  final bool adminDisabled;
  final String moderationReason;
  final DateTime? moderatedAt;
  final int stock;
  final bool storeDeliveryEnabled;
  final List<ProductVariantModel> variants;
  final String localId;
  final EntitySyncStatus syncStatus;
  final double syncProgress;
  final String? syncError;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageurl,
    this.images = const [],
    required this.status,
    this.description = "",
    this.category = "",
    this.storeId = "",
    this.storeName = "",
    this.contactClicks = 0,
    this.isActive = true,
    this.adminDisabled = false,
    this.moderationReason = "",
    this.moderatedAt,
    this.stock = 0,
    this.storeDeliveryEnabled = false,
    this.variants = const [],
    this.localId = "",
    this.syncStatus = EntitySyncStatus.online,
    this.syncProgress = 1,
    this.syncError,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = <String>[];
    if (rawImages is String && rawImages.trim().isNotEmpty) {
      images.add(rawImages.trim());
    }
    if (rawImages is List) {
      images.addAll(
        rawImages
            .whereType<String>()
            .map((image) => image.trim())
            .where((image) => image.isNotEmpty),
      );
    }
    final imageUrl = images.isEmpty ? '' : images.first;
    final rawVariants = json['variation'];
    final variants = <ProductVariantModel>[];
    if (rawVariants is Map && rawVariants['items'] is List) {
      for (final item in rawVariants['items'] as List) {
        if (item is! Map) continue;
        variants.add(
          ProductVariantModel(
            name: '${item['name'] ?? ''}',
            price: '${item['price'] ?? ''}',
            quantity: '${item['quantity'] ?? ''}',
            imageurl: '${item['imageurl'] ?? ''}',
          ),
        );
      }
    }
    final stock = (json['stock'] as num?)?.toInt() ?? 0;
    return ProductModel(
      id: '${json['idproduct'] ?? ''}',
      name: '${json['title'] ?? ''}',
      price: '${json['price'] ?? 0} ${json['currency'] ?? 'CDF'}',
      imageurl: imageUrl,
      images: images,
      status: stock > 0 ? 'En stock' : 'Rupture de stock',
      description: '${json['description'] ?? ''}',
      category: '${json['category'] ?? ''}',
      storeId: '${json['store_idstore'] ?? ''}',
      storeName: '${json['store_name'] ?? ''}',
      isActive: json['is_active'] as bool? ?? true,
      adminDisabled: json['admin_disabled'] as bool? ?? false,
      moderationReason: '${json['moderation_reason'] ?? ''}',
      moderatedAt: DateTime.tryParse('${json['moderated_at'] ?? ''}'),
      stock: stock,
      storeDeliveryEnabled: json['store_delivery_enabled'] as bool? ?? false,
      variants: variants,
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? price,
    String? imageurl,
    List<String>? images,
    String? status,
    String? description,
    String? category,
    String? storeId,
    String? storeName,
    int? contactClicks,
    bool? isActive,
    bool? adminDisabled,
    String? moderationReason,
    DateTime? moderatedAt,
    int? stock,
    bool? storeDeliveryEnabled,
    List<ProductVariantModel>? variants,
    String? localId,
    EntitySyncStatus? syncStatus,
    double? syncProgress,
    String? syncError,
  }) {
    final nextImageUrl =
        imageurl ??
        (images == null ? this.imageurl : (images.isEmpty ? '' : images.first));
    final nextImages =
        images ??
        (imageurl == null
            ? this.images
            : [if (nextImageUrl.trim().isNotEmpty) nextImageUrl]);

    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageurl: nextImageUrl,
      images: nextImages,
      status: status ?? this.status,
      description: description ?? this.description,
      category: category ?? this.category,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      contactClicks: contactClicks ?? this.contactClicks,
      isActive: isActive ?? this.isActive,
      adminDisabled: adminDisabled ?? this.adminDisabled,
      moderationReason: moderationReason ?? this.moderationReason,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      stock: stock ?? this.stock,
      storeDeliveryEnabled: storeDeliveryEnabled ?? this.storeDeliveryEnabled,
      variants: variants ?? this.variants,
      localId: localId ?? this.localId,
      syncStatus: syncStatus ?? this.syncStatus,
      syncProgress: syncProgress ?? this.syncProgress,
      syncError: syncError ?? this.syncError,
    );
  }
}
