import 'package:flutter/foundation.dart';

final likedProductIdsStore = ValueNotifier<Set<String>>(<String>{});

void toggleLikedProduct(String productId) {
  final updated = Set<String>.from(likedProductIdsStore.value);
  if (updated.contains(productId)) {
    updated.remove(productId);
  } else {
    updated.add(productId);
  }
  likedProductIdsStore.value = updated;
}

bool isProductLiked(String productId) {
  return likedProductIdsStore.value.contains(productId);
}
