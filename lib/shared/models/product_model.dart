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
  final String status;
  final String description;
  final String category;
  final String storeId;
  final String storeName;
  final int contactClicks;
  final bool isActive;
  final List<ProductVariantModel> variants;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageurl,
    required this.status,
    this.description = "",
    this.category = "",
    this.storeId = "",
    this.storeName = "",
    this.contactClicks = 0,
    this.isActive = true,
    this.variants = const [],
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? price,
    String? imageurl,
    String? status,
    String? description,
    String? category,
    String? storeId,
    String? storeName,
    int? contactClicks,
    bool? isActive,
    List<ProductVariantModel>? variants,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageurl: imageurl ?? this.imageurl,
      status: status ?? this.status,
      description: description ?? this.description,
      category: category ?? this.category,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      contactClicks: contactClicks ?? this.contactClicks,
      isActive: isActive ?? this.isActive,
      variants: variants ?? this.variants,
    );
  }
}
