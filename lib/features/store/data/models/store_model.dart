import 'package:vendza/core/sync/entity_sync_status.dart';

class ListStoreModel {
  final String id;
  final String localId;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final String city;
  final String whatsappUrl;
  final String instagramUrl;
  final String facebookUrl;
  final bool deliveryEnabled;
  final bool isActive;
  final bool adminHidden;
  final String moderationReason;
  final DateTime? moderatedAt;
  final EntitySyncStatus syncStatus;
  final double syncProgress;
  final String? syncError;

  ListStoreModel({
    required this.id,
    this.localId = '',
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    this.city = "",
    this.whatsappUrl = "",
    this.instagramUrl = "",
    this.facebookUrl = "",
    this.deliveryEnabled = false,
    this.isActive = true,
    this.adminHidden = false,
    this.moderationReason = "",
    this.moderatedAt,
    this.syncStatus = EntitySyncStatus.online,
    this.syncProgress = 1,
    this.syncError,
  });

  bool get isLocalOnly => syncStatus.isPending || isLocalEntityId(id);

  factory ListStoreModel.fromJson(Map<String, dynamic> json) {
    return ListStoreModel(
      id: '${json['idstore'] ?? ''}',
      name: '${json['name'] ?? ''}',
      description: '${json['description'] ?? ''}',
      imageUrl: _storeImageUrl(json['image']),
      rating: 0,
      city: '${json['address'] ?? ''}',
      whatsappUrl: '${json['whatsappUrl'] ?? ''}',
      instagramUrl: '${json['instagramUrl'] ?? ''}',
      facebookUrl: '${json['facebookUrl'] ?? ''}',
      deliveryEnabled: json['deliveryEnabled'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      adminHidden: json['admin_hidden'] as bool? ?? false,
      moderationReason: '${json['moderation_reason'] ?? ''}',
      moderatedAt: DateTime.tryParse('${json['moderated_at'] ?? ''}'),
    );
  }

  ListStoreModel copyWith({
    String? id,
    String? localId,
    String? name,
    String? description,
    String? imageUrl,
    double? rating,
    String? city,
    String? whatsappUrl,
    String? instagramUrl,
    String? facebookUrl,
    bool? deliveryEnabled,
    bool? isActive,
    bool? adminHidden,
    String? moderationReason,
    DateTime? moderatedAt,
    EntitySyncStatus? syncStatus,
    double? syncProgress,
    String? syncError,
  }) {
    return ListStoreModel(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      city: city ?? this.city,
      whatsappUrl: whatsappUrl ?? this.whatsappUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      isActive: isActive ?? this.isActive,
      adminHidden: adminHidden ?? this.adminHidden,
      moderationReason: moderationReason ?? this.moderationReason,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncProgress: syncProgress ?? this.syncProgress,
      syncError: syncError ?? this.syncError,
    );
  }
}

String _storeImageUrl(Object? image) {
  if (image is String) return image;
  if (image is List && image.isNotEmpty) return '${image.first}';
  if (image is Map) return '${image['url'] ?? image['public_url'] ?? ''}';
  return '';
}
