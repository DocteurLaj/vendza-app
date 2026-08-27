class StoreModel {
  final String id;
  final String name;
  final String image;
  final String? description;

  StoreModel({
    this.id = "",
    required this.name,
    required this.image,
    this.description, // La description est optionnelle
  });

  String getDescription() {
    return description ?? "Aucune description disponible";
  }
}
