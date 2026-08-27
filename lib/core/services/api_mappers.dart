import 'package:vendza/features/home/data/models/store_model.dart' as home;
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/shared/models/product_model.dart';

String _resolveImageUrl(dynamic image) {
  if (image == null) return '';
  if (image is String) return image.trim();
  return image.toString().trim();
}

String _firstProductImage(dynamic images) {
  if (images is! List || images.isEmpty) return '';
  return _resolveImageUrl(images.first);
}

List<ProductVariantModel> _mapVariants(dynamic variation) {
  if (variation is! Map) return const [];

  final variants = <ProductVariantModel>[];
  variation.forEach((key, value) {
    if (value is! Map) return;
    variants.add(
      ProductVariantModel(
        name: key.toString(),
        price: value['price']?.toString() ?? '',
        quantity:
            value['quantity']?.toString() ?? value['stock']?.toString() ?? '',
        imageurl: _resolveImageUrl(value['image'] ?? value['imageurl']),
      ),
    );
  });
  return variants;
}

ProductModel productFromApi(
  Map<String, dynamic> json, {
  String storeName = '',
}) {
  final stock = json['stock'];
  final stockValue = stock is int ? stock : int.tryParse('$stock') ?? 0;
  final rawActive = json['is_active'];
  final bool isActive;
  if (rawActive is bool) {
    isActive = rawActive;
  } else if (rawActive != null) {
    isActive = rawActive.toString().toLowerCase() == 'true';
  } else {
    // Legacy fallback before is_active existed on the API.
    isActive = stockValue > 0;
  }

  return ProductModel(
    id: (json['idproduct'] ?? json['uuidproduct']).toString(),
    name: json['title'] as String? ?? '',
    price: json['price']?.toString() ?? '0',
    imageurl: _firstProductImage(json['images']),
    status: '',
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? '',
    storeId: json['store_idstore']?.toString() ?? '',
    storeName: storeName,
    isActive: isActive,
    variants: _mapVariants(json['variation']),
  );
}

ListStoreModel listStoreFromApi(Map<String, dynamic> json) {
  final imageUrl = _resolveImageUrl(json['image']);
  return ListStoreModel(
    id: json['idstore'].toString(),
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    imageUrl: imageUrl.isEmpty ? 'assets/images/login_img.jpg' : imageUrl,
    rating: 0,
    city: json['address'] as String? ?? '',
    whatsappUrl: json['whatsappUrl'] as String? ?? '',
    instagramUrl: json['instagramUrl'] as String? ?? '',
    facebookUrl: json['facebookUrl'] as String? ?? '',
  );
}

home.StoreModel homeStoreFromApi(Map<String, dynamic> json) {
  final imageUrl = _resolveImageUrl(json['image']);
  return home.StoreModel(
    id: json['idstore'].toString(),
    name: json['name'] as String? ?? '',
    image: imageUrl.isEmpty ? 'assets/images/login_img.jpg' : imageUrl,
    description: json['description'] as String?,
  );
}

NotificationModel notificationFromApi(Map<String, dynamic> json) {
  return NotificationModel(
    id: json['idnotification'].toString(),
    name: json['type'] as String? ?? 'Notification',
    description: json['content'] as String? ?? '',
    imageUrl: 'assets/images/login_img.jpg',
    isRead: json['seen'] == true,
  );
}

List<Map<String, dynamic>> unwrapApiList(dynamic response) {
  if (response is List) {
    return response
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
  if (response is Map<String, dynamic>) {
    final data = response['data'];
    if (data is List) {
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
  }
  return const [];
}

Map<String, dynamic>? unwrapApiMeta(dynamic response) {
  if (response is! Map<String, dynamic>) return null;
  final meta = response['meta'];
  if (meta is Map<String, dynamic>) return meta;
  return null;
}
