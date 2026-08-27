class ListStoreModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final String city;
  final String whatsappUrl;
  final String instagramUrl;
  final String facebookUrl;

  ListStoreModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    this.city = "",
    this.whatsappUrl = "",
    this.instagramUrl = "",
    this.facebookUrl = "",
  });
}
