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
    this.syncStatus = EntitySyncStatus.online,
    this.syncProgress = 1,
    this.syncError,
  });

  bool get isLocalOnly => syncStatus.isPending || isLocalEntityId(id);

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
      syncStatus: syncStatus ?? this.syncStatus,
      syncProgress: syncProgress ?? this.syncProgress,
      syncError: syncError ?? this.syncError,
    );
  }
}
