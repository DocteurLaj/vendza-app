import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/features/home/data/models/store_model.dart' as detail;
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/store_customization_state.dart';
import 'package:vendza/shared/models/social_item.dart';

export 'package:vendza/core/catalog/catalog_repository.dart'
    show
        catalogError,
        catalogLoading,
        catalogRepository,
        catalogRevision,
        favoriteStoreChanges,
        favoriteStores,
        isOwnedStoreId,
        ownedStores,
        products,
        stores;

export 'package:vendza/features/store/data/services/store_customization_state.dart'
    show
        activateStoreCustomization,
        customizationForStore,
        isCustomizationForStore,
        storeCustomization,
        syncStoreCustomizationFromCatalog,
        updateStoreCustomization,
        updateStoreCustomizationForStore;

bool _matchesFavoriteStore(detail.StoreModel store, ListStoreModel favorite) {
  final storeId = store.id.trim();
  final favoriteId = favorite.id.trim();
  if (storeId.isNotEmpty && favoriteId.isNotEmpty && storeId == favoriteId) {
    return true;
  }
  return favorite.name == store.name;
}

bool isStoreFavorite(detail.StoreModel store) {
  return favoriteStores.any(
    (favorite) => _matchesFavoriteStore(store, favorite),
  );
}

Future<bool> toggleStoreFavorite(detail.StoreModel store) {
  return catalogRepository.toggleStoreFavorite(store.id);
}

List<SocialItem> configuredStoreSocials([String? storeId]) {
  final id = storeId?.trim().isNotEmpty == true
      ? storeId!.trim()
      : activeCustomizationStoreId;
  if (id == null || id.isEmpty) return const [];

  final store = storeRecordById(id);
  final customization = customizationForStore(id);
  final whatsapp = customization.whatsappUrl.trim().isNotEmpty
      ? customization.whatsappUrl
      : (store?.whatsappUrl ?? '');
  final instagram = customization.instagramUrl.trim().isNotEmpty
      ? customization.instagramUrl
      : (store?.instagramUrl ?? '');
  final facebook = customization.facebookUrl.trim().isNotEmpty
      ? customization.facebookUrl
      : (store?.facebookUrl ?? '');

  final configuredSocials = <SocialItem>[];

  if (whatsapp.trim().isNotEmpty) {
    configuredSocials.add(
      SocialItem(
        icon: FontAwesomeIcons.whatsapp,
        color: Colors.green,
        url: _normalizeWhatsappLink(whatsapp),
      ),
    );
  }

  if (instagram.trim().isNotEmpty) {
    configuredSocials.add(
      SocialItem(
        icon: FontAwesomeIcons.instagram,
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.pink, Colors.orange, Colors.yellow],
        ),
        url: _normalizeSocialLink(instagram, 'https://instagram.com/'),
      ),
    );
  }

  if (facebook.trim().isNotEmpty) {
    configuredSocials.add(
      SocialItem(
        icon: FontAwesomeIcons.facebook,
        color: Colors.blue,
        url: _normalizeSocialLink(facebook, 'https://facebook.com/'),
      ),
    );
  }

  return configuredSocials;
}

String _normalizeWhatsappLink(String value) {
  final trimmedValue = value.trim();
  if (trimmedValue.startsWith('http')) return trimmedValue;

  final phone = trimmedValue.replaceAll(RegExp(r'[^0-9]'), '');
  return 'https://wa.me/$phone';
}

String _normalizeSocialLink(String value, String baseUrl) {
  final trimmedValue = value.trim();
  if (trimmedValue.startsWith('http')) return trimmedValue;

  return '$baseUrl${trimmedValue.replaceFirst('@', '')}';
}

final List<SocialItem> socials = <SocialItem>[];
