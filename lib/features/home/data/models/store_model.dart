class StoreModel {
  final String id;
  final String name;
  final String image;
  final String? description;
  final bool deliveryEnabled;
  final bool adminHidden;
  final String moderationReason;

  StoreModel({
    this.id = "",
    required this.name,
    required this.image,
    this.description, // La description est optionnelle
    this.deliveryEnabled = false,
    this.adminHidden = false,
    this.moderationReason = "",
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final image = json['image'];
    var imageUrl = '';
    if (image is String) imageUrl = image;
    if (image is List && image.isNotEmpty) imageUrl = '${image.first}';
    if (image is Map) imageUrl = '${image['url'] ?? image['public_url'] ?? ''}';
    return StoreModel(
      id: '${json['idstore'] ?? ''}',
      name: '${json['name'] ?? ''}',
      image: imageUrl,
      description: json['description'] as String?,
      deliveryEnabled: json['deliveryEnabled'] as bool? ?? false,
      adminHidden: json['admin_hidden'] as bool? ?? false,
      moderationReason: '${json['moderation_reason'] ?? ''}',
    );
  }

  String getDescription() {
    return description ?? "Aucune description disponible";
  }
}
