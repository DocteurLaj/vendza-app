import 'package:vendza/shared/models/product_model.dart';

class StoreCustomizationModel {
  final String name;
  final String description;
  final String coverImageUrl;
  final String profileImageUrl;
  final String whatsappUrl;
  final String instagramUrl;
  final String facebookUrl;
  final List<ProductModel> featuredProducts;

  const StoreCustomizationModel({
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.profileImageUrl,
    this.whatsappUrl = "",
    this.instagramUrl = "",
    this.facebookUrl = "",
    this.featuredProducts = const [],
  });

  StoreCustomizationModel copyWith({
    String? name,
    String? description,
    String? coverImageUrl,
    String? profileImageUrl,
    String? whatsappUrl,
    String? instagramUrl,
    String? facebookUrl,
    List<ProductModel>? featuredProducts,
  }) {
    return StoreCustomizationModel(
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      whatsappUrl: whatsappUrl ?? this.whatsappUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      featuredProducts: featuredProducts ?? this.featuredProducts,
    );
  }
}
